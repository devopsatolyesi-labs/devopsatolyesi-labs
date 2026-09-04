# Aşama 1: Node.js Builder
FROM node:20-alpine AS builder
WORKDIR /build

COPY package*.json ./ 2>/dev/null || true
COPY public ./public 2>/dev/null || true
COPY src ./src 2>/dev/null || true
COPY index.html ./

# Build simülasyonu
RUN mkdir -p dist && cp index.html dist/

# Aşama 2: Nginx Web Sunucusu
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Varsayılan nginx sayfalarını temizleyin
RUN rm -rf ./*

# Builder çıktısını ve özel nginx ayarını kopyalayın
COPY --from=builder /build/dist .
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
