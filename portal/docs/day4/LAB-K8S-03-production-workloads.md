# LAB-K8S-03 — Production Workloads: Resources, Probes, Rollouts & PVC Storage

## Metadata
- **Seviye:** PRACTITIONER
- **Önerilen Gün:** Gün 4
- **Tahmini Süre:** 60 dk
- **Gerekli Profil:** `kubernetes`
- **Host Portları:** - (Küme İçi Servis ve Pod Dağıtımı)
- **Çalışma Dizini:** `~/devops-workspace/labs/LAB-K8S-03`

---

## 1. Lab Senaryosu
Üretim ortamındaki Kubernetes iş yüklerinde kontrolsüz kaynak kullanımı, bir uygulamanın aşırı bellek tüketerek aynı düğümdeki diğer tüm podları (Noisy Neighbor etkisi) çökertmesine yol açabilir. Ayrıca sağlık probları (Liveness ve Readiness) tanımlanmamış podlar, açılış esnasında hazır olmadan trafik alarak son kullanıcılara HTTP 502/503 hataları döner. Yeni sürümler dağıtılırken kullanıcı trafiğinin kesilmemesi için sıfır kesintili (Zero-Downtime) güncelleme ve acil durum geri alma stratejileri hayati önem taşır. Bu çalışmada kaynak limitleri, Liveness/Readiness probları, RollingUpdate stratejisi ve kalıcı disk alanı (PersistentVolumeClaim - PVC) barındıran dayanıklı bir iş yükü yapılandırılır.

## 2. Amaç
Kubernetes üzerinde üretim kalitesinde (production-grade) iş yükü tasarlamak; CPU/Bellek `requests` ve `limits` tanımlayarak Burstable QoS sağlamak; Liveness/Readiness probları ile sıfır kesintili sağlık kontrolü kurmak; `RollingUpdate` stratejisi ile kesintisiz sürüm güncellemesi ve `rollout undo` ile geri alma gerçekleştirmek; PVC ile kalıcı depolama bağlamak.

## 3. Mimari / Akış
```text
  [ Deployment: robust-web-service (3 Pod) ]
         |
         +---> Kaynaklar:  requests {cpu: 50m, memory: 64Mi}
         |                 limits   {cpu: 200m, memory: 128Mi} -> QoS: Burstable
         +---> Problar:    livenessProbe  (/ - kilitlenirse podu yeniden başlat)
         |                 readinessProbe (/ - hazır olmadan trafiği kes)
         +---> Strateji:   RollingUpdate  (maxSurge: 1, maxUnavailable: 0)
         +---> Depolama:   PVC: app-storage-pvc (1Gi, local-path standard)
```

## 4. Ön Koşullar
- `LAB-K8S-02` tamamlanmış ve kind cluster çalışıyor olmalıdır
- `kubectl` CLI yapılandırılmış olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-K8S-02`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
kubectl get nodes
mkdir -p ~/devops-workspace/labs/LAB-K8S-03/manifests
cd ~/devops-workspace/labs/LAB-K8S-03
```

## 5. Adım Adım Uygulama

### Adım 1 — Kalıcı Depolama Alanını (PVC) Tanımlama
Uygulamanın disk yazma ihtiyaçları için 1 GiB boyutunda PersistentVolumeClaim oluşturun:
```yaml
cat <<'EOF' > manifests/01-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

```bash
kubectl apply -f manifests/01-pvc.yaml
kubectl get pvc app-storage-pvc
```

### Adım 2 — Üretim Seviyesi Deployment ve Servis Manifestini Yazma
Limitler, problar, RollingUpdate ve PVC bağlamasını içeren manifestoyu oluşturun:
```yaml
cat <<'EOF' > manifests/02-production-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: robust-web-service
  labels:
    app: robust-web
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: robust-web
  template:
    metadata:
      labels:
        app: robust-web
    spec:
      containers:
        - name: app
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Robust App Version 1.0.0"
            - "-listen=:8080"
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 3
            periodSeconds: 5
            failureThreshold: 2
          volumeMounts:
            - name: persistent-data
              mountPath: /data
      volumes:
        - name: persistent-data
          persistentVolumeClaim:
            claimName: app-storage-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: robust-web-service
