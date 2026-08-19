from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
from typing import Optional
import uuid
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"payment-service","message":"%(message)s"}',
    stream=sys.stdout
)

app = FastAPI(title="payment-service")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class PaymentRequest(BaseModel):
    amount: float
    currency: str = "KES"
    customer_email: Optional[str] = None


@app.get("/")
def root():
    return {
        "service": "payment-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/payments")
def create_payment(request: PaymentRequest):
    payment_id = str(uuid.uuid4())

    if request.amount <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be greater than zero")

    if request.amount > 200000:
        raise HTTPException(status_code=402, detail="Payment declined by mock payment provider")

    logging.info(
        "Payment approved: %s for amount %s",
        payment_id,
        request.amount
    )

    return {
        "payment_id": payment_id,
        "status": "approved",
        "amount": request.amount,
        "currency": request.currency
    }