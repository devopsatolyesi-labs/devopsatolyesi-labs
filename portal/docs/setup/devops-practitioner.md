# DevOps Practitioner Lab Hazırlığı

Bu kontrol yalnız **DevOps Practitioner** eğitimine aittir.

## Sunucuda Bulunması Gereken Araçlar

- [Git, curl, jq ve unzip](./index.md)
- [Python 3, `python3-venv` ve pip](./index.md)
- [Docker Engine ve Docker Compose v2](./docker-engine.md)
- [Java 21, Jenkins ve GitLab Runner](./jenkins-installation.md)
- [Terraform](../terraform/LAB-TF-01-terraform-docker-provider.md)
- [kind, kubectl ve Helm](./kind-cluster.md)
- Harbor erişimi
- Argo CD CLI
- Prometheus, Grafana ve ELK lablarını çalıştırabilecek en az 8 GB RAM

## Ön Kontrol

```bash
set -u
git --version
curl --version | head -1
jq --version
unzip -v | head -1
python3 --version
python3 -m venv --help >/dev/null
python3 -m pip --version
docker version --format 'Docker Server: {{.Server.Version}}'
docker compose version
java -version
terraform version | head -1
kind version
kubectl version --client
helm version --short
free -h
df -h /
```

Eğitim sayfasındaki tek ZIP paketi bütün başlangıç dosyalarını içerir. Başka bir labın dizininden dosya kopyalamayın.
