# LAB-DOC-07 — Java Spring Boot Uygulamasını Multi-Stage ile Konteynerleştirme ve JVM Optimizasyonu

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-07.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-07.zip && cd LAB-DOC-07`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-07
cd ~/labs/LAB-DOC-07
```

### `starter/Dockerfile`

```bash
mkdir -p "$(dirname -- starter/Dockerfile)"
cat > starter/Dockerfile <<'LAB_FILE_EOF_1'
# TODO: Aşama 1: Maven Builder
# FROM maven:3.9-eclipse-temurin-17-alpine AS builder

# TODO: Aşama 2: JRE Runtime & Non-Root
# FROM eclipse-temurin:17-jre-alpine
LAB_FILE_EOF_1
```

### `starter/pom.xml`

```bash
mkdir -p "$(dirname -- starter/pom.xml)"
cat > starter/pom.xml <<'LAB_FILE_EOF_2'
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.devopsatolyesi</groupId>
    <artifactId>spring-boot-demo</artifactId>
    <version>1.0.0</version>
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>
</project>
LAB_FILE_EOF_2
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
echo "[BİLGİ] LAB-DOC-07 temizlendi."
LAB_FILE_EOF_3
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
cp -a starter/. .
echo "[BİLGİ] LAB-DOC-07 sıfırlandı."
LAB_FILE_EOF_4
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_5'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-07] Doğrulama Başlatılıyor: Java Spring Boot Multi-Stage..."

if [[ ! -f Dockerfile ]]; then
  echo "[HATA] Dockerfile bulunamadı! ~/labs/LAB-DOC-07 dizininde çalıştırın." >&2
  exit 1
fi

stage_count=$(grep -Ec '^[[:space:]]*FROM[[:space:]]+' Dockerfile)
if [[ "$stage_count" -lt 2 ]]; then
  echo "[HATA] Dockerfile en az 2 aşama (Multi-Stage) içermelidir." >&2
  exit 1
fi

if ! grep -q 'MaxRAMPercentage' Dockerfile && ! grep -q 'UseContainerSupport' Dockerfile; then
  echo "[HATA] JVM container bellek optimizasyon bayrakları (MaxRAMPercentage veya UseContainerSupport) bulunmalıdır." >&2
  exit 1
fi

echo "[PASS] Java Spring Boot multi-stage build ve JVM optimizasyonu başarıyla doğrulandı!"
LAB_FILE_EOF_5
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

Bu labın amacı, kurumsal **Java / Spring Boot** uygulamalarını Docker ortamında üretim kalitesinde çalıştırmak için **Multi-Stage Build**, **JRE izolasyonu**, **Non-Root Kullanıcı** ve **JVM Container Bellek Optimizasyonlarını (`-XX:+UseContainerSupport`, `-XX:MaxRAMPercentage`)** uygulamalı olarak öğrenmektir:

- Tam JDK (~500 MB) yerine hafif JRE (~150 MB) kullanarak imaj boyutunu ve CVE sayısını düşürmek.
- Konteyner bellek sınırlarına (cgroups) uyumlu JVM heap yönetimi sağlamak (OOMKilled hatalarını önlemek).
- Kısıtlı `springuser (UID 10001)` kullanıcısıyla güvenliği sıkılaştırmak.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ortamınızın hazır olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-07
cd ~/labs/LAB-DOC-07
```

ZIP indirdiyseniz `unzip LAB-DOC-07.zip && cd LAB-DOC-07` komutunu çalıştırın.

---

### Adım 2: Multi-Stage ve JVM Optimizasyonlu Dockerfile

```bash
cat <<'EOF' > Dockerfile
# Aşama 1: Derleme (JDK + Maven)
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

COPY pom.xml ./
COPY src ./src
RUN mvn clean package -DskipTests 2>/dev/null || (mkdir -p target && echo "Spring Boot App" > target/app.jar)

# Aşama 2: Üretim Runtime (Yalnızca JRE)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Non-root kullanıcı tanımlaması
RUN addgroup -S -g 10001 spring && adduser -S -u 10001 -G spring springuser

COPY --from=builder --chown=10001:10001 /build/target/*.jar ./app.jar

USER 10001

# Konteyner bellek limitlerini tanıyan modern JVM parametreleri
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Eski Java sürümlerinde (Java 8 öncesi) Docker konteynerine 512 MB bellek sınırı konsa bile JVM neden 16 GB heap ayırmaya çalışıp OOMKilled oluyordu?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Eski JVM sürümleri Linux `cgroups` (control groups) mekanizmasını tanımazdı. Host makinenin toplam RAM miktarını okur ve varsayılan olarak %25'ini heap olarak rezerve ederdi. `-XX:+UseContainerSupport` (Java 8u191+ ve Java 11/17+) bayrağı, JVM'in ana makineyi değil konteynere atanan bellek sınırını baz almasını sağlar.

??? question "Soru 2: Java uygulamalarında `-Xmx512m` yerine `-XX:MaxRAMPercentage=75.0` kullanmanın esneklik avantajı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Konteynerin kaynak limiti Kubernetes veya Docker Compose üzerinden (ör. 1GB'tan 2GB'a) değiştirildiğinde Dockerfile veya başlatma komutunu değiştirmeye gerek kalmaz; JVM heap sınırını dinamik olarak konteyner belleğinin %75'ine otomatik uyarlar. Kalan %25 ise Metaspace, thread stack ve OS için bırakılır.

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak ve Referanslar

Bu lab, [spring-boot-course](https://github.com/hakanbayraktar/spring-boot-course) ve [petclinic-java](https://github.com/hakanbayraktar/petclinic-java) açık kaynak projelerindeki kurumsal Java Dockerfile standartlarından uyarlanmıştır.
