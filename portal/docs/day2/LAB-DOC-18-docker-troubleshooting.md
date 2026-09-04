# LAB-DOC-18 — Docker Sorun Giderme ve Teşhis Senaryoları

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 55 dakika | `docker` | `8080, 5432` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-18.zip)](/downloads/LAB-DOC-18.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 55 dakika | `docker` | `8080`, `5432` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-18.zip)](/downloads/LAB-DOC-18.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Üretim ortamlarında sıkça karşılaşılan 4 kritik Docker arızasını teşhis etmek ve gidermek:
  1. **Port Çakışması:** `address already in use` hatası ve process analizi.
  2. **DNS & Ağ İletişim Hatası:** `Name or service not known` ve ağ denetimi.
  3. **Dosya Yetki Hatası:** Volume mount sonrası `EACCES: permission denied` ve UID/GID eşleşmesi.
  4. **OOM & CrashLoop:** Konteynerin sessizce çökmesi ve `State.OOMKilled` tespiti.

---

## Ön Koşullar

- Docker Engine çalışır durumda olmalıdır.

---

## Sorun Giderme Matrisi

```text
+-----------------------+-----------------------------+-------------------------------+
| BELİRTİ               | KÖK NEDEN                   | ÇÖZÜM ARAÇLARI                |
+-----------------------+-----------------------------+-------------------------------+
| Port Bind Hatası      | Host portu başka serviste   | lsof -i, ss -tulpn, docker ps |
| DNS / Network Hatası  | Konteynerler farklı ağlarda | docker network inspect/connect|
| EACCES Yetki Hatası   | Host dizini UID uyuşmazlığı | ls -nd, chown, chmod, --user  |
| Çıkış Kodu 137        | Kernel OOM Killer           | docker inspect .State.OOMKilled|
+-----------------------+-----------------------------+-------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-18
cd ~/labs/LAB-DOC-18
```

---

### Adım 2: Senaryo 1 — Port Çakışması Teşhisi ve Çözümü

Önce 8080 portunu kullanan arka plan bir servis başlatalım:

```bash
docker run -d --name blocker -p 8080:80 nginx:alpine
```

Şimdi yeni bir konteyneri aynı porta bağlamaya çalışın:

```bash
docker run -d --name new-service -p 8080:80 httpd:alpine || echo "BEKLENEN: Port zaten kullanımda hatası!"
```

**Teşhis:** Portu hangi sürecin dinlediğini bulun:

```bash
docker ps --filter "publish=8080"
```

**Çözüm:** Çakışan eski konteyneri durdurun veya yeni konteyneri boş bir host portuna eşleyin (`-p 8081:80`):

```bash
docker rm -f blocker
docker run -d --name new-service -p 8080:80 httpd:alpine
curl -I http://localhost:8080
docker rm -f new-service
```

---

### Adım 3: Senaryo 2 — Konteyner DNS Çözümleme Arızası

İki konteyneri varsayılan köprü (default bridge) ağında başlatalım:

```bash
docker run -d --name backend-srv nginx:alpine
docker run -d --name client-srv alpine sleep 1000
```

Kullanıcı `backend-srv` adına istek atar:

```bash
docker exec client-srv ping -c 2 backend-srv || echo "HATA: Varsayılan bridge ağında isim çözülemez!"
```

**Teşhis:** Varsayılan bridge ağında gömülü DNS devre dışıdır. Konteyner ağlarını inceleyin:

```bash
docker inspect client-srv --format '{{.NetworkSettings.Networks}}'
```

**Çözüm:** Kullanıcı tanımlı (user-defined) bridge ağı oluşturun ve konteynerleri bu ağa bağlayın:

```bash
docker network create my-custom-net
docker network connect my-custom-net backend-srv
docker network connect my-custom-net client-srv

# Şimdi tekrar deneyin:
docker exec client-srv ping -c 2 backend-srv
```

Artık isim başarıyla çözülür! Temizlik:

```bash
docker rm -f backend-srv client-srv
docker network rm my-custom-net
```

---

### Adım 4: Senaryo 3 — Volume Mount Yetki (EACCES) Arızası

Host üzerinde sadece root kullanıcısının yazabileceği bir dizin oluşturalım:

```bash
mkdir -p data
sudo chown -R root:root data 2>/dev/null || chown -R root:root data 2>/dev/null || true
chmod 700 data
```

Uygulamayı non-root (`UID 10001`) kullanıcısı ile çalıştırıp bu dizine yazmasını isteyelim:

```bash
docker run --rm --user 10001:10001 -v $(pwd)/data:/app/data alpine touch /app/data/test.log || echo "HATA: Permission denied!"
```

**Teşhis:** Host dizin izinlerini ve konteyner kullanıcısını karşılaştırın:

```bash
ls -ld data
```

**Çözüm:** Dizin sahipliğini konteynerin çalıştığı UID'ye devredin:

```bash
sudo chown -R 10001:10001 data 2>/dev/null || chown -R 10001:10001 data 2>/dev/null || chmod 777 data
docker run --rm --user 10001:10001 -v $(pwd)/data:/app/data alpine touch /app/data/test.log
ls -la data/test.log
```

---

### Adım 5: Senaryo 4 — Sessiz Çökme ve OOMKilled Analizi

```bash
docker run -d --name mem-crasher -m 32m alpine sh -c 'tail /dev/zero'
sleep 3
```

Konteynerin durumunu inceleyin:

```bash
docker ps -a --filter name=mem-crasher
```

Konteynerin `Exited (137)` olduğunu göreceksiniz. Neden çöktüğünü doğrulayın:

```bash
docker inspect mem-crasher --format='ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
```

`OOMKilled: true` çıktısı ile sorunun bellek yetersizliği olduğu kesinleşir.

---

### Adım 6: Temizlik

```bash
docker rm -f mem-crasher
rm -rf data
```

---

## Doğal Doğrulama

Her 4 senaryonun da neden-sonuç ilişkisini ve ilgili teşhis komutlarını başarıyla uyguladığınızı doğrulayın.

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: `docker run` komutu verdiğinizde konteyner anında kapanıyor ve `docker ps` listesinde görünmüyorsa ilk bakılması gereken yer neresidir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        1. `docker ps -a` ile çıkış koduna (Exit Code) bakılmalıdır.
        2. `docker logs <container_name>` ile uygulamanın çökmeden önce stdout/stderr'e yazdığı hata mesajı (örneğin eksik konfigürasyon, veritabanı bağlantı hatası veya syntax hatası) okunmalıdır.

??? question "Soru 2: `docker top <container_id>` komutu ne işe yarar?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Konteynerin içine girmeye gerek kalmadan, host işletim sistemi perspektifinden konteyner içinde çalışan tüm süreçlerin PID, PPID, kullanıcı (UID) ve CPU kullanımını anlık olarak gösterir.
