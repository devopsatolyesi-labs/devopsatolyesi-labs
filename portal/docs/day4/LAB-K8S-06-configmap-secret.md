# LAB-K8S-06 — ConfigMap ve Secret ile Yapılandırma

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `kubernetes` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-06.zip)](/downloads/LAB-K8S-06.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `kubernetes`, `kubectl` | `80` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-06.zip)](/downloads/LAB-K8S-06.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- 12-Factor App prensibine uygun olarak uygulama konfigürasyonunu ve şifreleri Docker imajından tamamen ayırmak.
- **ConfigMap** oluşturarak ortam değişkeni (`envFrom`, `valueFrom`) ve dosya (`volumeMounts`) olarak Pod'a bağlamak.
- **Secret** oluşturmak, Base64 kodlamanın bir şifreleme olmadığını anlamak ve hassas verileri güvenle saklamak.
- Çalışan bir Pod içerisinde enjekte edilen konfigürasyon ve gizli anahtarları CLI ile denetlemek.

---

## Ön Koşullar

- Kind kümesi aktif olmalıdır.

---

## Konfigürasyon ve Secret Enjeksiyon Modeli

```text
[ ConfigMap: app-config ]                [ Secret: app-secret ]
  - APP_NAME: "Payment Gateway"            - DB_USER: "postgres"
  - LOG_LEVEL: "debug"                     - DB_PASSWORD: "SuperSecret2026"
             │                                        │
             ├───────────────────┬────────────────────┤
             ▼                                        ▼
+--------------------------------------------------------------------+
| POD (payment-service)                                              |
|  - Ortam Değişkeni: APP_NAME, DB_USER, DB_PASSWORD                 |
|  - Dosya Mount: /etc/config/app.json (Canlı güncellenebilir)       |
+--------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-06
cd ~/labs/LAB-K8S-06
```

---

### Adım 2: ConfigMap Oluşturun

Bildirimsel olarak uygulama ayarlarını içeren bir ConfigMap tanımlayın:

```bash
cat <<'EOF' > app-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_NAME: "Payment Gateway API"
  APP_ENV: "production"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
EOF

kubectl apply -f app-config.yaml
```

---

### Adım 3: Secret Oluşturun ve Base64 Analizi Yapın

Hassas veritabanı kimlik bilgilerini içeren Secret nesnesi oluşturun:

```bash
kubectl create secret generic app-secrets \
  --from-literal=DB_USER=pgadmin \
  --from-literal=DB_PASSWORD=MasterSecretPassword2026

# Secret içeriğini YAML olarak inceleyin
kubectl get secret app-secrets -o yaml
```

> [!IMPORTANT]
> `data` altındaki değerlerin Base64 ile encode edildiğini görün. Base64 bir **şifreleme (encryption) değildir**, sadece ikili veriyi metne çevirme formatıdır:
> ```bash
> echo "UGFzc3dvcmQ=" | base64 --decode
> ```

---

### Adım 4: ConfigMap ve Secret Tüketen Pod Manifesti Hazırlayın

Hem ortam değişkeni olarak hem de dosya sistemi mount'u olarak enjekte edelim:

```bash
cat <<'EOF' > secure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  labels:
    app: secure-app
spec:
  containers:
    - name: api
      image: alpine:3.19
      command: ["sh", "-c", "echo 'Application configured.' && sleep infinity"]
      # 1. ConfigMap'teki tüm anahtarları ortam değişkeni olarak aktarma
      envFrom:
        - configMapRef:
            name: app-config
      # 2. Secret'tan tekil hassas değerleri ortam değişkeni yapma
      env:
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_USER
        - name: DATABASE_PASS
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
      # 3. ConfigMap'i dosya olarak bağlama (Mount)
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
  volumes:
    - name: config-volume
      configMap:
        name: app-config
EOF

kubectl apply -f secure-pod.yaml
```

---

## Doğal Doğrulama

Pod içine girerek ortam değişkenlerinin ve bağlanan dosyaların varlığını doğrulayın:

```bash
# 1. Ortam değişkenlerini sorgulayın
kubectl exec secure-app -- env | grep -E "(APP_|DATABASE_)"

# 2. /etc/config dizinindeki dosyaları inceleyin
kubectl exec secure-app -- ls -l /etc/config
kubectl exec secure-app -- cat /etc/config/APP_NAME
```

---

### Adım 5: Temizlik

```bash
kubectl delete pod secure-app
kubectl delete configmap app-config
kubectl delete secret app-secrets
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: ConfigMap ortam değişkeni olarak mı yoksa Volume Mount olarak mı bağlanmalıdır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Eğer ayarlar ortam değişkeni (`env`) olarak verilirse, ConfigMap güncellendiğinde Pod yeniden başlatılana (restart) kadar yeni değerleri **ALAMAZ**. Ancak Volume Mount (`/etc/config`) olarak bağlanırsa, Kubernetes arka planda symlink'leri günceller ve Pod yeniden başlatılmadan saniyeler içinde yeni değerler dosya sistemine yansır.

??? question "Soru 2: Kubernetes Secret'ları varsayılan olarak etcd veritabanında nasıl saklanır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Varsayılan Kubernetes kurulumlarında Secret'lar etcd içerisinde **düz metin (plaintext/base64)** olarak saklanır! Üretim ortamlarında etcd düzeyinde şifreleme (**Encryption at Rest**) veya HashiCorp Vault / External Secrets Operator gibi harici kasalar kullanılmalıdır.

---

## Beklenen Sonuç

- `kubectl exec secure-app -- env` komutunun `DATABASE_USER=pgadmin` değerini döndürmesi.
- `/etc/config/APP_NAME` dosyasının `Payment Gateway API` içeriğini barındırması.
