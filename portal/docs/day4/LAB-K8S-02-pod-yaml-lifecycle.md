# LAB-K8S-02 — İlk Pod, YAML ve Pod Yaşam Döngüsü

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 40 dakika | `kubernetes` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-02.zip)](/downloads/LAB-K8S-02.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 40 dakika | `kubernetes`, `kubectl` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-02.zip)](/downloads/LAB-K8S-02.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Kubernetes'in en küçük atomik birimi olan **Pod** mimarisini ve yaşam döngüsünü anlamak.
- Emir kipiyle (imperative) hızlı pod ayağa kaldırmak (`kubectl run`).
- Bildirimsel (declarative) YAML manifest dosyası hazırlamak (`apiVersion`, `kind`, `metadata`, `spec`).
- Pod'ları incelemek (`describe`), canlı loglarını okumak (`logs -f`) ve içine terminal oturumu açmak (`exec -it`).
- Bağımsız (standalone) bir Pod silindiğinde neden kendiliğinden yeniden **oluşmadığını** görerek Deployment ihtiyacını uygulamalı olarak kavramak.

---

## Ön Koşullar

- `LAB-K8S-01` tamamlanmış ve `devops-cluster` kümesi çalışır durumda olmalıdır.

---

## Pod Mimarisi ve Tekil Yaşam Döngüsü

```text
+-------------------------------------------------------------+
| POD (web-pod) - IP: 10.244.1.5                              |
|                                                             |
|   +-----------------------------------------------------+   |
|   | Container 1 (nginx:alpine)                          |   |
|   |   - Port 80                                         |   |
|   +-----------------------------------------------------+   |
|                                                             |
|   Paylaşılan Ağ Arayüzü (Network Namespace / localhost)     |
+-------------------------------------------------------------+
                               │
                kubectl delete pod web-pod
                               ▼
+-------------------------------------------------------------+
| POD SİLİNDİ VE YOK OLDU!                                    |
| - Tekil Pod'un self-healing (kendini onarma) yeteneği YOKTUR!|
| - Tekrar ayağa kalkması için DEPLOYMENT gereklidir!         |
+-------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-02
cd ~/labs/LAB-K8S-02
```

---

### Adım 2: Emir Kipiyle (Imperative) İlk Pod'u Başlatın

Hızlıca tek satır komutla Nginx pod'u oluşturun:

```bash
kubectl run quick-web --image=nginx:alpine --port=80
```

Pod'un hangi düğümde ve hangi IP ile çalıştığını sorgulayın:

```bash
kubectl get pods -o wide
```

---

### Adım 3: Bildirimsel (Declarative) Pod YAML Manifesti Hazırlayın

Gerçek üretim ortamlarında her şey YAML dosyaları ile kod olarak yönetilir:

```bash
cat <<'EOF' > web-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: declarative-web
  labels:
    app: demo-web
    tier: frontend
    env: training
spec:
  containers:
    - name: nginx-container
      image: nginx:alpine
      ports:
        - containerPort: 80
          name: http
      resources:
        limits:
          memory: "128Mi"
          cpu: "250m"
        requests:
          memory: "64Mi"
          cpu: "100m"
EOF
```

Manifesti kümeye uygulayın:

```bash
kubectl apply -f web-pod.yaml
```

---

### Adım 4: Pod Detaylarını ve Yaşam Döngüsü Olaylarını İnceleyin

```bash
kubectl describe pod declarative-web
```

Çıktının en altındaki **Events** bölümünde; `Scheduled` (planlandı), `Pulling` (imaj çekiliyor), `Pulled` (indirildi), `Created` (oluşturuldu) ve `Started` (başlatıldı) adımlarını inceleyin.

---

### Adım 5: Port Yönlendirme ve Pod İçine Terminal Açma

Host üzerinden Pod portuna doğrudan erişmek için port-forward başlatın:

```bash
kubectl port-forward pod/declarative-web 8080:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 2

# HTTP yanıtını host üzerinden test edin
curl -I http://localhost:8080

kill $PF_PID 2>/dev/null || true
```

Pod içerisindeki konteynerde interaktif kabuk açın ve web içeriğini yerinde değiştirin:

```bash
kubectl exec -it declarative-web -- sh -c 'echo "Merhaba Kubernetes!" > /usr/share/nginx/html/index.html'

# Değişikliği doğrulayın
kubectl exec declarative-web -- cat /usr/share/nginx/html/index.html
```

---

### Adım 6: Kritik Deney: Bağımsız Pod'u Silin

Tek başına çalışan bir Pod'un kendini iyileştirip iyileştiremediğini gözlemleyin:

```bash
kubectl delete pod declarative-web quick-web
```

Pod'ları hemen tekrar listeleyin:

```bash
kubectl get pods
```

Çıktıda `No resources found` göreceksiniz. Pod tamamen yok olmuştur!

---

## Doğal Doğrulama

Pod'un silindiğini ve sistemde hiçbir sahipsiz pod kalmadığını doğrulayın:

```bash
kubectl get pods | grep -q "declarative-web" || echo "DOĞRULAMA BAŞARILI: Tekil Pod silindi ve geri gelmedi (Deployment gerekliliği kanıtlandı)."
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Üretim ortamlarında neden doğrudan tekil Pod manifesti (`kind: Pod`) kullanılmaz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Tekil Pod'lar efemerdir (geçicidir). Pod'un çalıştığı fiziksel düğüm çökerse, düğüm bakıma alınırsa veya pod bir şekilde silinirse Kubernetes onu yeniden başlatmaz. Kendi kendini onarma (self-healing), otomatik yeniden oluşturma ve sıfır kesinti güncelleme yetenekleri için pod'lar her zaman **Deployment** veya **StatefulSet** gibi üst düzey kontrolcüler tarafından yönetilmelidir.

??? question "Soru 2: Bir Pod içinde birden fazla container (Sidecar pattern) çalıştırılabilir mi?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Evet. Bir Pod birden fazla container barındırabilir. Bu container'lar aynı ağ ad alanını (network namespace), IP adresini, port aralığını ve isteğe bağlı olarak aynı disk birimlerini (volumes) paylaşırlar. Birbirleriyle `localhost` üzerinden çok yüksek hızda haberleşebilirler.

??? question "Soru 3: `kubectl describe pod` çıktısında en çok hangi bölüme dikkat edilmelidir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        En alttaki **Events** tablosu. Pod'un neden başlamadığı, imaj çekme hataları (`ImagePullBackOff`), kaynak yetersizliği veya sağlık kontrolü arızaları doğrudan Events bölümünde açık hata metinleriyle listelenir.

---

## Beklenen Sonuç

- Adım 5'te `curl -I http://localhost:8080` komutu `HTTP/1.1 200 OK` döner.
- Adım 6'da tekil Pod silindiğinde yerine yenisinin gelmediği (`No resources found`) doğrulanır.
