# LAB-DOC-06 — Trivy ile İmaj Güvenlik Taraması ve Registry Entegrasyonu

## Metadata

- **Seviye:** PRACTITIONER
- **Süre:** 30 dakika
- **Profil:** `docker`
- **Port:** Yok

## Amaç

Bu labın amacı, konteynerleştirilmiş uygulamaları üretime almadan önce güvenlik açıklarına (CVE - Common Vulnerabilities and Exposures), gizli sırlara (Secrets) ve yanlış yapılandırmalara karşı **Trivy Container Security Scanner** kullanarak otomatik olarak denetlemektir:

- İmaj taban katmanlarındaki ve işletim sistemi kütüphanelerindeki zafiyetleri tespit etmek.
- CI/CD boru hatlarında kritik güvenlik kapıları (**Security Gates / Quality Gates**) oluşturmak.
- Yalnızca belirli önem seviyesindeki (`CRITICAL`, `HIGH`) ve çözümü bulunan (`--ignore-unfixed`) açıkları filtreleyerek gürültüyü azaltmak.
- Güvenli taranmış imajları kurumsal **Harbor Private Registry** üzerine yayınlama ilkelerini kavramak.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ortamınızın hazır olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.
> - Özel registry kullanımı için: [🛠️ Harbor Private Registry Kurulum Rehberi](../../setup/harbor-registry.md) dokümanını inceleyin.

Hızlı sistem ön kontrolü:

```bash
docker --version
docker ps
```

---

## Güvenlik Taraması Modeli

```text
+---------------------+      +-------------------------------+      +-------------------------+
| Dockerfile & Build  | ---> | Trivy Security Scan Engine    | ---> | CI/CD Karar Kapısı      |
| lab-image:latest    |      | (OS PKGs + App Deps + CVE DB) |      | Exit 0: PASS -> Push    |
+---------------------+      +-------------------------------+      | Exit 1: FAIL -> Block   |
                                                                    +-------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-06
cd ~/labs/LAB-DOC-06
```

ZIP indirdiyseniz `unzip LAB-DOC-06.zip && cd LAB-DOC-06` komutunu çalıştırın.

---

### Adım 2: Trivy Güvenlik Scriptini Oluşturun

`trivy-scan.sh` scriptini oluşturun. Bu script, Docker soketini bağlayarak Trivy konteynerini çalıştırır ve hedef imajı tarar:

```bash
cat <<'EOF' > trivy-scan.sh
#!/usr/bin/env bash
set -euo pipefail

echo "==> Trivy Güvenlik Taraması Başlatılıyor..."

docker run --rm   -v /var/run/docker.sock:/var/run/docker.sock   -v /tmp/trivy-cache:/root/.cache/   aquasec/trivy:0.74.0 image   --severity CRITICAL   --ignore-unfixed   --exit-code 1   alpine:3.21

echo "==> [PASS] İmaj güvenlik testini başarıyla geçti!"
EOF

chmod +x trivy-scan.sh
```

---

### Adım 3: Taramayı Çalıştırın ve Sonuçları İnceleyin

```bash
./trivy-scan.sh
echo "Exit Code: $?"
```

Çıktıda:
- Taranan kütüphaneler ve paketler (APK, RPM, Debian veya NPM paketleri),
- Varsa tespit edilen CVE numaraları (ör. `CVE-2024-XXXX`),
- Zafiyetin önem derecesi (`CRITICAL`, `HIGH`),
- Düzeltilmiş sürüm (`Fixed Version`) bilgisi listelenir.

---

### Adım 4: Güvenlik Açıklı (Vulnerable) İmaj Simülasyonu

Eski ve zafiyetli bir imajı tarayarak Trivy'nin pipeline'ı nasıl durdurduğunu test edin:

```bash
docker run --rm   -v /var/run/docker.sock:/var/run/docker.sock   aquasec/trivy:0.74.0 image   --severity HIGH,CRITICAL   --exit-code 1   alpine:3.15 || echo "Trivy güvenlik kapısı zafiyetli imajı başarıyla engelledi! (Exit Code 1)"
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

Aşağıdaki soruları yanıtlamaya çalışın; ardından çözümü görmek için kutucuklara tıklayın:

??? question "Soru 1: CI/CD boru hattında (Jenkins, GitLab CI, GitHub Actions) Trivy'nin pipeline'ı hata vererek durdurması için hangi parametre kullanılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `--exit-code 1` parametresi kullanılır. Varsayılan olarak Trivy açık bulsa bile çıktıyı ekrana basıp `exit 0` döner. `--exit-code 1` eklendiğinde belirlenen önem seviyesinde (`--severity CRITICAL`) bir açık bulunursa komut `1` koduyla sonlanır ve CI/CD adımı başarısız sayılır.

??? question "Soru 2: `--ignore-unfixed` bayrağı kurumsal ortamlarda neden kritik bir parametredir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Bazı CVE'ler tespit edilmiş olsa da Linux dağıtıcısı veya kütüphane geliştiricisi tarafından henüz bir yama (fix) yayınlanmamış olabilir. Geliştiricinin düzeltebileceği bir güncelleme yoksa pipeline'ın sürekli başarısız olması (false alarm) geliştirme akışını kilitler. `--ignore-unfixed`, yalnızca geliştiricinin güncelleyerek çözebileceği yamalı açıkları filtreler.

??? question "Soru 3: Trivy taraması sırasında `/var/run/docker.sock` dosyasını konteynere bağlamanın (`-v`) amacı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Trivy'nin ana makinedeki (host) yerel Docker daemon'a erişebilmesini ve henüz registry'ye push edilmemiş yerel imajları (local images) doğrudan tarayabilmesini sağlar.

??? question "Soru 4: Trivy ile sadece işletim sistemi (OS) paketlerini değil, kaynak koddaki Python/Node.js bağımlılıklarını (SBOM) nasıl tararız?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `trivy fs` (filesystem) veya `trivy repo` komutunu kullanarak projenin kaynak dizinini tarayabilirsiniz:
        ```bash
        trivy fs --severity HIGH,CRITICAL ./my-project/
        ```
        Trivy otomatik olarak `package-lock.json`, `requirements.txt`, `pom.xml` ve `go.sum` dosyalarını analiz eder.

??? question "Soru 5: Kurumsal Harbor Registry üzerinde otomatik imaj taraması (Scan on Push) nasıl yapılandırılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Harbor Web UI üzerinde **Projects > [Proje Adı] > Configuration** sekmesine gidilir ve **Automatically scan images on push** seçeneği işaretlenir. Böylece geliştiriciler `docker push` yaptığında Harbor bünyesindeki Trivy servisi imajı arka planda otomatik tarar ve güvenlik politikasına uymayan imajların `docker pull` edilmesini engeller.

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Sorun Giderme

- **Docker Socket İzni:** `permission denied while trying to connect to the Docker daemon socket` hatasında kullanıcınızın `docker` grubunda olduğunu kontrol edin (`sudo usermod -aG docker $USER`).
- **Veritabanı İndirme:** Trivy ilk çalışırken GitHub'dan güvenlik veritabanını indirir; internet erişiminizin açık olduğundan emin olun.

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak ve Referanslar

Bu lab, Aqua Security Trivy açık kaynak güvenlik standartları ve Harbor OCI Registry güvenlik politikalarından uyarlanmıştır.
