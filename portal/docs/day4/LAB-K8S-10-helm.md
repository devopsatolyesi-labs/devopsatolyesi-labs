# LAB-K8S-10 — Helm ile Uygulama Kurulumu ve Güncelleme

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `kubernetes, helm` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-10.zip)](/downloads/LAB-K8S-10.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 50 dakika | `kubernetes`, `helm` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-10.zip)](/downloads/LAB-K8S-10.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Kubernetes paket yöneticisi **Helm** mimarisini ve temel terminolojisini (Chart, Release, Values) öğrenmek.
- Standart bir Helm chart yapısını (`Chart.yaml`, `values.yaml`, `templates/`) incelemek.
- `helm install` ile parametreleri özelleştirerek ilk uygulamayı yayınlamak.
- `values.yaml` üzerinden replika sayısını ve imaj sürümünü değiştirip `helm upgrade` ile güncellemek.
- Dağıtım geçmişini incelemek (`helm history`) ve hatalı bir sürümden `helm rollback` ile geri dönmek.
- `helm uninstall` ile oluşturulan tüm nesneleri temiz şekilde kaldırmak.

---

## Ön Koşullar

- Kind kümesi çalışır durumda olmalıdır.
- `helm` CLI aracı kurulu olmalıdır (`helm version`).

---

## Helm Paketleme ve Release Yaşam Döngüsü

```text
[ HELM CHART (training-app) ]
  ├── Chart.yaml (Paket metadata ve sürümü)
  ├── values.yaml (Varsayılan değişkenler: replicaCount, image, port)
  └── templates/ (K8s YAML şablonları: deployment.yaml, service.yaml)
             │
             │ helm install my-app ./chart --set replicaCount=3
             ▼
[ HELM RELEASE (my-app, Revizyon: 1) ]
  ├── Deployment (3 Pod)
  └── Service (ClusterIP)
             │
             │ helm upgrade my-app ./chart --set image.tag=1.26
             ▼
[ HELM RELEASE (my-app, Revizyon: 2) ]
             │
             │ helm rollback my-app 1 (Acil geri alma)
             ▼
[ HELM RELEASE (my-app, Revizyon: 3) ] (Revizyon 1 durumuna döndü)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-10
cd ~/labs/LAB-K8S-10
```

---

### Adım 2: Sade Bir Helm Chart Oluşturun

Öğrenim amacıyla sade ve temiz bir mikroservis chart'ı oluşturalım:

```bash
mkdir -p my-web-chart/templates

cat <<'EOF' > my-web-chart/Chart.yaml
apiVersion: v2
name: my-web-chart
description: DevOps Atölyesi Eğitim Helm Chart
type: application
version: 0.1.0
appVersion: "1.25"
EOF

cat <<'EOF' > my-web-chart/values.yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.25-alpine"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
EOF

cat <<'EOF' > my-web-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-web
  labels:
    app: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: web
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}
EOF

cat <<'EOF' > my-web-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
EOF
```

---

### Adım 3: Chart'ı Test Edin ve Kurulumu Yapın (Helm Install)

Önce şablonların doğru render edildiğini doğrulamak için `helm template` çalıştırın:

```bash
helm template test-release ./my-web-chart
```

Şimdi uygulamayı 3 replika ile yayınlayın:

```bash
helm install training-app ./my-web-chart --set replicaCount=3
```

Aktif release listesini ve oluşturulan nesneleri inceleyin:

```bash
helm list
kubectl get deployment,pods,service -l app=training-app
```

---

### Adım 4: Uygulamayı Güncelleyin (Helm Upgrade)

Özel bir değerler dosyası (`prod-values.yaml`) hazırlayarak replikayı 4'e çıkaralım ve imajı güncelleyelim:

```bash
cat <<'EOF' > prod-values.yaml
replicaCount: 4
image:
  tag: "1.26-alpine"
EOF

helm upgrade training-app ./my-web-chart -f prod-values.yaml
```

Dağıtım geçmişini görüntüleyin:

```bash
helm history training-app
```

Revizyon 2'nin yayınlandığını ve Pod sayısının 4'e yükseldiğini doğrulayın:

```bash
kubectl get pods -l app=training-app
```

---

### Adım 5: Acil Geri Alma (Helm Rollback)

Sistemi tek komutla Revizyon 1 durumuna geri alın:

```bash
helm rollback training-app 1
```

Geçmişi ve pod durumunu tekrar kontrol edin:

```bash
helm history training-app
kubectl get deployment training-app-web
```

Revizyon 3'ün oluşturulduğunu ve replika sayısının tekrar 3'e indiğini görün.

---

## Doğal Doğrulama

```bash
# Helm release durumunun deployed olduğunu doğrulayın
helm status training-app | grep -q "STATUS: deployed" && echo "DOĞRULAMA BAŞARILI: Helm release sağlıklı!"
```

---

### Adım 6: Temizlik (Helm Uninstall)

```bash
helm uninstall training-app
```

Tüm deployment, service ve pod'ların tek komutla temizlendiğini teyit edin (`kubectl get pods -l app=training-app`).

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: `kubectl apply -f manifest.yaml` varken neden Helm gibi bir paket yöneticisine ihtiyaç duyarız?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Düz YAML dosyaları statiktir; ortamdan ortama (dev, staging, prod) değişen replika sayısı, CPU limitleri veya domain adları için onlarca kopya oluşturmak gerekir. Helm, YAML dosyalarını dinamik şablonlara (templates) dönüştürür. Ayrıca versiyonlama, tek komutla yükseltme (`upgrade`), geçmiş izleme (`history`), otomatik geri alma (`rollback`) ve temiz kaldırma (`uninstall`) yetenekleri sağlar.

---

## Beklenen Sonuç

- `helm list` komutunun `training-app` release'ini listelemesi.
- `helm rollback` sonrası revizyonun güncellenmesi.
