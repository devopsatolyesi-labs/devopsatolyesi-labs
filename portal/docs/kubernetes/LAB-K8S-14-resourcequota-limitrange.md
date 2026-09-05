# LAB-K8S-14 — ResourceQuota ve LimitRange ile Namespace Kaynak Yönetimi

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 40 dakika | `kubernetes` | `Küme içi` |

[LAB-K8S-14.zip](/downloads/LAB-K8S-14.zip)


40 dakika | `kubernetes` | `Küme içi` |

## Amaç

- Namespace toplam CPU, bellek, Pod ve PVC tüketimini sınırlandırmak
- Container’lara varsayılan request/limit uygulamak
- Kurala uyan ve reddedilen workload sonuçlarını API sunucusundan gözlemlemek

## Ön Koşullar

```bash
kubectl cluster-info
kubectl auth can-i create resourcequota
kubectl auth can-i create limitrange
```

## Mimari ve Çalışma Modeli

```text
Workload isteği ── API admission ── LimitRange ── ResourceQuota ── kabul / red
```

LimitRange tek container için varsayılanları ve sınırları belirler. ResourceQuota namespace içindeki toplam tüketimi denetler.

## Adım Adım Uygulama Rehberi

### 1. Namespace politikasını oluşturun

```bash
mkdir -p lab-k8s-14
cd lab-k8s-14

cat <<'EOF' > namespace-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: governed
---
apiVersion: v1
kind: LimitRange
metadata:
  name: container-defaults
  namespace: governed
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 100m
        memory: 64Mi
      default:
        cpu: 250m
        memory: 128Mi
      max:
        cpu: "1"
        memory: 512Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-budget
  namespace: governed
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "4"
    persistentvolumeclaims: "2"
EOF

kubectl apply -f namespace-policy.yaml
kubectl describe limitrange -n governed
kubectl describe resourcequota -n governed
```

### 2. Varsayılan değerleri gözlemleyin

```bash
cat <<'EOF' > accepted-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: accepted
  namespace: governed
spec:
  containers:
    - name: web
      image: nginx:1.27-alpine
EOF

kubectl apply -f accepted-pod.yaml
kubectl wait --for=condition=Ready pod/accepted -n governed --timeout=120s
kubectl get pod accepted -n governed \
  -o jsonpath='{.spec.containers[0].resources}'
echo
```

Çıktıda manifestte yazmadığınız `requests` ve `limits` değerleri görünmelidir.

### 3. LimitRange tarafından reddedilen Pod’u deneyin

```bash
cat <<'EOF' > rejected-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: rejected
  namespace: governed
spec:
  containers:
    - name: memory-heavy
      image: nginx:1.27-alpine
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 250m
          memory: 1Gi
EOF

kubectl apply -f rejected-pod.yaml
```

API sunucusu, `1Gi` container limitinin izin verilen `512Mi` üst sınırını aştığını belirterek isteği reddetmelidir.

### 4. Namespace toplam tüketimini inceleyin

```bash
kubectl get resourcequota team-budget -n governed
kubectl get resourcequota team-budget -n governed -o jsonpath='{.status.used}'
echo
kubectl get pods -n governed
```

## Doğal Doğrulama ve Beklenen Sonuç

```bash
kubectl get pod accepted -n governed -o jsonpath='{.spec.containers[0].resources.requests.cpu}' | grep -qx 100m
kubectl get pod accepted -n governed -o jsonpath='{.spec.containers[0].resources.limits.memory}' | grep -qx 128Mi
test "$(kubectl get pod rejected -n governed --ignore-not-found)" = ""
kubectl describe resourcequota team-budget -n governed
```

`accepted` Pod çalışmalı ve varsayılan değerlere sahip olmalı; `rejected` Pod oluşmamalı; quota çıktısı kullanılan kaynakları göstermelidir.
