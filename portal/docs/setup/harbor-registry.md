# Harbor Private Registry ve TLS Kurulumu

Bu rehber, kurumsal container imaj yönetimi, güvenlik taraması (Trivy) ve Helm OCI chart barındırma için **Harbor Private Registry** bileşeninin kurulumunu adım adım açıklar.

---

## 1. Ön Koşullar

- Docker Engine ve Docker Compose v2 kurulu olmalıdır.
- OpenSSL aracı kurulu olmalıdır.

---

## 2. Kendi Kendine İmzalı (Self-Signed) TLS Sertifikası Üretimi

Harbor ve Docker güvenli HTTPS iletişimi için geçerli bir sertifika gerektirir:

```bash
mkdir -p ~/harbor-certs
cd ~/harbor-certs

DOMAIN="harbor.devopsatolyesi.local"

# CA Sertifikası
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650   -subj "/C=TR/ST=Istanbul/L=Istanbul/O=DevOpsAtolyesi/OU=Labs/CN=$DOMAIN"   -key ca.key -out ca.crt

# Sunucu Sertifikası
openssl genrsa -out server.key 4096
openssl req -sha512 -new   -subj "/C=TR/ST=Istanbul/L=Istanbul/O=DevOpsAtolyesi/OU=Labs/CN=$DOMAIN"   -key server.key -out server.csr

# SAN (Subject Alternative Name) Yapılandırması
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = harbor.devopsatolyesi.local
IP.1 = 127.0.0.1
EOF

openssl x509 -req -sha512 -days 3650 -extfile v3.ext   -CA ca.crt -CAkey ca.key -CAcreateserial   -in server.csr -out server.crt

# Docker istemcisine CA sertifikasını tanıtın
sudo mkdir -p /etc/docker/certs.d/$DOMAIN/
sudo cp ca.crt /etc/docker/certs.d/$DOMAIN/ca.crt
sudo systemctl restart docker
```

---

## 3. Harbor Offline Installer ile Kurulum

```bash
HARBOR_VERSION="v2.10.0"
curl -SL "https://github.com/goharbor/harbor/releases/download/$HARBOR_VERSION/harbor-offline-installer-$HARBOR_VERSION.tgz" -o ~/harbor.tgz
tar -xzf ~/harbor.tgz -C ~/
cd ~/harbor

# Yapılandırma dosyasını kopyalayın
cp harbor.yml.tmpl harbor.yml

# harbor.yml dosyasını düzenleyin
sed -i "s/hostname: reg.yourdomain.com/hostname: $DOMAIN/g" harbor.yml
sed -i "s|/your/certificate/path|/home/$USER/harbor-certs/server.crt|g" harbor.yml
sed -i "s|/your/private/key/path|/home/$USER/harbor-certs/server.key|g" harbor.yml

# Trivy güvenlik tarayıcısı ile birlikte kurulumu başlatın
sudo ./install.sh --with-trivy
```

---

## 4. Harbor Giriş ve Test

```bash
# /etc/hosts dosyasına ekleyin
echo "127.0.0.1 harbor.devopsatolyesi.local" | sudo tee -a /etc/hosts

# Docker CLI ile login testi
docker login harbor.devopsatolyesi.local -u admin -p Harbor12345
```
