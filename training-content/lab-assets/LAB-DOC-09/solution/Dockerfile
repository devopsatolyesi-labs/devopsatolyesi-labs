# Aşama 1: Builder
FROM node:20-alpine AS builder
WORKDIR /build

COPY package*.json ./
# Production bağımlılıklarını kurun
RUN npm install --omit=dev --no-audit --no-fund

COPY server.js ./

# Aşama 2: Minimal & Güvenli Runtime
FROM node:20-alpine
WORKDIR /app

# Güvenlik gereksinimi: UID 10001 olan kısıtlı kullanıcı oluşturma
RUN addgroup -S -g 10001 appgroup && adduser -S -u 10001 -G appgroup appuser

# Yalnızca gerekli runtime dosyalarını kopyalayın
COPY --from=builder --chown=10001:10001 /build/node_modules ./node_modules
COPY --from=builder --chown=10001:10001 /build/package.json ./package.json
COPY --from=builder --chown=10001:10001 /build/server.js ./server.js

USER 10001
EXPOSE 3000

CMD ["node", "server.js"]
