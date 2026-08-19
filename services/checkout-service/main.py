from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
from psycopg2.pool import ThreadedConnectionPool
from contextlib import asynccontextmanager
import asyncio
import httpx
import os
import uuid
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"checkout-service","message":"%(message)s"}',
    stream=sys.stdout
)

PRODUCT_API_URL = os.getenv("PRODUCT_API_URL", "http://localhost:8001")
CART_SERVICE_URL = os.getenv("CART_SERVICE_URL", "http://localhost:8002")
INVENTORY_SERVICE_URL = os.getenv("INVENTORY_SERVICE_URL", "http://localhost:8005")
PAYMENT_SERVICE_URL = os.getenv("PAYMENT_SERVICE_URL", "http://localhost:8004")
NOTIFICATION_SERVICE_URL = os.getenv("NOTIFICATION_SERVICE_URL", "http://localhost:8006")

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set. Inject it via environment or Secrets.")


db_pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    global db_pool
    for attempt in range(30):
        try:
            db_pool = ThreadedConnectionPool(1, 5, dsn=DATABASE_URL)
            logging.info("Connected to PostgreSQL")
            break
        except Exception as error:
            logging.warning("PostgreSQL not ready (%s). Retry %s/30", error, attempt + 1)
            await asyncio.sleep(2)
    else:
        raise RuntimeError("Could not connect to PostgreSQL")
        
    yield  # <-- App runs here
    
    # --- SHUTDOWN ---
    if db_pool:
        db_pool.closeall()
        logging.info("PostgreSQL connection pool closed gracefully")

app = FastAPI(title="checkout-service", lifespan=lifespan)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class CheckoutRequest(BaseModel):
    cart_id: str
    email: str


@app.get("/")
def root():
    return {"service": "checkout-service", "status": "running"}


@app.get("/healthz")
def healthz():
    return {"status": "healthy"}


@app.post("/checkout")
async def checkout(request: CheckoutRequest):
    order_id = str(uuid.uuid4())

    async with httpx.AsyncClient(timeout=10.0) as client:
        cart_response = await client.get(f"{CART_SERVICE_URL}/cart/{request.cart_id}")
        if cart_response.status_code != 200:
            raise HTTPException(status_code=400, detail="Cart not found")

        cart = cart_response.json()
        items = cart.get("items", {})
        if not items:
            raise HTTPException(status_code=400, detail="Cart is empty")

        total = 0.0

        for product_id, quantity in items.items():
            quantity = int(quantity)

            product_response = await client.get(f"{PRODUCT_API_URL}/products/{product_id}")
            if product_response.status_code != 200:
                raise HTTPException(status_code=400, detail=f"Product {product_id} not found")

            product = product_response.json()
            total += float(product["price"]) * quantity

            reserve_response = await client.post(
                f"{INVENTORY_SERVICE_URL}/inventory/{product_id}/reserve",
                params={"quantity": quantity},
            )
            if reserve_response.status_code != 200:
                raise HTTPException(status_code=409, detail=f"Could not reserve stock for {product_id}")

        try:
            payment_response = await client.post(
                f"{PAYMENT_SERVICE_URL}/payments",
                json={"amount": total, "currency": "KES", "customer_email": request.email},
            )
            if payment_response.status_code != 200:
                raise HTTPException(status_code=402, detail="Payment failed")
        except httpx.RequestError as exc:
            # Catches ConnectError, TimeoutException, DNS failures, etc.
            logging.error("Payment service unreachable: %s", exc)
            raise HTTPException(status_code=503, detail="Payment service unavailable")

        # Persist the order (source of truth = PostgreSQL)
        conn = db_pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """INSERT INTO orders.orders
                       (order_id, cart_id, customer_email, total, currency, status)
                       VALUES (%s, %s, %s, %s, %s, %s)""",
                    (order_id, request.cart_id, request.email, total, "KES", "completed"),
                )
            conn.commit()
        finally:
            db_pool.putconn(conn)

        await client.post(
            f"{NOTIFICATION_SERVICE_URL}/notifications",
            json={
                "to": request.email,
                "message": f"Your order {order_id} has been confirmed. Total: KES {total}",
                "type": "email",
            },
        )

        await client.delete(f"{CART_SERVICE_URL}/cart/{request.cart_id}")

        logging.info("Order %s completed successfully. Total: %s", order_id, total)

        return {
            "order_id": order_id,
            "status": "completed",
            "total": total,
            "currency": "KES",
        }


@app.get("/orders")
def list_orders():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """SELECT order_id, customer_email, total, status, created_at
                   FROM orders.orders ORDER BY created_at DESC LIMIT 20"""
            )
            rows = cur.fetchall()
    finally:
        db_pool.putconn(conn)

    return {
        "count": len(rows),
        "orders": [
            {
                "order_id": r[0],
                "email": r[1],
                "total": float(r[2]),
                "status": r[3],
                "created_at": str(r[4]),
            }
            for r in rows
        ],
    }