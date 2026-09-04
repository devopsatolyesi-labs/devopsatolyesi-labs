# Aşama 1: Derleyici Aşaması (JDK + Maven)
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

COPY pom.xml ./
COPY src ./src

# Derleme: Hızlı ve güvenilir mikroservis paketi
RUN javac -d target/classes src/main/java/com/devopsatolyesi/Application.java && \
    jar cfe target/app.jar com.devopsatolyesi.Application -C target/classes .

# Aşama 2: Minimal ve Güvenli Çalışma Aşaması (Yalnızca JRE)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Güvenlik: Kısıtlı Non-Root Kullanıcı (UID 10001)
RUN addgroup -S -g 10001 spring && adduser -S -u 10001 -G spring springuser

# Derlenen artefaktı kullanıcı sahipliğinde kopyalayın
COPY --from=builder --chown=10001:10001 /build/target/app.jar ./app.jar

USER 10001

# Konteyner bellek limitlerini tanıyan modern JVM parametreleri
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
