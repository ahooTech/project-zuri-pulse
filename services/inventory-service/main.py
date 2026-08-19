from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from psycopg2.pool import ThreadedConnectionPool
from contextlib import asynccontextmanager
import asyncio
import logging
import os
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"inventory-service","message":"%(message)s"}',
    stream=sys.stdout
)

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

app = FastAPI(title="inventory-service", lifespan=lifespan)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/")
def root():
    return {"service": "inventory-service", "status": "running"}


@app.get("/healthz")
def healthz():
    return {"status": "healthy"}


@app.get("/inventory")
def get_inventory():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT product_id, remaining FROM inventory.stock ORDER BY product_id")
            rows = cur.fetchall()
    finally:
        db_pool.putconn(conn)

    return [{"product_id": r[0], "remaining": r[1]} for r in rows]


@app.get("/inventory/{product_id}")
def get_product_inventory(product_id: str):
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT product_id, remaining FROM inventory.stock WHERE product_id = %s",
                (product_id,),
            )
            row = cur.fetchone()
    finally:
        db_pool.putconn(conn)

    if row is None:
        raise HTTPException(status_code=404, detail="Product not found in inventory")

    return {"product_id": row[0], "remaining": row[1]}


@app.post("/inventory/{product_id}/reserve")
def reserve_inventory(product_id: str, quantity: int = 1):
    if quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be greater than zero")

    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Atomic reservation: the DB guarantees no oversell (CHECK remaining >= 0)
            cur.execute(
                """UPDATE inventory.stock
                   SET remaining = remaining - %s
                   WHERE product_id = %s AND remaining >= %s
                   RETURNING remaining""",
                (quantity, product_id, quantity),
            )
            row = cur.fetchone()
            conn.commit()

            if row is None:
                cur.execute(
                    "SELECT 1 FROM inventory.stock WHERE product_id = %s",
                    (product_id,),
                )
                exists = cur.fetchone() is not None
    finally:
        db_pool.putconn(conn)

    if row is None:
        if not exists:
            raise HTTPException(status_code=404, detail="Product not found in inventory")
        raise HTTPException(status_code=409, detail="Insufficient stock")

    logging.info("Reserved %s units of %s. Remaining: %s", quantity, product_id, row[0])

    return {"product_id": product_id, "reserved": quantity, "remaining": row[0]}