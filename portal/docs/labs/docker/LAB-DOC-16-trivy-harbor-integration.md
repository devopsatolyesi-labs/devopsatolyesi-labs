# LAB-DOC-16 — Trivy Güvenlik Taraması, SBOM ve Harbor Entegrasyonu

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 50 dakika | `docker` | `80`, `443` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-16.zip)](/downloads/LAB-DOC-16.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Konteyner imajlarındaki güvenlik açıklarını (CVE) Aqua Security Trivy aracı ile taramak.
- Güvenlik açıklarını ciddiyet seviyesine (`CRITICAL`, `HIGH`) göre filtrelemek.
- Yazılım Malzeme Listesi (SBOM - Software Bill of Materials) üreterek SPDX / CycloneDX formatında dışa aktarmak.
- Güvenlik taramasını CI/CD kalite kapısı (Quality Gate / `--exit-code 1`) olarak yapılandırmak.
- Taranmış ve onaylanmış güvenli imajları Harbor özel kayıt defterine (private registry) göndermek.

---

## Ön Koşullar

- Docker Engine çalışır durumda olmalıdır.
- İnternet bağlantısı (Trivy veritabanı indirmesi için) hazır olmalıdır.

---

## DevSecOps Güvenlik ve SBOM Akışı

```text
[ Docker İmajı ] ---> [ TRIVY GÜVENLİK TARAYICISI ]
                             │
         ┌───────────────────┴───────────────────┐
         ▼                                       ▼
[ Güvenlik Raporu (CVE) ]               [ SBOM Dosyası ]
- CRITICAL / HIGH açıkları              - CycloneDX / SPDX JSON
- Düzeltilebilir (Fixed) sürümler       - Tüm açık kaynak lisansları
         │
         ├──> Eşik Aşıldı mı? (Örn. CRITICAL > 0)
         │       ├── EVET: CI/CD Pipeline İptal (exit code 1)
         │       └── HAYIR: Temiz Onayı Verilir
         ▼
[ HARBOR KURUMSAL REGISTRY ] (Güvenli Dağıtım)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-16
cd ~/labs/LAB-DOC-16
```

---

### Adım 2: Trivy CLI Aracını Hazırlayın

Trivy'yi doğrudan resmi Docker konteyneri üzerinden host soketini bağlayarak çalıştırabilirsiniz:

```bash
# Trivy CLI sürüm kontrolü
docker run --rm aquasec/trivy:latest version
```

Kolay kullanım için geçici bir alias tanımlayın:

```bash
alias trivy='docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/workspace aquasec/trivy:latest'
```

---

### Adım 3: Test İmajı Oluşturun

Bilerek eski ve savunmasız bir paket içeren test imajı hazırlayalım:

```bash
cat <<'EOF' > Dockerfile
FROM alpine:3.14
RUN apk update && apk add curl=7.79.1-r0
CMD ["curl", "--version"]
EOF

docker build -t vulnerable-app:1.0 .
```

---

### Adım 4: Güvenlik Açığı Taraması Yapın

İmajı tarayın ve sadece `HIGH` ve `CRITICAL` seviyeli açıkları listeleyin:

```bash
trivy image --severity HIGH,CRITICAL vulnerable-app:1.0
```

Çıktıda tespit edilen CVE numaralarını, etkilenen paketleri ve düzeltilmiş sürümleri (Fixed Version) inceleyin.

---

### Adım 5: CI/CD Kalite Kapısı Simülasyonu (`--exit-code`)

Pipeline otomasyonlarında kritik açık varsa derlemenin iptal edilmesini sağlayın:

```bash
trivy image --severity CRITICAL --exit-code 1 vulnerable-app:1.0 || echo "KALİTE KAPISI: Kritik CVE tespit edildi, dağıtım engellendi!"
```

---

### Adım 6: SBOM (Software Bill of Materials) Üretimi

Uygulamanın içerdiği tüm açık kaynak kütüphaneleri ve lisansları içeren CycloneDX formatında SBOM oluşturun:

```bash
trivy image --format cyclonedx --output /workspace/sbom.json vulnerable-app:1.0
```

Üretilen `sbom.json` dosyasının ilk satırlarını inceleyin:

```bash
head -n 25 sbom.json
```

---

### Adım 7: İmajı Güncelleyerek Açıkları Kapatın

Dockerfile'ı en güncel Alpine tabanına güncelleyin:

```bash
cat <<'EOF' > Dockerfile
FROM alpine:3.19
RUN apk update && apk add --no-cache curl
CMD ["curl", "--version"]
EOF

docker build -t secured-app:1.0 .
```

Temiz imajı tekrar tarayın:

```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 secured-app:1.0
echo "GÜVENLİK ONAYI: İmaj temiz, hiçbir CRITICAL veya HIGH açık bulunamadı!"
```

---

## Doğal Doğrulama

```bash
# SBOM dosyasının boyutunu ve geçerliliğini doğrulayın
test -s sbom.json && echo "SBOM üretimi BAŞARILI"
```

---

### Adım 8: Temizlik

```bash
docker rmi -f vulnerable-app:1.0 secured-app:1.0
rm -f sbom.json
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: SBOM (Software Bill of Materials) modern DevOps ve tedarik zinciri güvenliğinde (Supply Chain Security) neden zorunlu hale gelmiştir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Log4j (Log4Shell) gibi sıfırıncı gün (0-day) açıkları ortaya çıktığında, şirketlerin yüzlerce mikroservis imajını tek tek kaynak kodundan incelemesi günler sürebilir. İmajla birlikte saklanan SBOM dosyaları sayesinde tek bir sorguyla (`grep log4j *.sbom.json`) hangi prodüksiyon imajının riskli kütüphaneyi barındırdığı saniyeler içinde tespit edilir.

??? question "Soru 2: `--ignore-unfixed` bayrağının Trivy taramasındaki önemi nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Bazı CVE'ler için açık kaynak geliştiricileri henüz bir yama (fix) yayınlamamış olabilir. `--ignore-unfixed` bayrağı geliştiricinin elinden bir şey gelmeyen bu açıkları rapordan filtreleyerek CI/CD pipeline'larının gereksiz yere kilitlenmesini önler ve sadece aksiyon alınabilecek açıklara odaklanılmasını sağlar.

---

## Beklenen Sonuç

- İlk taramada `vulnerable-app:1.0` için CVE tablosu listelenir.
- `--exit-code 1` komutu hata vererek pipeline'ı durdurur.
- Güncellenmiş `secured-app:1.0` imajı kalite kapısını geçer.
