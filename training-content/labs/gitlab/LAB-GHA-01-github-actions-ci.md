# LAB-GHA-01 — GitHub Actions ile Sürekli Entegrasyon (CI) ve Otomatik Test

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 45 dakika | `docker` | `Küme içi` |

[LAB-GHA-01.zip](/downloads/LAB-GHA-01.zip)


## Amaç

Bu labın amacı, modern bulut yerel projelerde yaygın olarak kullanılan **GitHub Actions** otomasyon platformunu kullanarak **Sürekli Entegrasyon (CI)** boru hatları tasarlamayı, **Matrix Builds** ile çoklu Python sürümlerinde test koşturmayı, kod linter denetimlerini (`flake8`) ve Docker imaj derleme adımlarını otomatize etmeyi öğrenmektir.

---

## Ön Koşullar

- Git ve Docker ortamı kurulu olmalıdır.
- Hızlı kontrol:
  ```bash
  git --version
  docker --version
  ```

---

## GitHub Actions CI İş Akışı Modeli

```text
[ Git Push / Pull Request ]
            |
            v
[ GitHub Actions Workflow: .github/workflows/ci.yml ]
     |
     ├── Job 1: test (Matrix: Python 3.11 & 3.12)
     │     ├── Step 1: actions/checkout@v4
     │     ├── Step 2: actions/setup-python@v5
     │     ├── Step 3: pip install flake8 pytest
     │     └── Step 4: pytest test_app.py
     │
     └── Job 2: build (needs: test)
           ├── Step 1: docker/setup-buildx-action@v3
           └── Step 2: docker build test
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-GHA-01
cd ~/labs/LAB-GHA-01
```

ZIP indirdiyseniz `unzip LAB-GHA-01.zip && cd LAB-GHA-01` komutunu çalıştırın.

---

### Adım 2: Test Edilecek Uygulama Kodunu Oluşturun

```bash
cat <<'EOF' > test_app.py
def add(x, y):
    return x + y

def test_add():
    assert add(2, 3) == 5
EOF
```

---

## Doğal Doğrulama ve Beklenen Sonuç

Workflow dosyasını gönderin ve son koşumu GitHub CLI ile inceleyin:

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push
gh run list --workflow ci.yml --limit 1
gh run view "$(gh run list --workflow ci.yml --limit 1 --json databaseId --jq '.[0].databaseId')" --log-failed
```

Son koşum `completed` ve `success` olmalı; lint, test ve image build işleri başarıyla bitmelidir. `--log-failed` başarılı koşumda hata günlüğü döndürmemelidir.

### Adım 3: GitHub Actions Workflow Dosyasını Oluşturun

`.github/workflows/ci.yml` dosyasını oluşturun:

```bash
mkdir -p .github/workflows

cat <<'EOF' > .github/workflows/ci.yml
name: Python Application CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install flake8 pytest

      - name: Lint with flake8
        run: |
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

      - name: Test with pytest
        run: |
          pytest

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: devops-app:latest
EOF
```

---
