# DevOps Atölyesi Labs

Kalıcı Labs portalı ve Keycloak kimlik servisinin bağımsız private projesidir.
Jenkins, GitLab, Harbor, SonarQube ve diğer geçici eğitim servisleri bu repoda
bulunmaz.

## Bileşenler

- `portal/`: MkDocs tabanlı Labs portalı
- `training-content/`: iki eğitim paketinin kanonik lab içeriği
- `charts/labs-portal/`: Labs Kubernetes Helm chartı
- `charts/keycloak/`: Keycloak 26.7.3 ve PostgreSQL Helm chartı
- `docs/KUBERNETES_LABS_KEYCLOAK.md`: kurulum, doğrulama ve taşıma rehberi

## Adresler

- Labs: <https://labs.devopsatolyesi.com>
- Kimlik servisi: <https://auth.devopsatolyesi.com>

Deploy işlemleri yalnız `.github/workflows/deploy.yml` üzerinden yapılır.
Parolalar repoya yazılmaz; GitHub Actions repository secrets içinde tutulur.
