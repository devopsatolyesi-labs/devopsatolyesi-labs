# Jenkins Kurulum Rehberi (Docker & Kubernetes)

Bu rehber, eğitim lablarında kullanılmak üzere **Jenkins Automation Server** ın hem **Docker Compose** üzerinde hem de **Kubernetes (Helm)** üzerinde kurulumunu adım adım açıklar.

---

## 1. Docker Compose ile Hızlı Jenkins Kurulumu

Docker-in-Docker (DinD) ve container build yetenekleri içeren güvenli bir Jenkins ortamı kuralım.

### Adım 1: Dizin ve Yetkilendirme

```bash
mkdir -p ~/jenkins-setup
cd ~/jenkins-setup
sudo chown -R 1000:1000 ~/jenkins-setup
```

### Adım 2: docker-compose.yaml Dosyası

```bash
cat <<EOF > docker-compose.yaml
version: "3.8"

services:
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins-server
    restart: unless-stopped
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=true
    volumes:
      - jenkins_data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker:ro

volumes:
  jenkins_data:
    driver: local
EOF
```

### Adım 3: Başlatma ve İlk Şifreyi Alma

```bash
docker compose up -d

# Logları kontrol edin ve başlangıç şifresini alın
docker compose logs -f
# Veya doğrudan şifre dosyasını okuyun:
docker exec -it jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
```

Tarayıcınızdan `http://<IP-ADRESINIZ>:8080` adresine giderek kurulum sihirbazını tamamlayın.

---

## 2. Kubernetes Üzerinde Helm ile Jenkins Kurulumu

Production benzeri ortamlarda Kubernetes pod agent ları kullanmak için:

```bash
# Helm deposunu ekleyin
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Jenkins values dosyasını oluşturun
cat <<EOF > jenkins-values.yaml
controller:
  componentName: "jenkins-controller"
  image: "jenkins/jenkins"
  tag: "lts-jdk17"
  serviceType: NodePort
  nodePort: 32000
  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - blueocean:latest
    - credentials-binding:latest
persistence:
  enabled: true
  size: "10Gi"
EOF

# Jenkins i kurun
helm install jenkins jenkins/jenkins -n jenkins --create-namespace -f jenkins-values.yaml

# Admin şifresini alın
kubectl get secret -n jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode; echo
```
