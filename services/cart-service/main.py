from fastapi import FastAPI
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
import redis
import os
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"cart-service","message":"%(message)s"}',
    stream=sys.stdout
)

app = FastAPI(title="cart-service")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=0,
    decode_responses=True
)

CART_TTL_SECONDS = int(os.getenv("CART_TTL_SECONDS", "3600"))


class CartItem(BaseModel):
    product_id: str
    quantity: int = 1


@app.get("/")
def root():
    return {
        "service": "cart-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/cart/{cart_id}/items")
def add_item_to_cart(cart_id: str, item: CartItem):
    key = f"cart:{cart_id}"

    redis_client.hincrby(
        key,
        item.product_id,
        item.quantity
    )
    redis_client.expire(key, CART_TTL_SECONDS)

    items = redis_client.hgetall(key)

    logging.info(
        "Added item %s to cart %s (TTL %ss)",
        item.product_id,
        cart_id,
        CART_TTL_SECONDS
    )

    return {
        "cart_id": cart_id,
        "items": items
    }


@app.get("/cart/{cart_id}")
def get_cart(cart_id: str):
    key = f"cart:{cart_id}"
    items = redis_client.hgetall(key)

    return {
        "cart_id": cart_id,
        "items": items,
        "item_count": len(items)
    }


@app.delete("/cart/{cart_id}")
def clear_cart(cart_id: str):
    key = f"cart:{cart_id}"
    redis_client.delete(key)

    return {
        "cart_id": cart_id,
        "status": "cleared"
    }