# Keycloak Kubernetes kurulumu

Bu chart, `identity-system` namespace'inde Keycloak 26.7.3 ve kalıcı
PostgreSQL StatefulSet'i kurar. Labs portalı ayrı namespace ve Ingress olarak
kalır; kimlik servisiyle uygulama servisi birbirine karıştırılmaz.

Parolalar chart'a yazılmaz. Örnek kurulum:

```bash
helm upgrade --install keycloak ./charts/keycloak \
  --set-string postgres.password="$KEYCLOAK_DB_PASSWORD" \
  --set-string admin.password="$PLATFORM_ADMIN_PASSWORD" \
  --set-string users.admin.password="$LABS_ADMIN_PASSWORD" \
  --set-string users.devops.password="$LABS_DEVOPS_PASSWORD" \
  --set-string users.kubernetes.password="$LABS_KUBERNETES_PASSWORD"
```

Native Kubernetes'e geçişte `storageClassName`, Ingress class/TLS ve Secret
kaynağı ortam değerleriyle değiştirilir; realm, roller ve istemci tanımları
aynı kalır. PostgreSQL PVC'si silinmeden cluster taşınmamalıdır.