spec:
  type: ClusterIP
  selector:
    app: robust-web
  ports:
    - port: 80
      targetPort: 8080
EOF
```

```bash
kubectl apply -f manifests/02-production-deployment.yaml
kubectl rollout status deployment/robust-web-service
```

### Adım 3 — Sıfır Kesintili Rolling Update Güncellemesi
Uygulamanın sürümünü kesintisiz olarak 2.0.0'a yükseltin:
```bash
kubectl set args deployment/robust-web-service -c=app "-text=Robust App Version 2.0.0" "-listen=:8080"
kubectl rollout status deployment/robust-web-service
```

### Adım 4 — Sürüm Geri Alma (Rollback) Testi
Rollout geçmişini görüntüleyin ve tek komutla önceki sürüme geri dönün:
```bash
kubectl rollout history deployment/robust-web-service
kubectl rollout undo deployment/robust-web-service
kubectl rollout status deployment/robust-web-service
```

## 6. Beklenen Sonuç
Adım 1'deki PVC durumu:
```text
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
app-storage-pvc   Bound    pvc-...                                    1Gi        RWO            standard
```

Adım 3'teki sıfır kesintili güncelleme akışı:
```text
Waiting for deployment "robust-web-service" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "robust-web-service" rollout to finish: 2 out of 3 new replicas have been updated...
deployment "robust-web-service" successfully rolled out
```

## 7. Doğrulama
Tüm podların Ready durumda olduğunu ve Burstable QoS sınıfında çalıştığını doğrulayın:
```bash
READY_CNT=$(kubectl get deployment robust-web-service -o jsonpath='{.status.readyReplicas}')
QOS_CLASS=$(kubectl get pods -l app=robust-web -o jsonpath='{.items[0].status.qosClass}')

if [ "$READY_CNT" -eq 3 ] && [ "$QOS_CLASS" = "Burstable" ]; then
  echo "VALIDATION SUCCESS: 3/3 pods are Ready with Burstable QoS and probes active."
else
  echo "VALIDATION FAILED: Ready: $READY_CNT, QoS: $QOS_CLASS" && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
Podlar sürekli `CrashLoopBackOff` durumuna geçer veya yeniden başlatma sayacı (`Restarts`) artar.

### Kanıt
`kubectl describe pod` çıktısında Liveness probe başarısızlık uyarısı görülür.

### Kontrol Komutu
```bash
kubectl describe pod -l app=robust-web | grep -A 8 "Events:"
```

### Muhtemel Neden
Liveness probe yolunda belirtilen endpoint (`/healthz`) uygulamada mevcut değildir (örneğin uygulama sadece `/` adresine yanıt vermektedir).

### Çözüm
Manifest içindeki probe `path` değerini uygulamanın gerçek sağlık adresiyle eşitleyin ve güncelleyin:
```bash
kubectl apply -f manifests/02-production-deployment.yaml
```

### Tekrar Doğrulama
```bash
kubectl rollout status deployment/robust-web-service
# Podların Ready 1/1 olduğu doğrulanmalıdır.
```

## 9. Temizlik / Sıfırlama
Dağıtımı, servisi ve PVC nesnesini silin:
```bash
kubectl delete -f manifests/ 2>/dev/null || true
rm -rf ~/devops-workspace/labs/LAB-K8S-03
```

## 10. Production Notu
Üretim ortamlarında `maxUnavailable: 0` ve `maxSurge: 1` tanımlanarak yeni pod tamamen ayağa kalkıp Readiness probe onayını almadan eski podun silinmesi engellenmelidir. Ayrıca açılışı uzun süren uygulamalarda (örneğin JVM tabanlı servisler) Liveness probunun erken patlamaması için mutlaka `startupProbe` tanımlanmalıdır.

## 11. Challenge
Bellek limitini (`resources.limits.memory`) `10Mi` gibi aşırı küçük bir değere çekerek Kubernetes'in Pod'u `OOMKilled` (Exit Code 137) ile nasıl sonlandırdığını gözlemleyin.
