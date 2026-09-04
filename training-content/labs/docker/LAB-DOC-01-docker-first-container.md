# LAB-DOC-01 — İlk Docker Konteyneri ve Temel Komutlar

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 35 dakika | `docker` | `8080` |

[LAB-DOC-01.zip](/downloads/LAB-DOC-01.zip)


## Amaç

- Docker Engine mimarisini (Client, Daemon, Registry) uygulamalı olarak anlamak.
- Resmi bir Nginx web sunucu imajını Docker Hub üzerinden çekmek (`docker pull`).
- İmajı izole bir konteyner olarak arka planda çalıştırmak (`docker run -d`).
- Host portu ile konteyner portu arasındaki yönlendirmeyi (`-p 8080:80`) doğrulamak.
- Konteynerleri listelemek, durdurmak ve temizlemek (`ps`, `stop`, `rm`).

---

## Ön Koşullar

- Docker Engine servisinin çalışır durumda olması:
  ```bash
  docker version
  docker info >/dev/null
  ```
- Host üzerinde `8080` portunun boş olması.

---

## Mimari ve Port Yönlendirme Modeli

```text
+-----------------------------------------------------------------------+
| ANA MAKİNE (HOST)                                                    |
|                                                                       |
|   İstemci (curl / Web Tarayıcı) ---> Host Port: 8080                  |
|                                          |                            |
|                                (Port Yönlendirme: -p 8080:80)         |
|                                          v                            |
|   +---------------------------------------------------------------+   |
|   | DOCKER KONTEYNERİ (first-web-container)                       |   |
|   |                                                               |   |
|   |   Nginx Web Sunucusu Dinliyor ---> Konteyner Port: 80         |   |
|   +---------------------------------------------------------------+   |
+-----------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-01
cd ~/labs/LAB-DOC-01
```

---

### Adım 2: Resmi Nginx İmajını İndirin (Pull)

Docker Hub genel kayıt defterinden (public registry) hafif `nginx:alpine` imajını indirin:

```bash
docker pull nginx:alpine
```

İndirilen imajı yerel imaj deposunda inceleyin:

```bash
docker images nginx:alpine
```

---

### Adım 3: Konteyneri Arka Planda Başlatın (Run)

Konteyneri detached modda (`-d`), `first-web-container` adıyla ve `8080:80` port eşlemesiyle başlatın:

```bash
docker run -d --name first-web-container -p 8080:80 nginx:alpine
```

---

### Adım 4: Konteyner Durumunu ve Yanıtı Kontrol Edin

Çalışan konteyneri listeleyin:

```bash
docker ps --filter name=first-web-container
```

HTTP servisine istek atarak Nginx karşılama sayfasını doğrulayın:

```bash
curl -I http://localhost:8080
```

HTTP yanıtında `HTTP/1.1 200 OK` ve `Server: nginx/...` görmelisiniz.

---

### Adım 5: Konteyneri Durdurun ve Kaldırın

Konteynerin çalışmasını güvenli bir şekilde sonlandırın:

```bash
docker stop first-web-container
```

Durdurulan konteynerleri listeleyin (`-a` bayrağı ile):

```bash
docker ps -a --filter name=first-web-container
```

Konteyneri sistemden kaldırın:

```bash
docker rm first-web-container
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```text
HTTP/1.1 200 OK
Server: nginx/1.27.x-alpine
```

---
