# LAB-DOC-03 — Docker İmaj, Etiketleme ve Registry Yönetimi

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 45 dakika | `docker` | `5000` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-03.zip)](/downloads/LAB-DOC-03.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


## Amaç

- Docker imajlarının katmanlı dosya sistemi (OverlayFS) mimarisini ve `docker history` çıktısını anlamak.
- Anlamsal Sürümleme (Semantic Versioning) prensiplerine göre imaj etiketlemeyi (`docker tag`) kavramak.
- `tag` (değişebilir işaretçi) ile `digest` (değiştirilemez SHA256 içerik hash'i) arasındaki kritik güvenlik farkını deneyimlemek.
- Yerel bir özel kayıt defteri (Local Private Registry v2) ayağa kaldırıp imaj yüklemek (`push`) ve çekmek (`pull`).
- Kullanılmayan imajları güvenle temizlemeyi (`docker rmi`, `image prune`) öğrenmek.

---

## Ön Koşullar

- Docker Engine ortamının hazır olması.
- `5000` portunun boş olması (yerel registry için).

---

## İmaj Etiketleme ve Registry Mimarisi

```text
                                 DOCKER TAG ANATOMİSİ
           registry.example.com:5000 / devops-team / backend-api : 1.4.2
           \_______________________/   \_________/   \_________/   \___/
                   Registry            Organizasyon     İmaj       Etiket
                    Adresi               / Proje         Adı       (Tag)

+-------------------------------------------------------------------------------+
| LOCAL DOCKER DAEMON                                                           |
|                                                                               |
|  1. İmajı Etiketle:                                                           |
|     docker tag alpine:latest localhost:5000/my-app:1.0.0                      |
|                                                                               |
|  2. Registry'ye Gönder (Push):           3. Yerel Registry'den Çek (Pull):    |
|     docker push localhost:5000/my-app       docker pull localhost:5000/my-app |
|                     |                                     ^                   |
+---------------------|-------------------------------------|-------------------+
                      v                                     |
              +--------------------------------------------------+
              | LOCAL REGISTRY CONTAINER (registry:2 on :5000)   |
              |  - HTTP API v2                                   |
              |  - İmaj Blobları ve Manifest Saklama             |
              +--------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-03
cd ~/labs/LAB-DOC-03
```

---

### Adım 2: İmaj Katmanlarını ve Geçmişini İnceleyin (History)

Bir Docker imajı, salt-okunur (read-only) katmanların üst üste binmesiyle oluşur:

```bash
docker pull alpine:3.19
docker history alpine:3.19
```

`docker history` komutu, imajı oluşturan her bir katmanın boyutunu ve çalıştırılan komutları gösterir.

---

### Adım 3: İmaj Etiketleme (Semantic Versioning)

Aynı imaj kimliğine (IMAGE ID) birden fazla etiket atanabilir. Bu işlem diski iki katına çıkarmaz; sadece yeni bir referans işaretçisi ekler:

```bash
# Sürüm etiketi atama
docker tag alpine:3.19 my-microservice:1.0.0

# Latest etiketi atama
docker tag alpine:3.19 my-microservice:latest

# İmaj listesini inceleyin (IMAGE ID değerlerinin aynı olduğunu teyit edin)
docker images my-microservice
```

---

### Adım 4: Yerel Özel Registry (Private Registry) Başlatın

Kurumsal ortamlarda imajlar dahili Harbor veya cloud registry üzerinde barındırılır. Test için yerel bir registry başlatalım:

```bash
docker run -d --name local-registry -p 5000:5000 --restart always registry:2
```

Registry API'sinin çalıştığını kontrol edin:

```bash
curl -s http://localhost:5000/v2/_catalog
```

API `{"repositories":[]}` yanıtını dönmelidir.

---

### Adım 5: İmajı Registry Formatında Etiketleyin ve Push Edin

Bir imajın özel bir registry'ye push edilebilmesi için etiketinin başında registry adresi (`host:port`) bulunmalıdır:

```bash
# Registry ön ekiyle etiketleme
docker tag my-microservice:1.0.0 localhost:5000/my-microservice:1.0.0
docker tag my-microservice:latest localhost:5000/my-microservice:latest

# İmajları yerel registry'ye yükleme
docker push localhost:5000/my-microservice:1.0.0
docker push localhost:5000/my-microservice:latest
```

Registry kataloğunu tekrar sorgulayın:

```bash
curl -s http://localhost:5000/v2/my-microservice/tags/list
```

Çıktıda `["1.0.0", "latest"]` etiketlerini göreceksiniz.

---

### Adım 6: İmajı Yerelden Silin ve Registry'den Çekin (Pull)

İmajın registry'den gerçekten geri çekilebildiğini doğrulamak için yerel kopyaları silin:

```bash
# Yerel etiketleri silin
docker rmi localhost:5000/my-microservice:1.0.0 localhost:5000/my-microservice:latest

# Registry'den sıfırdan indirin
docker pull localhost:5000/my-microservice:1.0.0

# İndirilen imajı doğrulayın
docker images localhost:5000/my-microservice
```

---

### Adım 7: Tag vs Digest (Değiştirilemez İmaj Güvenliği)

Etiketler (`latest`, `1.0.0`) değiştirilebilir (mutable) referanslardır; birisi aynı etiketle farklı bir imaj push edebilir. Üretim ortamlarında mutlak güvenilirlik için **Digest (SHA256)** kullanılır:

```bash
# İmajın benzersiz SHA256 digest değerini öğrenin
docker images --digests localhost:5000/my-microservice

# Digest kullanarak çalıştırma
DIGEST=$(docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/my-microservice:1.0.0)
echo "Kullanılan Digest: $DIGEST"

docker run --rm $DIGEST cat /etc/alpine-release
```

---

### Adım 8: Temizlik

```bash
docker rm -f local-registry
docker rmi localhost:5000/my-microservice:1.0.0 my-microservice:1.0.0 my-microservice:latest 2>/dev/null || true
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Üretim ortamlarında neden `image: my-app:latest` kullanımı kesinlikle tavsiye edilmez (Anti-pattern)?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `latest` etiketi deterministik değildir. Bir düğüm imajı pazartesi çektiğinde v1 çalışırken, çarşamba günü yeni pod ayağa kaldıran başka bir düğüm güncellenmiş v2 kodunu çekebilir. Bu durum kümede farklı podların farklı kodlar çalıştırmasına ve sürümlerin takip edilememesine yol açar. Üretimde daima sabit sürüm (`v1.4.2`) veya `digest (sha256:...)` kullanılmalıdır.

??? question "Soru 2: `docker tag` komutu diski ikiye katlar mı?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Hayır. `docker tag` dosya kopyalamaz; yalnızca var olan aynı imaj ID'sine yeni bir takma ad (alias/pointer) ekler. `docker images` çıktısında iki satır görünse de `IMAGE ID` birebir aynıdır ve fiziksel katmanlar tektir.

??? question "Soru 3: Kullanılmayan (dangling) sahipsiz imajları tek komutla nasıl temizleriz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        ```bash
        docker image prune -f
        ```
        Hiçbir konteyner tarafından referans verilmeyen tüm kullanılmayan imajları silmek için ise:
        ```bash
        docker image prune -a -f
        ```

---

## Beklenen Sonuç

- `curl http://localhost:5000/v2/_catalog` çıktısında `my-microservice` deposu listelenir.
- Registry'den çekilen imaj `docker images` çıktısında `localhost:5000/my-microservice` adıyla yer alır.
- Digest ile çağrılan imaj alpine sürümünü sorunsuz ekrana basar.

---

## Sorun Giderme

- **HTTP vs HTTPS Registry Hatası:** Docker varsayılan olarak HTTP registry'lere izin vermez. Ancak `localhost` ve `127.0.0.1` adresleri güvenli (insecure registry istisnası) sayıldığı için ek ayar gerektirmeden çalışır.
- **Port 5000 Meşgulse:** `docker ps --filter publish=5000` ile registry konteynerini kontrol edin.
