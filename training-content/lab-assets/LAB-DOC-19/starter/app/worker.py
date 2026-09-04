import os
import time
import redis

REDIS_HOST = os.getenv("REDIS_HOST", "redis-broker")

def run_worker():
    print(f"[Worker] Starting Async Task Consumer connected to {REDIS_HOST}...")
    r = redis.Redis(host=REDIS_HOST, port=6379, socket_timeout=5)
    
    while True:
        try:
            task = r.brpop("task_queue", timeout=2)
            if task:
                task_data = task[1].decode("utf-8")
                print(f"[Worker] Processing background task: {task_data}")
                time.sleep(0.5)
                print(f"[Worker] Task completed successfully: {task_data}")
        except Exception as e:
            print(f"[Worker] Error polling task queue: {e}")
            time.sleep(2)

if __name__ == "__main__":
    run_worker()
