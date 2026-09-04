# Hardened Multi-stage Dockerfile
FROM python:3.11-alpine AS builder
WORKDIR /app
COPY app/ /app/

FROM python:3.11-alpine
WORKDIR /app
RUN addgroup -S appgroup -g 10001 && adduser -S appuser -u 10001 -G appgroup
COPY --from=builder /app /app
USER 10001
EXPOSE 8000
CMD ["python", "main.py"]
