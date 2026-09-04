# Çoklu Kubeconfig Dosyalarını Birleştirme ve Yönetme

> Kaynak: [Merging Multiple Kubeconfig Files into a Single File — Hakan Bayraktar](https://hbayraktar.medium.com/merging-multiple-kubeconfig-files-into-a-single-file-50c266c2d152)

Farklı Kubernetes kümeleri (GKE, EKS, AKS, On-Prem Kubeadm, kind) yönetirken her kümenin ayrı bir kubeconfig dosyası oluşturulur. Bu rehber, birden fazla config dosyasını tek bir standart `~/.kube/config` dosyasında güvenle birleştirmeyi ve `kubectx` ile kümeler arası hızlı geçiş yapmayı adım adım gösterir.

---

## 1. Senaryo

Elinizde 3 farklı kümenin config dosyası olduğunu varsayalım:
- `~/.kube/config` (Mevcut yerel kind kümesi)
- `~/cluster-prod.conf` (Production EKS / Kubeadm kümesi)
- `~/cluster-dev.conf` (GCP GKE geliştirme kümesi)

---

## 2. Kubeconfig Dosyalarını Birleştirme Adımları

### Adım 1: Mevcut Config Dosyanızı Yedekleyin

```bash
mkdir -p ~/.kube/backups
cp ~/.kube/config ~/.kube/backups/config.backup.$(date +%Y%m%d%H%M%S) 2>/dev/null || true
```

### Adım 2: KUBECONFIG Ortam Değişkeni ile Dosyaları Tanımlayın

```bash
# İki nokta üst üste (:) ile birleştirilecek dosyaları tanımlayın
export KUBECONFIG=~/.kube/config:~/cluster-prod.conf:~/cluster-dev.conf
```

### Adım 3: kubectl ile Birleştirilmiş Config Dosyası Üretin

```bash
kubectl config view --flatten > ~/.kube/config-merged.yaml

# Birleştirilmiş dosyayı ana config haline getirin
mv ~/.kube/config-merged.yaml ~/.kube/config
chmod 600 ~/.kube/config
```

---

## 3. Context ve Küme Yönetimi

Birleştirilen konfigürasyon içerisindeki context leri listeleyin ve aralarında geçiş yapın:

```bash
# Mevcut context listesi
kubectl config get-contexts

# Aktif contexti değiştirme
kubectl config use-context prod-cluster

# Context ismini yeniden adlandırma (daha sade hale getirme)
kubectl config rename-context arn:aws:eks:eu-west-1:123456789:cluster/prod-cluster aws-prod
```

---

## 4. Hızlı Context & Namespace Geçiş Araçları (kubectx & kubens)

Kümeler ve Namespace ler arasında tek komutla geçiş yapmak için:

```bash
# kubectx ve kubens kurulumu
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens

# Kullanım:
kubectx              # Tüm kümeleri listeler
kubectx devops-cluster # Seçilen kümeye geçer
kubens monitoring    # Default namespacei monitoring yapar
```
