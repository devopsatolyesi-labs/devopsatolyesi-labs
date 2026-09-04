# LAB-DOC-10 — Docker Runtime Güvenliği ve Hardening

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| İleri | 45 dakika | `docker` | `8080` |

[LAB-DOC-10.zip](/downloads/LAB-DOC-10.zip)


---

## Amaç

- Konteynerlerin varsayılan `root (UID 0)` yerine kısıtlı kullanıcı (`UID 10001`) ile çalıştırılmasını zorunlu kılmak.
- Salt okunur dosya sistemi (`--read-only`) ve geçici yazılabilir bellek alanları (`--tmpfs`) tanımlamak.
- Linux çekirdek yeteneklerini kısıtlamak (`--cap-drop=ALL` ve `--cap-add`).
- Yetki yükseltme saldırılarını engellemek (`--security-opt=no-new-privileges:true`).
- Konteyner güvenlik parametrelerini `docker inspect` ve `docker top` ile denetlemek.

---

## Ön Koşullar

- Docker Engine hazır olmalıdır.
- `8080` portu boş olmalıdır.

---

## Konteyner Sertleştirme (Hardening) Modeli

```text
+-------------------------------------------------------------------+
| GÜVENSİZ KONTEYNER (VARSAYILAN)                                   |
|  - User: root (UID 0)                                             |
|  - Rootfs: Yazılabilir (Kötü amaçlı yazılım diske kaydedilebilir) |
|  - Capabilities: 14+ Linux yeteneği açık (CAP_CHOWN, CAP_NET_RAW) |
|  - Privileges: SUID binary ile root yetkisine sıçranabilir        |
+-------------------------------------------------------------------+
                                 vs
+-------------------------------------------------------------------+
| SERTLEŞTİRİLMİŞ (HARDENED) KONTEYNER                              |
|  - User: UID 10001 (Non-root, host üzerinde yetkisiz)             |
|  - Rootfs: Read-Only (Diske hiçbir dosya yazılamaz)               |
|  - Tmpfs: /tmp:rw,noexec,nosuid (Sadece RAM'de geçici izin)       |
|  - Capabilities: --cap-drop=ALL (Tüm kernel yetkileri kapalı)     |
|  - Security Opt: no-new-privileges:true (Yetki yükseltme bloke)   |
+-------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-10
cd ~/labs/LAB-DOC-10
```

---

### Adım 2: Güvenli Nginx Yapılandırması Hazırlayın

Standart Nginx root (UID 0) olarak başlar ve `/var/run`, `/var/cache` gibi yerlere yazar. Non-root çalışması için portu 8080'e ve yolları `/tmp` dizinine yönlendirelim:

```bash
cat <<'EOF' > nginx-hardened.conf
pid /tmp/nginx.pid;

events {
    worker_connections 1024;
}

http {
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp_path;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;

    server {
        listen 8080;
        server_name localhost;

        location / {
            return 200 '{"status":"secure","security":"hardened_runtime"}
';
            add_header Content-Type application/json;
        }
    }
}
EOF
```

---

### Adım 3: Non-Root Dockerfile Hazırlayın

```bash
cat <<'EOF' > Dockerfile
FROM nginx:1.25-alpine

# Non-root UID 10001 kullanıcısı
RUN addgroup -g 10001 -S appgroup &&     adduser -u 10001 -D -S -G appgroup appuser

COPY nginx-hardened.conf /etc/nginx/nginx.conf

# Dosya sahipliği appuser'a verilir
RUN chown -R appuser:appgroup /etc/nginx

USER 10001
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
EOF
```

İmajı derleyin:

```bash
docker build -t nginx-hardened:1.0 .
```

---

### Adım 4: Konteyneri Üretim Seviyesinde Sertleştirilmiş Bayraklarla Başlatın

```bash
docker run -d   --name secure-nginx   -p 8080:8080   --user 10001:10001   --read-only   --tmpfs /tmp:rw,noexec,nosuid,size=64m   --cap-drop=ALL   --security-opt=no-new-privileges:true   nginx-hardened:1.0
```

---

## Doğal Doğrulama

Konteynerin çalıştığını ve sertleştirme kurallarının devrede olduğunu test edin:

```bash
# 1. HTTP yanıtını doğrulayın
curl -s http://localhost:8080

# 2. Salt-okunur (read-only) dosya sistemini test edin (Yazma hatası vermeli!)
docker exec secure-nginx touch /etc/nginx/hack.txt || echo "BEKLENEN: Read-only file system hatası alındı!"

# 3. /tmp üzerinde yazma yapılabilir, ancak noexec nedeniyle dosya çalıştırılamaz
docker exec secure-nginx touch /tmp/test.txt && echo "Tmpfs yazma başarılı"

# 4. Sürecin host üzerindeki UID değerini denetleyin
docker top secure-nginx
```

---

## Doğal Doğrulama ve Beklenen Sonuç

- `touch /etc/nginx/hack.txt` komutu `Read-only file system` hatası döner.
- HTTP yanıtı `{"status":"secure","security":"hardened_runtime"}` döner.

---
