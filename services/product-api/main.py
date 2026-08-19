from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from psycopg2.pool import ThreadedConnectionPool
from contextlib import asynccontextmanager
import asyncio
import logging
import os
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"product-api","message":"%(message)s"}',
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
    
    # --- SHUTDOWN (Graceful Teardown) ---
    if db_pool:
        db_pool.closeall()
        logging.info("PostgreSQL connection pool closed gracefully")

app = FastAPI(title="product-api", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/")
def root():
    return {"service": "product-api", "status": "running"}


@app.get("/healthz")
def healthz():
    return {"status": "healthy"}


@app.get("/products")
def get_products():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, price, currency FROM catalog.products ORDER BY id")
            rows = cur.fetchall()
    finally:
        db_pool.putconn(conn)

    return [
        {"id": r[0], "name": r[1], "price": float(r[2]), "currency": r[3]}
        for r in rows
    ]


@app.get("/products/{product_id}")
def get_product(product_id: str):
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, price, currency FROM catalog.products WHERE id = %s",
                (product_id,),
            )
            row = cur.fetchone()
    finally:
        db_pool.putconn(conn)

    if row is None:
        raise HTTPException(status_code=404, detail="Product not found")

    return {"id": row[0], "name": row[1], "price": float(row[2]), "currency": row[3]}