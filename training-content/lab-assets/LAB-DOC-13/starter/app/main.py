import os
import psycopg2
import redis
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Enterprise Order API", version="1.0.0")

DB_HOST = os.getenv("DB_HOST", "postgres-db")
DB_NAME = os.getenv("DB_NAME", "order_db")
DB_USER = os.getenv("DB_USER", "order_user")
DB_PASS = os.getenv("DB_PASS", "order_secret_pass")
REDIS_HOST = os.getenv("REDIS_HOST", "redis-broker")

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        connect_timeout=3
    )

def get_redis_connection():
    return redis.Redis(host=REDIS_HOST, port=6379, socket_timeout=3)

@app.on_event("startup")
def init_tables():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                item_name VARCHAR(100) NOT NULL,
                quantity INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Startup DB init error: {e}")

@app.get("/healthz")
def healthz():
    db_ok = False
    redis_ok = False
    try:
        conn = get_db_connection()
        conn.close()
        db_ok = True
    except Exception:
        pass

    try:
        r = get_redis_connection()
        r.ping()
        redis_ok = True
    except Exception:
        pass

    if db_ok and redis_ok:
        return {"status": "HEALTHY", "database": "CONNECTED", "cache": "CONNECTED"}
    raise HTTPException(status_code=503, detail={"status": "UNHEALTHY", "database": db_ok, "cache": redis_ok})

@app.get("/")
def read_root():
    return {"service": "order-api", "version": "1.0.0", "status": "active"}

@app.post("/orders")
def create_order(item: str = "Laptop", qty: int = 1):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO orders (item_name, quantity) VALUES (%s, %s) RETURNING id;", (item, qty))
    order_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()

    r = get_redis_connection()
    r.incr("order_count")
    r.lpush("task_queue", f"OrderCreated:{order_id}")

    return {"order_id": order_id, "item": item, "quantity": qty, "status": "queued"}

@app.get("/stats")
def read_stats():
    r = get_redis_connection()
    count = r.get("order_count")
    return {"total_orders": int(count) if count else 0}
