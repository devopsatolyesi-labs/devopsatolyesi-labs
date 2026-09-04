# LAB-DOC-07 Başlangıç Dockerfile Şablonu

# TODO: Aşama 1: Builder aşamasını tanımlayın (maven:3.9-eclipse-temurin-17-alpine AS builder)
# WORKDIR /build
# COPY pom.xml ./
# COPY src ./src
# RUN javac -d target/classes src/main/java/com/devopsatolyesi/Application.java && jar cfe target/app.jar com.devopsatolyesi.Application -C target/classes .

# TODO: Aşama 2: Minimal Runtime aşamasını tanımlayın (eclipse-temurin:17-jre-alpine)
# WORKDIR /app
# RUN addgroup -S -g 10001 spring && adduser -S -u 10001 -G spring springuser
# COPY --from=builder --chown=10001:10001 /build/target/app.jar ./app.jar
# USER 10001
# ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
# EXPOSE 8080
# ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
