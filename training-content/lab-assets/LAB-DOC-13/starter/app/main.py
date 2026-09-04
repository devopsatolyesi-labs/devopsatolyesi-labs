import os

import psycopg2
import redis
import uvicorn
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Multi-Tier Order Service")


def database_connection():
    return psycopg2.connect(host=os.environ["DB_HOST"], user=os.environ["DB_USER"], password=os.environ["DB_PASS"], dbname=os.environ["DB_NAME"], connect_timeout=3)


def redis_connection():
    return redis.Redis(host=os.environ["REDIS_HOST"], port=6379, decode_responses=True)


@app.get("/")
def home():
    return {"service": "order-api", "page_hits_from_redis": redis_connection().incr("page_views")}


@app.get("/healthz")
def health():
    try:
        connection = database_connection()
        connection.close()
        redis_connection().ping()
        return {"status": "HEALTHY", "db": "OK", "redis": "OK"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail="dependency check failed") from exc


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
