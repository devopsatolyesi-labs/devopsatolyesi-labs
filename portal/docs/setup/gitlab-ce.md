# Yerel GitLab Community Edition (CE) ve Runner Kurulumu

Bu rehber, eğitim ortamında yerel Git deposu, dahili container registry ve CI/CD pipeline süreçlerini yürütmek için **GitLab Community Edition (CE)** ve **GitLab Runner** bileşenlerinin Docker Compose ile kurulumunu açıklar.

---

## 1. Ön Koşullar ve Sistem Gereksinimleri

- Docker Engine 24.0+ ve Docker Compose v2 kurulu olmalıdır.
- En az **4 GB RAM** (önerilen 8 GB) ve 2 CPU çekirdeği ayrılmalıdır.
- Portlar: `8085` (HTTP web arayüzü), `2222` (SSH Git clone).

---

## 2. Docker Compose ile GitLab CE Kurulumu

Çalışma dizinini oluşturun:

```bash
mkdir -p ~/gitlab && cd ~/gitlab
```

`docker-compose.yml` dosyasını hazırlayın:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab-ce
    restart: always
    hostname: 'gitlab.devopsatolyesi.local'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8085'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        # Lab ortamı için bellek optimizasyonu
        puma['worker_processes'] = 2
        puma['min_threads'] = 1
        puma['max_threads'] = 4
        sidekiq['concurrency'] = 5
        postgresql['shared_buffers'] = "256MB"
        prometheus_monitoring['enable'] = false
    ports:
      - '8085:80'
      - '2222:22'
    volumes:
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
    networks:
      - gitlab-net

  runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    depends_on:
      - gitlab
    volumes:
      - './runner-config:/etc/gitlab-runner'
      - '/var/run/docker.sock:/var/run/docker.sock'
    networks:
      - gitlab-net

networks:
  gitlab-net:
    name: gitlab-net
```

Konteynerleri başlatın:

```bash
docker compose up -d
```

**Not:** GitLab ilk başlatmada veritabanı tablolarını ve servisleri ayağa kaldırırken 2-3 dakika sürebilir. Durumu `docker compose logs -f gitlab` ile izleyebilirsiniz.

---

## 3. İlk Admin (root) Parolasını Alma

Konteyner sağlıklı duruma geldikten sonra ilk parola dosyasından şifrenizi alın:

```bash
docker exec -it gitlab-ce grep 'Password:' /etc/gitlab/initial_root_password
```

Tarayıcınızdan `http://localhost:8085` adresine gidin. Kullanıcı adı `root` ve yukarıdaki geçici parola ile giriş yapın.

---

## 4. GitLab Runner Kaydı (Registration)

1. GitLab Web UI üzerinde: **Admin Area → CI/CD → Runners** bölümüne gidin (veya projenizin **Settings → CI/CD → Runners** sekmesini açın).
2. **New project runner** butonuna tıklayarak etiketleri belirleyin (`docker`, `linux`) ve oluşturulan **Registration Token** değerini kopyalayın.
3. Terminalde Runner'ı kaydedin:

```bash
docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab:80" \
  --registration-token "BURAYA_TOKEN_GELIR" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "local-docker-runner" \
  --tag-list "docker,linux" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
```

Artık yerel GitLab ve GitLab Runner hazır!
