# LAB-GIT-01 — Git Workflow, Branching & Conflict Resolution

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-GIT-01.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-GIT-01.zip && cd LAB-GIT-01`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-GIT-01
cd ~/labs/LAB-GIT-01
```

### `starter/app-config.json`

```bash
mkdir -p "$(dirname -- starter/app-config.json)"
cat > starter/app-config.json <<'LAB_FILE_EOF_1'
{
  "appName": "payment-service",
  "version": "1.0.0",
  "port": 8080,
  "features": {
    "logging": "INFO",
    "auth": "BASIC"
  }
}
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
echo "Cleanup completed for LAB-GIT-01."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
echo "Resetting workspace for LAB-GIT-01..."
bash "$lab_dir/scripts/cleanup.sh"
cp -r "$lab_dir/starter"/. .
echo "Workspace reset to starter state for LAB-GIT-01."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-GIT-01: Git Config Resolution..."
if grep -q '"auth": "JWT_OAUTH2"' app-config.json && grep -q '"port": 9090' app-config.json; then
    echo "[PASS] LAB-GIT-01 Conflict resolved with required parameters."
    exit 0
else
    echo "[FAIL] LAB-GIT-01 app-config.json missing expected configuration."
    exit 1
fi
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## 1. Lab Senaryosu
Çok paydaşlı bir yazılım geliştirme ortamında birden fazla mühendis aynı mikroservis yapılandırması üzerinde paralel geliştirmeler yapmaktadır. Bir geliştirici kimlik doğrulama altyapısını JWT standardına taşırken, operasyon ekibi ana dalda port ve log seviyesi güncellemesi uygulamıştır. Bu iki dal birleştirilmek istendiğinde dosya düzeyinde çakışma (merge conflict) meydana gelir. Bu çalışmada Trunk-Based ve Feature-Branch yaklaşımları uygulanır; çakışan JSON yapılandırması çözümlenerek temiz bir commit geçmişi elde edilir.

## 2. Amaç
Git ortamında branch oluşturma, çakışan commitleri birleştirme (`git merge`), çakışma işaretlerini (`<<<<<<<`, `=======`, `>>>>>>>`) çözümleme ve geçerli bir birleştirme geçmişi oluşturmak.

## 3. Mimari / Akış
```text
  main:          [C1: Init] -------------> [C2: Port 9090] -------> [C4: Merge Commit]
                     \                                                     ^
                      \                                                    | (Conflict Resolved)
  feature/jwt-auth:    \-----> [C3: JWT Auth] -----------------------------/
```

## 4. Ön Koşullar
- Git CLI (v2.40+) kurulu olmalıdır
- `jq` komut satırı JSON ayrıştırıcısı kurulu olmalıdır
- Çalışma dizini: `~/labs/LAB-GIT-01`

Aşağıdaki komutlarla Git kullanıcı yapılandırmasını doğrulayın:
```bash
git --version
git config --global user.name "DevOps Engineer"
git config --global user.email "engineer@devops.local"
```

## 5. Adım Adım Uygulama

### Adım 1 — Çalışma Ortamı ve Git Reposu Oluşturma
Temiz bir Git deposu başlatın:
```bash
mkdir -p ~/labs/LAB-GIT-01/repo
cd ~/labs/LAB-GIT-01/repo
git init -b main
```

### Adım 2 — İlk Commit ve Temel Yapılandırma Dosyası
Başlangıç yapılandırma dosyasını oluşturun ve commit edin:
```bash
cat <<'EOF' > app-config.json
{
  "appName": "payment-service",
  "version": "1.0.0",
  "port": 8080,
  "features": {
    "logging": "INFO",
    "auth": "BASIC"
  }
}
EOF

git add app-config.json
git commit -m "feat: initial app config for payment service"
```

### Adım 3 — Feature Branch Açma ve Kimlik Doğrulama Değişikliği
Yeni bir branch oluşturup auth alanını güncelleyin:
```bash
git checkout -b feature/jwt-auth

cat <<'EOF' > app-config.json
{
  "appName": "payment-service",
  "version": "1.1.0-auth",
  "port": 8080,
  "features": {
    "logging": "DEBUG",
    "auth": "JWT_OAUTH2"
  }
}
EOF

