# LAB-K8S-08 — PersistentVolume ve PersistentVolumeClaim

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 45 dakika | `kubernetes` | `Küme içi` |

[LAB-K8S-08.zip](/downloads/LAB-K8S-08.zip)


---

## Amaç

- Kubernetes'in durum bilgisi içeren (stateful) uygulamalarda veri kalıcılığı mimarisini kavramak.
- **StorageClass** üzerinden dinamik depolama birimi tahsisini (**Dynamic Provisioning**) gözlemlemek.
- **PersistentVolumeClaim (PVC)** tanımlayarak PostgreSQL veritabanına kalıcı disk alanı bağlamak.
- Pod silindiğinde bile veritabanı tablolarının ve kayıtlarının yeni açılan Pod tarafından eksiksiz okunduğunu kanıtlamak.
- `emptyDir` (geçici) ile `PVC` (kalıcı) arasındaki farkı test etmek.

---

## Ön Koşullar

- Kind kümesi aktif olmalıdır.

---

## PersistentVolume ve PVC Mimarisi

```text
[ STORAGECLASS: standard ] (Dinamik Disk Üretici)
            │
            ▼ Otomatik Üretir
[ PERSISTENTVOLUME (PV) ] (1Gi HostPath Disk Alanı)
            │
            │ Eşleşir (Bound)
            ▼
[ PERSISTENTVOLUMECLAIM (postgres-pvc) ]
            │
            │ volumeMounts: /var/lib/postgresql/data
            ▼
+------------------------------------+
| POD: postgres-db                   |
| - Veritabanı Tablosu: orders       |  <--- kubectl delete pod postgres-db
+------------------------------------+
            │
            ▼ (Yeni Pod Oluşur)
+------------------------------------+
| YENİ POD: postgres-db-new          |
| - Aynı PVC'ye bağlanır             |
| - Veriler EKSİKSİZ KORUNUR!        |
+------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-08
cd ~/labs/LAB-K8S-08
```

---

### Adım 2: Kümedeki Varsayılan StorageClass Nesnesini İnceleyin

```bash
kubectl get storageclass
```

Kind ortamında `standard (default)` adında dinamik bir yerel depolama sınıfının aktif olduğunu görün.

---

### Adım 3: PersistentVolumeClaim (PVC) Tanımlayın

```bash
cat <<'EOF' > postgres-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

kubectl apply -f postgres-pvc.yaml
kubectl get pvc postgres-pvc
```

Durumun `Bound` olduğunu ve dinamik olarak arka planda 1Gi boyutunda bir `PersistentVolume (PV)` üretildiğini görün.

---

### Adım 4: PVC Bağlı PostgreSQL Pod'u Başlatın

```bash
cat <<'EOF' > postgres-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-db
  labels:
    app: postgres
spec:
  containers:
    - name: postgres
      image: postgres:16-alpine
      env:
        - name: POSTGRES_PASSWORD
          value: "MasterPass2026"
        - name: POSTGRES_DB
          value: "school"
      ports:
        - containerPort: 5432
      volumeMounts:
        - name: db-data
          mountPath: /var/lib/postgresql/data
  volumes:
    - name: db-data
      persistentVolumeClaim:
        claimName: postgres-pvc
EOF

kubectl apply -f postgres-pod.yaml
```

Pod'un `Running` olmasını bekleyin (`kubectl get pod postgres-db -w`).

---

### Adım 5: Veritabanına Kritik Veri Ekleyin

```bash
kubectl exec -i postgres-db -- psql -U postgres -d school <<'EOF'
CREATE TABLE students (id SERIAL PRIMARY KEY, name VARCHAR(50), grade INT);
INSERT INTO students (name, grade) VALUES ('Ahmet Yilmaz', 95);
INSERT INTO students (name, grade) VALUES ('Ayse Demir', 100);
SELECT * FROM students;
EOF
```

---

### Adım 6: Kritik Test: Pod'u Silin ve Verinin Korunduğunu Kanıtlayın

Veritabanı Pod'unu tamamen yok edelim:

```bash
kubectl delete pod postgres-db
```

Şimdi aynı YAML dosyası ile yeni bir Pod oluşturalım:

```bash
kubectl apply -f postgres-pod.yaml
sleep 5
```

Yeni Pod içerisinden verileri sorgulayın:

```bash
kubectl exec -i postgres-db -- psql -U postgres -d school -c "SELECT * FROM students;"
```

`Ahmet Yilmaz` ve `Ayse Demir` kayıtlarının silinmediğini, verilerin PVC sayesinde fiziksel diskte korunduğunu görün!

---

## Doğal Doğrulama

```bash
# Veritabanında 2 öğrencinin bulunduğunu doğrulayın
STUDENT_COUNT=$(kubectl exec -i postgres-db -- psql -U postgres -d school -t -c "SELECT COUNT(*) FROM students;" | tr -d ' ')
[ "$STUDENT_COUNT" -eq 2 ] && echo "DOĞRULAMA BAŞARILI: Veri kalıcılığı PVC ile kanıtlandı."
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```text
 id |     name     | grade 
----+--------------+-------
  1 | Ahmet Yilmaz |    95
  2 | Ayse Demir   |   100
(2 rows)
```
