# LAB-INC-01 — War Room: Kubernetes CrashLoopBackOff, ImagePullBackOff & Postmortem

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 45 dakika | `kubernetes` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-INC-01.zip)](/downloads/LAB-INC-01.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


## 1. Lab Senaryosu
Üretim ortamına yeni bir mikroservis sürümü dağıtıldıktan hemen sonra müşteri sipariş akışı durmuş ve sistem alarmları tetiklenmiştir. Canlı kümede aynı anda üç farklı arıza yaşanmaktadır: Ödeme servisi eksik ortam değişkeni nedeniyle sürekli çökmekte (`CrashLoopBackOff`), sepet servisi yazım hatası içeren bir imaj etiketi nedeniyle başlatılamamakta (`ImagePullBackOff`), katalog servisi ise yanlış port dinleyen bir sağlık probu yüzünden trafik alamamaktadır (`0/1 Ready`). Bu çalışmada SRE ve DevOps kriz masası (War Room) metodolojisi uygulanır; `kubectl describe`, `kubectl logs --previous` ve event kayıtları incelenerek üç arıza teşhis edilir, onarılır ve kurumsal bir Blameless Postmortem raporu düzenlenir.

## 2. Amaç
Kubernetes kümesinde eşzamanlı ortaya çıkan `CrashLoopBackOff`, `ImagePullBackOff` ve `Readiness Probe Failure` arızalarını sistemli teşhis araçlarıyla analiz etmek, kök nedenleri tespit edip canlı sistemi kesintisiz onarmak ve kurumsal Blameless Postmortem dokümantasyonunu tamamlamak.

## 3. Mimari / Akış
```text
  [ Olay Ad Alanı: "production-incident" ]
       |
       +---> [ Pod: payment-service ] ---> Durum: CrashLoopBackOff (Eksik DB_HOST)
       +---> [ Pod: cart-service ]    ---> Durum: ImagePullBackOff (Hatalı İmaj Tag)
       +---> [ Pod: catalog-service ] ---> Durum: 0/1 Running (Readiness Port Uyuşmazlığı)
```

## 4. Ön Koşullar
- `LAB-K8S-01` ve `LAB-K8S-03` tamamlanmış ve kind cluster çalışıyor olmalıdır
- `kubectl` CLI yetkili olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-K8S-03`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
kubectl get nodes
mkdir -p ~/labs/LAB-INC-01/broken-manifests ~/labs/LAB-INC-01/reports
cd ~/labs/LAB-INC-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Kasıtlı Arızalı Manifestoları Uygulama (Arıza Başlatma)
Kriz masası simülasyonunu başlatmak için 3 arızalı servisi içeren manifestoyu uygulayın:
```yaml
cat <<'EOF' > broken-manifests/incident-stack.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production-incident
---
# ARIZA 1: Eksik ortam degiskeni (CrashLoopBackOff)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: production-incident
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh", "-c"]
          args:
            - |
              echo "Checking DB credentials..."
              if [ -z "$DB_HOST" ]; then
                echo "CRITICAL ERROR: DB_HOST is not set! Exiting..." >&2
                exit 1
              fi
              echo "Connected to DB: $DB_HOST" && sleep 3600
---
# ARIZA 2: Yanlis imaj etiketi (ImagePullBackOff)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cart-service
  namespace: production-incident
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cart-service
  template:
    metadata:
      labels:
        app: cart-service
    spec:
      containers:
        - name: app
          image: nginx:non-existent-tag-999.9.9
---
# ARIZA 3: Yanlis readiness portu (0/1 Ready, Trafik Kesildi)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-service
  namespace: production-incident
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog-service
  template:
    metadata:
      labels:
        app: catalog-service
    spec:
      containers:
        - name: app
          image: hashicorp/http-echo:0.2.3
          args: ["-text=Catalog Ready", "-listen=:8080"]
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /
              port: 9999
            initialDelaySeconds: 2
            periodSeconds: 3
EOF
```

```bash
kubectl apply -f broken-manifests/incident-stack.yaml
sleep 15
kubectl get pods -n production-incident
```

### Adım 2 — Arıza 1 (CrashLoopBackOff) Teşhis ve Çözümü
Önceki çökme logunu inceleyin ve eksik değişkeni tanımlayın:
```bash
# Cokme logunu oku
kubectl logs -l app=payment-service -n production-incident --previous

# Cozum: Ortam degiskenini ekle
kubectl set env deployment/payment-service -n production-incident DB_HOST="postgres.production.svc"
```

### Adım 3 — Arıza 2 (ImagePullBackOff) Teşhis ve Çözümü
Event kayıtlarını denetleyin ve imaj etiketini geçerli sürüme çekin:
```bash
# Eventleri oku
kubectl describe pod -l app=cart-service -n production-incident | grep -A 3 "Events:"

# Cozum: Gecerli imaj etiketini ata
kubectl set image deployment/cart-service -n production-incident app=nginx:1.27-alpine
```

### Adım 4 — Arıza 3 (Readiness Probe Failure) Teşhis ve Çözümü
Probe hata kaydını okuyun ve port uyuşmazlığını düzeltin:
```bash
# Probe hatasini incele
kubectl describe pod -l app=catalog-service -n production-incident | grep -A 2 "Unhealthy"

# Cozum: Portu 8080 olarak yamala (patch)
kubectl patch deployment catalog-service -n production-incident --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/port", "value": 8080}]'
```

### Adım 5 — Tüm Podların Ready Durumuna Ulaşmasını Bekleme
Podların iyileşmesini takip edin:
```bash
kubectl wait --for=condition=Ready pods --all -n production-incident --timeout=60s
kubectl get pods -n production-incident
```

### Adım 6 — Blameless Postmortem Raporunu Hazırlama
Olay sonrası kök neden analizini ve önleyici aksiyonları içeren raporu oluşturun:
```markdown
cat <<'EOF' > reports/postmortem-incident-101.md
# Incident Postmortem — INC-101: Production Cluster Outage

## 1. Ozet
- **Tarih & Saat:** 2026-08-27 10:00 UTC
- **Kesinti Suresi:** 12 dakika
- **Etki:** Odeme, Sepet ve Katalog servisleri kullanicilara gecici olarak hizmet veremedi.
- **Kriz Yoneticisi:** SRE & DevOps Incident Lead

## 2. Kok Neden Analizi (5 Whys)
1. **Odeme servisi neden coktu?** Konteyner Exit Code 1 ile sonlandi.
2. **Neden sonlandi?** `DB_HOST` ortam degiskeni deployment manifestosunda tanimli degildi.
3. **Sepet servisi neden baslamadi?** Imaj etiketinde yazim hatasi (`non-existent-tag-999.9.9`) vardi.
4. **Katalog servisi neden trafik almadi?** Readiness probu 8080 yerine 9999 portunu dinliyordu.
5. **Kok Neden:** CI/CD hattinda sema dogrulamasi (`kubeconform`) ve otomatik imaj varlik kontrolunun eksik olmasi.

## 3. Onleyici Aksiyon Plani (Action Items)
| No | Aksiyon | Sorumlu | Oncelik |
|---|---|---|---|
| ACT-01 | CI hattina kubeconform ve sema dogrulamasi eklenmesi | DevOps | P0 |
| ACT-02 | Dagitim oncesi Harbor uzerinde imaj etiketi kontrolu zorunlulugu | CI Team | P1 |
| ACT-03 | Ortak Helm Chart sablonlari ile standart port ve probe tanimlarinin zorunlu kilinmasi | SRE | P1 |
EOF
```

## 6. Beklenen Sonuç
Adım 1'deki arıza tablosu:
```text
NAME                               READY   STATUS             RESTARTS
cart-service-xxxxxxxx-xxxxx        0/1     ImagePullBackOff   0
catalog-service-xxxxxxxx-xxxxx     0/1     Running            0
payment-service-xxxxxxxx-xxxxx     0/1     CrashLoopBackOff   2
```

Adım 5'te onarım sonrası pod durumu:
```text
NAME                               READY   STATUS    RESTARTS
cart-service-xxxxxxxx-xxxxx        1/1     Running   0
catalog-service-xxxxxxxx-xxxxx     1/1     Running   0
payment-service-xxxxxxxx-xxxxx     1/1     Running   0
```

## 8. Sorun Giderme

### Belirti
`kubectl logs` komutu çalıştırıldığında çıktı boş döner ve podun neden çöktüğü anlaşılamaz.

### Kanıt
Pod sürekli yeniden başladığı için mevcut konteyner henüz çıktı üretmeden sonlanmaktadır.

### Kontrol Komutu
```bash
kubectl logs <pod-name> -n production-incident --previous
```

### Muhtemel Neden
Pod restart olduktan sonra varsayılan `kubectl logs` yalnızca aktif konteynerin loglarını okur; çöken konteynerin logu okunamaz.

### Çözüm
Bir önceki çöküşün loglarını almak için mutlaka `--previous` parametresini kullanın.

### Tekrar Doğrulama
```bash
kubectl logs -l app=payment-service -n production-incident --previous
# Hata mesajı ekranda görüntülenmelidir.
```

## 10. Production Notu
Kurumsal SRE kültüründe arızalar bireysel suçlama (Blameless Culture) ile değil; süreç, araç ve mimari eksiklikleri giderecek şekilde analiz edilir. CI boru hatlarına `kubeconform` veya `conftest` eklenerek hatalı port ve eksik değişken içeren manifestoların cluster'a uygulanması otomatik olarak engellenmelidir.

## 11. Challenge
`kubectl get events -n production-incident --sort-by='.metadata.creationTimestamp'` komutunu kullanarak kümedeki olay akışını kronolojik sırada listeleyen bir olay zaman çizelgesi (timeline) çıkarın.
