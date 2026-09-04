# LAB-DOC-01 — İlk Docker Konteyneri ve Temel Komutlar

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 35 dakika | `docker` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-01.zip)](/downloads/LAB-DOC-01.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


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

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: `docker run` komutunda `-p 8080:80` yerine sadece `-p 80` yazılırsa ne olur?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Docker, host üzerinde rastgele boş bir yüksek port (genellikle 32768 - 60999 aralığında) seçer ve konteynerin 80 portuna bağlar. Hangi portun atandığını `docker port <container_name>` veya `docker ps` çıktısından öğrenebilirsiniz.

??? question "Soru 2: Çalışan bir konteyneri durdurmadan doğrudan `docker rm first-web-container` komutu verirsek ne olur?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Docker hata verir: `You cannot remove a running container... Stop the container before attempting removal or force remove`. Çalışan konteyneri zorla silmek için `docker rm -f` kullanılabilir (önce SIGKILL sinyali gönderir, ardından siler).

??? question "Soru 3: Konteyner silindiğinde indirdiğimiz `nginx:alpine` imajı da silinir mi?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Hayır. İmajlar ve konteynerler bağımsız nesnelerdir. Konteyner silinse bile imaj yerel diskte kalır (`docker images`). İmajı silmek için `docker rmi nginx:alpine` komutu çalıştırılmalıdır.

---

## Beklenen Sonuç

```text
HTTP/1.1 200 OK
Server: nginx/1.27.x-alpine
```

---

## Sorun Giderme

- **Port 8080 Çakışması:** `bind: address already in use` hatası alırsanız, `sudo lsof -i :8080` veya `docker ps` ile portu kullanan servisi bulun ve durdurun.
- **İzin Hatası:** `permission denied while trying to connect to the Docker daemon socket` hatasında kullanıcınızın docker grubunda olduğunu doğrulayın (`groups`).