git add app-config.json
git commit -m "feat(auth): upgrade auth mechanism to JWT_OAUTH2"
```

### Adım 4 — Ana Dala (Main) Dönüp Çakışan Değişiklik Uygulama
Ana dala dönün ve port yapılandırmasını güncelleyin:
```bash
git checkout main

cat <<'EOF' > app-config.json
{
  "appName": "payment-service",
  "version": "1.0.1",
  "port": 9090,
  "features": {
    "logging": "WARN",
    "auth": "BASIC"
  }
}
EOF

git add app-config.json
git commit -m "fix(port): change default port to 9090 and logging to WARN"
```

### Adım 5 — Çakışmayı Tetikleme
Geliştirme dalını ana dal ile birleştirmeyi deneyin:
```bash
git merge feature/jwt-auth || true
```

### Adım 6 — Çakışmayı Çözümleme
Dosyadaki çakışma bloklarını temizleyerek her iki tarafın geçerli parametrelerini birleştiren nihai yapılandırmayı kaydedin:

```bash
cat <<'EOF' > app-config.json
{
  "appName": "payment-service",
  "version": "1.2.0",
  "port": 9090,
  "features": {
    "logging": "INFO",
    "auth": "JWT_OAUTH2"
  }
}
EOF
```

### Adım 7 — Çözümü Doğrulama ve Commit Etme
```bash
# JSON sözdizimini doğrula
jq . app-config.json

# Çözümü commit et
git add app-config.json
git commit -m "merge: resolve conflict between main (port 9090) and jwt-auth"
```

## 6. Beklenen Sonuç
Adım 5'te beklenen Git çakışma uyarısı:
```text
Auto-merging app-config.json
CONFLICT (content): Merge conflict in app-config.json
Automatic merge failed; fix conflicts and then commit the result.
```

Çakışma çözüldükten sonra commit geçmişi (`git log --oneline --graph`):
```text
*   ... (HEAD -> main) merge: resolve conflict between main (port 9090) and jwt-auth
|\  
| * ... (feature/jwt-auth) feat(auth): upgrade auth mechanism to JWT_OAUTH2
* | ... fix(port): change default port to 9090 and logging to WARN
|/  
* ... feat: initial app config for payment service
```

## 7. Doğrulama
Yapılandırma dosyasının geçerli bir JSON olduğunu ve her iki değişikliğin birleştiğini doğrulayın:
```bash
cd ~/labs/LAB-GIT-01/repo
PORT=$(jq -r .port app-config.json)
AUTH=$(jq -r .features.auth app-config.json)

if [ "$PORT" = "9090" ] && [ "$AUTH" = "JWT_OAUTH2" ]; then
    echo "VALIDATION SUCCESS: Merge conflict resolved. Port=9090, Auth=JWT_OAUTH2."
else
    echo "VALIDATION FAILED: Unexpected values in app-config.json" && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
Çalışma esnasında `fatal: You are in 'detached HEAD' state` uyarısı alınır.

### Kanıt
`git status` çıktısında `HEAD detached at ...` ifadesi görülür.

### Kontrol Komutu
```bash
git branch
```

### Muhtemel Neden
Branch adı yerine doğrudan bir commit hash'i kontrol edilmiştir (`git checkout <commit-hash>`).

### Çözüm
Değişiklikleri kaybetmeden ana dala geri dönün veya yeni bir branch açın:
```bash
git checkout main
```

### Tekrar Doğrulama
```bash
git branch --show-current
# Çıktı "main" olmalıdır.
```

## 9. Temizlik / Sıfırlama
Laboratuvar ortamını temizlemek ve sıfırlamak için:
```bash
rm -rf ~/labs/LAB-GIT-01
```

## 10. Production Notu
Üretim ortamlarında `main` veya `release` dallarına doğrudan `git push` engellenmeli (Protected Branch), tüm değişiklikler zorunlu Code Review (Pull Request) ve otomatik CI testlerinin (Merge Request Pipeline) ardından merge edilmelidir.

## 11. Challenge
Son 2 commit'i tek bir temiz commit haline getiren `git rebase -i HEAD~2` (Interactive Rebase Squash) işlemini uygulayın ve commit geçmişini sadeleştirin.
