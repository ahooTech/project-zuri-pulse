from fastapi import FastAPI
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"notification-service","message":"%(message)s"}',
    stream=sys.stdout
)

app = FastAPI(title="notification-service")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class NotificationRequest(BaseModel):
    to: str
    message: str
    type: str = "email"


@app.get("/")
def root():
    return {
        "service": "notification-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/notifications")
def send_notification(request: NotificationRequest):
    logging.info(
        "Sending %s notification to %s: %s",
        request.type,
        request.to,
        request.message
    )

    return {
        "status": "queued",
        "to": request.to,
        "type": request.type
    }