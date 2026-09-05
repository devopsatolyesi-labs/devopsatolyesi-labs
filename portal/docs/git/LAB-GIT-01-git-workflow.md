# LAB-GIT-01 — Git Workflow, Branching & Conflict Resolution

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 45 dakika | `docker` | `Küme içi` |

[LAB-GIT-01.zip](/downloads/LAB-GIT-01.zip)


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

## Doğal Doğrulama ve Beklenen Sonuç
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

## Doğal Doğrulama ve Beklenen Sonuç
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
