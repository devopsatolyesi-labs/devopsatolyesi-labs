from fastapi import FastAPI
import uvicorn
import os

app = FastAPI(title="DevOps Demo API", version="1.0.0")

@app.get("/")
def read_root():
    return {
        "status": "healthy",
        "service": "order-api",
        "environment": os.getenv("APP_ENV", "production")
    }

@app.get("/healthz")
def health_check():
    return {"status": "UP"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app:app", host="0.0.0.0", port=port, log_level="info")
