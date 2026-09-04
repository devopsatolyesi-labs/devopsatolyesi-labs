# Stage 1: Builder
FROM alpine:3.21 AS builder
WORKDIR /build
RUN echo "console.log('Production Microservice');" > app.js

# Stage 2: Runtime
FROM alpine:3.21
WORKDIR /app
RUN addgroup -S appgroup -g 10001 && adduser -S appuser -u 10001 -G appgroup
COPY --from=builder /build/app.js /app/app.js
USER 10001
CMD ["cat", "/app/app.js"]
