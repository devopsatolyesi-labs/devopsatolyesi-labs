# Docker ve Kubernetes Lab Hazırlığı

Bu kontrol yalnız **Docker and Kubernetes — 2 Gün** eğitimine aittir.

## Sunucuda Bulunması Gereken Araçlar

- Git, curl, jq ve unzip
- Docker Engine ve Docker Compose v2
- kind
- kubectl
- En az 4 CPU, 8 GB RAM ve 30 GB boş disk

## Ön Kontrol

```bash
set -u
git --version
curl --version | head -1
jq --version
unzip -v | head -1
docker version --format 'Docker Server: {{.Server.Version}}'
docker compose version
kind version
kubectl version --client
free -h
df -h /
```

Her lab kendi ZIP paketini ve gereken komutları içerir. Başka bir labın dizininden dosya kopyalamayın.
