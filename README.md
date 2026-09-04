# DevOps Atölyesi Labs

Kalıcı Labs portalı ve Keycloak kimlik servisinin bağımsız private projesidir.
Jenkins, GitLab, Harbor, SonarQube ve diğer geçici eğitim servisleri bu repoda
bulunmaz.

## Bileşenler

- `portal/`: MkDocs tabanlı Labs portalı
- `training-content/`: iki eğitim paketinin kanonik lab içeriği
- `charts/labs-portal/`: Labs Kubernetes Helm chartı
- `charts/keycloak/`: Keycloak 26.7.3 ve PostgreSQL Helm chartı
- `gitops/applications.yaml`: Argo CD otomatik senkronizasyon tanımları
- `scripts/bootstrap-argocd.sh`: GitHub ve Harbor secretlarını güvenli biçimde uygular
- `docs/KUBERNETES_LABS_KEYCLOAK.md`: kurulum, doğrulama ve taşıma rehberi

## Adresler

- Labs: <https://labs.devopsatolyesi.com>
- Kimlik servisi: <https://auth.devopsatolyesi.com>

GitHub Actions imajı ve sürümlü Helm paketlerini private Harbor OCI registry'ye
yollar. Argo CD yalnız pull yetkisiyle Harbor'ı izleyerek chartları otomatik
uygular. Kubernetes API internete açılmaz. Parolalar repoya yazılmaz;
GitHub Actions repository secrets ve Kubernetes Secret nesnelerinde tutulur.
