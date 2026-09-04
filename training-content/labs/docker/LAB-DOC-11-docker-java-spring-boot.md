# LAB-DOC-11 — Java Spring Boot Konteynerleştirme ve JVM Optimizasyonu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 50 dakika | `docker` | `8080` |

[LAB-DOC-11.zip](/downloads/LAB-DOC-11.zip)


---

## Amaç

- Kurumsal Java Spring Boot uygulamalarını modern multi-stage mimari ile konteynerleştirmek.
- Maven SDK derleyicisini Eclipse Temurin JRE çalışma ortamından izole etmek.
- JVM'in cgroup v2 bellek sınırlarını tanımasını sağlamak (`-XX:+UseContainerSupport`, `-XX:MaxRAMPercentage`).
- Spring Boot katmanlı JAR (Layered JAR / `layertools`) desenini kullanarak bağımlılık katmanlarını önbelleğe almak.
- Üretilen konteynerin bellek tüketimini ve başlatma süresini CLI ile analiz etmek.

---

## Ön Koşullar

- Docker Engine servisinin çalışır durumda olması.
- `8080` portunun boş olması.

---

## JVM ve Katmanlı JAR Mimarisi

```text
+-------------------------------------------------------------+
| 1. DERLEME: maven:3.9-eclipse-temurin-17-alpine AS builder  |
|  - pom.xml ve kaynak kodlar derlenir (mvn clean package)    |
|  - target/demo.jar üretilir ve layertools ile ayrıştırılır:  |
|    * dependencies / spring-boot-loader / application        |
+-------------------------------------------------------------+
                               │
            SADECE AYRIŞTIRILMIŞ KATMANLAR AKTARILIR
                               ▼
+-------------------------------------------------------------+
| 2. RUNTIME: eclipse-temurin:17-jre-alpine (Non-root)        |
|  - JVM Container Support devrede                            |
|  - MaxRAMPercentage=75.0 (Container RAM'inin %75'i heap)    |
|  - Sık değişmeyen kütüphaneler (dependencies) CACHED kalır  |
+-------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-11
cd ~/labs/LAB-DOC-11
```

---

### Adım 2: Spring Boot Maven Proje Dosyalarını Hazırlayın

Maven proje yapılandırmasını oluşturun:

```bash
cat <<'EOF' > pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.devopsatolyesi</groupId>
    <artifactId>spring-boot-demo</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.3</version>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <layers>
                        <enabled>true</enabled>
                    </layers>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
```

Java kaynak kodunu oluşturun:

```bash
mkdir -p src/main/java/com/devopsatolyesi
cat <<'EOF' > src/main/java/com/devopsatolyesi/DemoApplication.java
package com.devopsatolyesi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@SpringBootApplication
@RestController
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/")
    public Map<String, Object> index() {
        Runtime runtime = Runtime.getRuntime();
        return Map.of(
            "service", "Java Spring Boot Microservice",
            "maxMemoryMB", runtime.maxMemory() / (1024 * 1024),
            "totalMemoryMB", runtime.totalMemory() / (1024 * 1024),
            "freeMemoryMB", runtime.freeMemory() / (1024 * 1024),
            "availableProcessors", runtime.availableProcessors()
        );
    }
}
EOF
```

---

### Adım 3: Optimize Edilmiş Katmanlı (Layered) Dockerfile Yazın

```bash
cat <<'EOF' > Dockerfile
# Aşama 1: Maven Builder
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Bağımlılıkları önbellekle
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Kaynak kodları derle
COPY src ./src
RUN mvn clean package -DskipTests

# Spring Boot Layertools ile JAR katmanlarını ayıkla
WORKDIR /build/target
RUN java -Djarmode=layertools -jar spring-boot-demo-1.0.0.jar extract

# Aşama 2: JRE Runtime & Non-Root
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Ayrıştırılmış katmanları kopyala (En az değişenden en çok değişene)
COPY --from=builder --chown=appuser:appgroup /build/target/dependencies/ ./
COPY --from=builder --chown=appuser:appgroup /build/target/spring-boot-loader/ ./
COPY --from=builder --chown=appuser:appgroup /build/target/snapshot-dependencies/ ./
COPY --from=builder --chown=appuser:appgroup /build/target/application/ ./

USER appuser
EXPOSE 8080

# JVM Container bellek ayarları
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
EOF
```

---

### Adım 4: İmajı Derleyin

```bash
docker build -t spring-boot-demo:1.0 .
```

---

### Adım 5: Konteyneri Bellek Sınırı ile Başlatın

Konteynere 512MB RAM limiti vererek JVM'in bu limiti algılayıp algılamadığını test edin:

```bash
docker run -d   --name spring-demo   -p 8080:8080   -m 512m   spring-boot-demo:1.0
```

Konteyner loglarından başlatılma sürecini takip edin:

```bash
docker logs -f spring-demo
```

`Started DemoApplication in ... seconds` satırını gördükten sonra `Ctrl+C` ile çıkın.

---

## Doğal Doğrulama

Konteynerin çalıştığını ve JVM heap boyutunun 512MB konteyner sınırına uyarlandığını (yaklaşık 380MB) doğrulayın:

```bash
# 1. HTTP API testi
curl -s http://localhost:8080 | jq . || curl -s http://localhost:8080

# 2. Spring Boot Actuator sağlık kontrolü
curl -s http://localhost:8080/actuator/health

# 3. Docker stats ile anlık tüketim kontrolü
docker stats --no-stream spring-demo
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```json
{
  "availableProcessors": 4,
  "freeMemoryMB": 120,
  "maxMemoryMB": 384,
  "service": "Java Spring Boot Microservice",
  "totalMemoryMB": 256
}
```

---
