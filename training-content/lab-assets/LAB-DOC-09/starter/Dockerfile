# ==========================================
# LAB-DOC-04: Multi-Stage & Non-Root Hardening
# ==========================================

# AŞAMA 1: Builder Aşaması
# TODO: node:20-alpine imajını 'builder' adıyla taban alın
# FROM node:20-alpine AS builder

# TODO: Çalışma dizinini /build yapın
# WORKDIR /build

# TODO: Bağımlılık dosyalarını kopyalayın ve npm install çalıştırın
# COPY package*.json ./
# RUN npm ci --only=production

# TODO: Uygulama kaynak kodlarını kopyalayın
# COPY server.js ./


# AŞAMA 2: Runtime (Production) Aşaması
# TODO: Minimal ve güvenli node:20-alpine imajını taban alın
# FROM node:20-alpine

# TODO: Güvenlik için UID ve GID 10001 olan non-root 'appuser' kullanıcısını oluşturun
# RUN addgroup -S -g 10001 appgroup && adduser -S -u 10001 -G appgroup appuser

# TODO: Çalışma dizinini /app yapın ve sahipliğini appuser'a verin
# WORKDIR /app

# TODO: Builder aşamasından YALNIZCA gerekli dosyaları (node_modules, package.json, server.js) kopyalayın
# COPY --from=builder --chown=10001:10001 /build/node_modules ./node_modules
# COPY --from=builder --chown=10001:10001 /build/package.json ./package.json
# COPY --from=builder --chown=10001:10001 /build/server.js ./server.js

# TODO: Konteyneri root olmayan 10001 kullanıcısına geçirin
# USER 10001

# TODO: Port 3000'i tanımlayın ve CMD ile sunucuyu başlatın
# EXPOSE 3000
# CMD ["node", "server.js"]
