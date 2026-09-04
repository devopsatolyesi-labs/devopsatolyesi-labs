# LAB-K8S-02 — Kubernetes Networking: Services, ConfigMaps & Secrets

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-K8S-02.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-K8S-02.zip && cd LAB-K8S-02`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-K8S-02
cd ~/labs/LAB-K8S-02
```

### `starter/service.yaml`

```bash
mkdir -p "$(dirname -- starter/service.yaml)"
cat > starter/service.yaml <<'LAB_FILE_EOF_1'
# TODO: Write ClusterIP Service
apiVersion: v1
kind: Service
metadata:
  name: web-service
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
kubectl delete -f service.yaml --ignore-not-found=true 2>/dev/null || true
echo "Cleanup completed for LAB-K8S-02."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
echo "Resetting workspace for LAB-K8S-02..."
bash "$lab_dir/scripts/cleanup.sh"
cp -r "$lab_dir/starter"/. .
echo "Workspace reset to starter state for LAB-K8S-02."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-02: Services, ConfigMaps & Secrets..."
kubectl apply --dry-run=client -f service.yaml
echo "[PASS] Service, ConfigMap and Secret definitions are valid."
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## 1. Lab Senaryosu
Kubernetes kümesinde çalışan Pod'lar dinamik ve geçici nesnelerdir; yeniden başlatıldıklarında veya başka bir düğüme taşındıklarında IP adresleri değişir. Uygulama bileşenlerinin birbirleriyle kesintisiz haberleşebilmesi için kalıcı bir sanal IP ve CoreDNS ismi sağlayan Service soyutlaması gereklidir. Ayrıca 12-Factor App prensipleri doğrultusunda uygulama konfigürasyonları kaynak koddan ayrılarak ConfigMap nesnelerine, hassas veritabanı şifreleri ise Secret nesnelerine taşınmalıdır. Bu çalışmada izole bir `ecommerce` ad alanı açılarak ClusterIP servisi, CoreDNS çözümlemesi, ortam değişkeni enjeksiyonu ve etiket seçici (label selector) mekanizması doğrulanır.

## 2. Amaç
Kubernetes üzerinde `ecommerce` ad alanında (Namespace) ClusterIP Servisi oluşturmak, ConfigMap ve Secret nesnelerini Pod ortam değişkeni olarak bağlamak, CoreDNS servis keşfini (`order-service.ecommerce.svc.cluster.local`) geçici bir test konteyneri ile doğrulamak.

## 3. Mimari / Akış
```text
  [ Namespace: ecommerce ]
       |
       +---> [ ConfigMap: order-api-config ] ------+ (Ortam Değişkeni Enjeksiyonu)
       +---> [ Secret: order-api-secret ] --------+ (Hassas Veri Enjeksiyonu)
       |                                           |
       v                                           v
  [ Service: order-service (ClusterIP: Port 80) ] <---> [ Deployment: order-service (2 Pod) ]
       |
       v (İç DNS: order-service.ecommerce.svc.cluster.local:80 -> TargetPort: 8000)
```

## 4. Ön Koşullar
- `LAB-K8S-01` tamamlanmış ve kind cluster çalışıyor olmalıdır
- `kubectl` CLI yapılandırılmış olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-K8S-01`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
kubectl cluster-info
mkdir -p ~/labs/LAB-K8S-02/manifests
cd ~/labs/LAB-K8S-02
```

## 5. Adım Adım Uygulama

### Adım 1 — Ad Alanı (Namespace) Tanımlama
İş yüklerini izole etmek için `ecommerce` ad alanını oluşturun:
```yaml
cat <<'EOF' > manifests/01-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce
  labels:
    environment: production
EOF
```

```bash
kubectl apply -f manifests/01-namespace.yaml
```

### Adım 2 — ConfigMap ve Secret Nesnelerini Tanımlama
Konfigürasyon parametrelerini ve hassas anahtarları bildiren manifestoyu oluşturun ve uygulayın:
```yaml
cat <<'EOF' > manifests/02-config-secret.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-api-config
  namespace: ecommerce
data:
  APP_ENV: "production"
  LOG_LEVEL: "INFO"
  CACHE_ENABLED: "true"
  PAYMENT_GATEWAY_URL: "https://api.payment.internal"
---
apiVersion: v1
kind: Secret
metadata:
  name: order-api-secret
  namespace: ecommerce
type: Opaque
stringData:
  DB_PASSWORD: "SuperSecureK8sSecretPassword!"
  API_KEY: "prod-token-xyz-987654321"
