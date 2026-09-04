# Labs ve Keycloak Kubernetes işletim rehberi

Bu belge yalnız kalıcı eğitim portalı ile kimlik servisinin kurulumunu kapsar.
Jenkins, GitLab, Harbor, SonarQube ve gözlemlenebilirlik servisleri bu kapsamda
değiştirilmez.

## Hedef yapı

| Bileşen | Namespace | Adres | Kalıcılık |
| --- | --- | --- | --- |
| Labs portalı | `labs-system` | `labs.devopsatolyesi.com` | Stateless, içerik image içinde |
| Keycloak 26.7.3 | `identity-system` | `auth.devopsatolyesi.com` | PostgreSQL PVC |

Her iki servis de `training-runtime-01` üzerindeki `devops-cluster` Kind
cluster'ında Helm ile yönetilir. Ingress sınıfı `nginx` olarak sabitlenmiştir.

## Tekrarlanabilir kurulum

Uygulama kurulumu doğrudan Helm ile yapılır. Ansible bu iki uygulamanın deploy
yolunda kullanılmaz.

```bash
helm upgrade --install keycloak charts/keycloak \
  --namespace identity-system --create-namespace \
  --set-string postgres.password="$KEYCLOAK_DB_PASSWORD" \
  --set-string admin.password="$PLATFORM_ADMIN_PASSWORD" \
  --set-string users.admin.password="$LABS_ADMIN_PASSWORD" \
  --set-string users.devops.password="$LABS_DEVOPS_PASSWORD" \
  --set-string users.kubernetes.password="$LABS_KUBERNETES_PASSWORD" \
  --wait --timeout 10m

helm upgrade --install labs-portal charts/labs-portal \
  --namespace labs-system --create-namespace \
  --set-string image.repository=devops-atolyesi/labs-portal \
  --set-string image.tag="$LABS_IMAGE_TAG" \
  --wait --timeout 5m
```

Portal image'ı CI tarafından `linux/amd64` olarak build edilir. Kind ortamında
registry kullanılmıyorsa aynı image `kind load docker-image` ile yüklenir.

İlk Keycloak kurulumunda aşağıdaki değerler yalnız environment/CI Secret olarak
verilir; repoya yazılmaz:

- `PLATFORM_ADMIN_PASSWORD`
- `KEYCLOAK_DB_PASSWORD`
- `LABS_ADMIN_PASSWORD`
- `LABS_DEVOPS_PASSWORD`
- `LABS_KUBERNETES_PASSWORD`

Mevcut Keycloak release güncellenirken parolalar mevcut Secret değerlerinden
verilir; release geçmişi ve rollback Helm tarafından yönetilir.

## Kullanıcı ve eğitim erişimi yönetimi

Keycloak yönetim konsolu
`https://auth.devopsatolyesi.com/admin/devops-atolyesi/console/` adresindedir.
Yönetim hesabı portalda kullanılan `admin` hesabıdır; parolası
`LABS_ADMIN_PASSWORD` GitHub Actions secret'ıyla yönetilir. Bu hesaba yalnız
`devops-atolyesi` realm'ini yönetmesi için `realm-management/realm-admin` rolü
verilir. Portal yöneticisi üst menüdeki **Kullanıcı Yönetimi** bağlantısıyla bu
ekrana ulaşır. `master` realm yönetici parolası günlük kullanıcı yönetiminde
kullanılmaz.

Öğrenci hesabı `Users` bölümünde oluşturulur. Erişim, kullanıcıyı aşağıdaki
gruplardan birine ekleyerek verilir:

- `devops-practitioner-5-day`
- `docker-kubernetes-2-day`

Portalın **Çıkış** bağlantısı önce OAuth2 Proxy çerezini, ardından Keycloak SSO
oturumunu kapatır ve kullanıcıyı yeniden Labs girişine yönlendirir.

## Doğrulama

```bash
kubectl -n labs-system get deployment,service,ingress,pods
kubectl -n identity-system get deployment,statefulset,service,ingress,pods,pvc
helm list --all-namespaces
curl -H 'Host: labs.devopsatolyesi.com' http://127.0.0.1:8080/
curl -H 'Host: auth.devopsatolyesi.com' \
  http://127.0.0.1:8080/realms/devops-atolyesi/.well-known/openid-configuration
```

Başarılı durumda iki Labs pod'u, bir Keycloak pod'u ve bir PostgreSQL pod'u
`Running/Ready` görünür; iki HTTP kontrolü de `200` döner.

## İçerik güncelleme

Yeni veya düzeltilen lab içeriği `training-content/` altında tutulur. Playbook
yeniden çalıştırıldığında portal image'ı tekrar üretilir, Kind'a yüklenir ve
Labs Deployment Helm üzerinden güncellenir. Pod içine elle dosya kopyalanmaz.

## Yedekleme ve taşıma

Labs portalı stateless olduğu için repository ve image yeniden üretim için
yeterlidir. Keycloak verisi `data-keycloak-postgres-0` PVC'sindedir. Native
Kubernetes'e geçmeden önce PostgreSQL mantıksal yedeği alınır; yeni cluster'da
StorageClass ve TLS/Ingress değerleri ayarlanıp aynı Helm chartları kurulur,
ardından yedek geri yüklenir. PVC silme işlemi otomasyona dahil değildir.
