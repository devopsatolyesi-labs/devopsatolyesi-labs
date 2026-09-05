# LAB-DOC-06 — User-Defined Docker Network, Port İzolasyonu ve DNS

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 45 dakika | `docker` | `8080` |

[LAB-DOC-06.zip](/downloads/LAB-DOC-06.zip)


## Amaç

- Docker'ın varsayılan (default bridge) ağı ile kullanıcı tanımlı (user-defined bridge) ağı arasındaki farkları öğrenmek.
- Kullanıcı tanımlı bir bridge ağ (`custom-app-net`) oluşturmak.
- Aynı ağdaki konteynerlerin birbirleriyle IP adresi yerine **Konteyner Adı (DNS Resolution)** ile haberleşmesini sağlamak.
- Farklı ağlardaki konteynerler arasında ağ izolasyonunu (network isolation) test etmek.
- Port yayınlama (host port mapping) ile küme içi dahili haberleşme farkını kavramak.

---

## Ön Koşullar

- Docker Engine ortamının hazır olması.
- `8080` ve `8081` portlarının boş olması.

---

## Ağ İzolasyonu ve DNS Mimarisi

```text
+-------------------------------------------------------------------------------+
| DOCKER USER-DEFINED BRIDGE NETWORK (custom-app-net)                          |
|                                                                               |
|   +--------------------------+             +--------------------------+       |
|   | WEB KONTEYNERİ           |             | API KONTEYNERİ           |       |
|   | Adı: frontend-app        |  HTTP GET   | Adı: backend-api         |       |
|   | Host Port: 8080:80       | ----------> | Port: 80 (Dahili)        |       |
|   |                          |             | (Host portu açık değil!) |       |
|   +--------------------------+             +--------------------------+       |
|                 ^                                                              |
|                 | (DNS Çözümleme: "backend-api" -> 172.20.0.3)                |
|                 +------------------ DOCKER EMBEDDED DNS (127.0.0.11)          |
+-------------------------------------------------------------------------------+
                                  X (AĞ İZOLASYONU)
+-------------------------------------------------------------------------------+
| İZOLE EDİLMİŞ BAŞKA BİR AĞ (isolated-net)                                     |
|   +--------------------------+                                                |
|   | GÜVENSİZ KONTEYNER       |                                                |
|   | Adı: untrusted-client    | ---> "backend-api"ye ERİŞEMEZ! (Bağlantı Yok)  |
|   +--------------------------+                                                |
+-------------------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-06
cd ~/labs/LAB-DOC-06
```

---

### Adım 2: Docker Ağlarını İnceleyin ve Yeni Bridge Ağ Oluşturun

Mevcut ağları listeleyin:

```bash
docker network ls
```

Özel bir user-defined bridge ağı oluşturun:

```bash
docker network create --driver bridge custom-app-net
docker network inspect custom-app-net
```

---

### Adım 3: Backend API Konteynerini Ağda Başlatın

Bu konteynerin portunu host makineye açmıyoruz (`-p` YOK). Sadece Docker ağı içinde çalışacak:

```bash
docker run -d   --name backend-api   --network custom-app-net   nginx:alpine
```

Konteynerin bu ağdaki IP adresini sorgulayın:

```bash
docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' backend-api
```

---

### Adım 4: Frontend Konteynerini Başlatın ve Dahili DNS İletişimini Test Edin

Frontend konteynerini aynı ağa bağlayarak başlatın:

```bash
docker run -d   --name frontend-app   --network custom-app-net   -p 8080:80   alpine sleep infinity
```

Frontend konteynerinin içinden, Backend konteynerine doğrudan **adı ile (backend-api)** istek atın:

```bash
docker exec frontend-app wget -qO- http://backend-api
```

Nginx karşılama HTML çıktısının sorunsuz geldiğini görün! Docker'ın dahili DNS sunucusu (`127.0.0.11`), `backend-api` ismini otomatik olarak doğru IP adresine çözmüştür.

---

### Adım 5: Ağ İzolasyonunu Kanıtlayın (Network Isolation)

Şimdi tamamen izole edilmiş farklı bir ağ açalım:

```bash
docker network create isolated-net

docker run -d   --name isolated-client   --network isolated-net   alpine sleep infinity
```

İzole konteynerden `backend-api` servisine erişmeye çalışın:

```bash
docker exec isolated-client wget -T 3 -qO- http://backend-api || echo "BEKLENEN SONUÇ: Ağ izole, bağlantı reddedildi!"
```

DNS çözülemediği veya ağ rotası bulunmadığı için isteğin zaman aşımına uğradığını veya hata verdiğini görün.

---

### Adım 6: Çalışan Konteyneri Canlı Olarak İkinci Bir Ağa Bağlama

Docker, çalışan bir konteyneri durdurmadan başka bir ağa da ekleyebilir:

```bash
docker network connect custom-app-net isolated-client

# Şimdi tekrar test edin:
docker exec isolated-client wget -qO- http://backend-api
```

Artık istek başarıyla tamamlanır!

---

## Doğal Doğrulama ve Beklenen Sonuç

- Adım 4'te `docker exec frontend-app wget -qO- http://backend-api` komutu Nginx HTML sayfasını döner.
- Adım 5'te izole ağdaki istek başarısız olurken, Adım 6'da ağa bağlandıktan sonra başarılı olur.

---