EOF
```

```bash
kubectl apply -f manifests/02-config-secret.yaml
```

### Adım 3 — Deployment ve ClusterIP Service Manifestini Uygulama
ConfigMap ve Secret verilerini ortam değişkeni olarak okuyan Deployment ile 80 portunu hedefleyen Service tanımını oluşturun:
```yaml
cat <<'EOF' > manifests/03-deployment-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: ecommerce
  labels:
    app: order-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=ORDER API v1.0.0 [ENV: PROD] - Config & Secrets Loaded"
            - "-listen=:8000"
          ports:
            - containerPort: 8000
              name: http
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: order-api-config
                  key: APP_ENV
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: order-api-secret
                  key: DB_PASSWORD
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: ecommerce
  labels:
    app: order-service
spec:
  type: ClusterIP
  selector:
    app: order-service
  ports:
    - name: http
      port: 80
      targetPort: 8000
EOF
```

```bash
kubectl apply -f manifests/03-deployment-service.yaml
kubectl rollout status deployment/order-service -n ecommerce
```

### Adım 4 — Küme İçi DNS ve Servis Keşfi Doğrulaması
Küme içinde geçici bir test podu (`test-curl`) çalıştırarak servis adı üzerinden HTTP isteği gönderin:
```bash
kubectl run test-curl --rm -i --tty --restart='Never' --namespace=ecommerce \
  --image=curlimages/curl:8.10.1 -- curl -s http://order-service.ecommerce.svc.cluster.local:80
```

## 6. Beklenen Sonuç
Adım 3'teki rollout tamamlanma çıktısı:
```text
deployment "order-service" successfully rolled out
```

Adım 4'teki iç DNS isteği çıktısı:
```text
ORDER API v1.0.0 [ENV: PROD] - Config & Secrets Loaded
```

## 7. Doğrulama
`order-service` nesnesine geçerli bir ClusterIP atandığını ve CoreDNS adının çözümlendiğini doğrulayın:
```bash
SVC_IP=$(kubectl get svc order-service -n ecommerce -o jsonpath='{.spec.clusterIP}')
if [ -n "$SVC_IP" ] && [ "$SVC_IP" != "None" ]; then
  echo "VALIDATION SUCCESS: Service 'order-service' assigned ClusterIP: $SVC_IP and responded to internal DNS."
else
  echo "VALIDATION FAILED: Invalid or missing ClusterIP." && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
`test-curl` podu servise istek attığında `Connection refused` veya zaman aşımı hatası alınır.

### Kanıt
`kubectl get endpoints order-service -n ecommerce` komutu çıktısında hedef IP listesi boştur (`<none>`).

### Kontrol Komutu
```bash
kubectl get endpoints order-service -n ecommerce
kubectl get pods -n ecommerce --show-labels
```

### Muhtemel Neden
Service manifestindeki `spec.selector.app` etiketi ile Deployment şablonundaki `spec.template.metadata.labels.app` etiketi birbiriyle eşleşmemektedir.

### Çözüm
Service selector etiketini Deployment pod etiketiyle (`app: order-service`) birebir eşitleyip manifestoyu güncelleyin:
```bash
kubectl apply -f manifests/03-deployment-service.yaml
```

### Tekrar Doğrulama
```bash
kubectl get endpoints order-service -n ecommerce
# Pod IP adresleri listelenmelidir (örn. 10.244.x.x:8000).
```

## 9. Temizlik / Sıfırlama
`ecommerce` ad alanını silerek tüm bağlı servis ve podları temizleyin:
```bash
kubectl delete namespace ecommerce 2>/dev/null || true
rm -rf ~/labs/LAB-K8S-02
```

## 10. Production Notu
Üretim ortamlarında hassas anahtarlar (API key, DB parolası) Kubernetes Secret nesnelerinde düz metin veya statik YAML olarak tutulmaz; HashiCorp Vault veya AWS Secrets Manager ile entegre çalışan External Secrets Operator (ESO) kullanılır. Ayrıca etcd veritabanında `EncryptionConfiguration` aktif edilerek disk düzeyinde şifreleme sağlanmalıdır.

## 11. Challenge
`kubectl exec` komutunu kullanarak `order-service` podlarından birinin içine bağlanın ve `env` komutunu çalıştırarak `DB_PASSWORD` ve `APP_ENV` değişkenlerinin yüklendiğini inceleyin.
