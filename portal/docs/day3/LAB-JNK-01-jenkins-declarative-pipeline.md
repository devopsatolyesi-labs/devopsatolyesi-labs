# LAB-JNK-01 — Jenkins Declarative Pipeline: Git Checkout, Build & Test

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 45 dakika | `secure-ci` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-JNK-01.zip)](/downloads/LAB-JNK-01.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


## 1. Lab Senaryosu
Yazılım geliştirme süreçlerinde kod değişikliklerinin manuel olarak derlenmesi ve test edilmesi, insan hatalarına ve gecikmeli geri bildirim döngülerine yol açar. Sürekli Entegrasyon (CI) kültürünün temel prensibi, her commit işlemi sonrasında otomatik bir boru hattının tetiklenerek kodun taranması, derlenmesi ve birim testlerden geçirilmesidir. Bu çalışmada sektör standardı Jenkins otomasyon sunucusu üzerinde Pipeline as Code (`Jenkinsfile`) yaklaşımı uygulanır; kod çekme, linter denetimi, otomatik test ve JUnit test raporu arşivleme adımları kurgulanır.

## 2. Amaç
Jenkins üzerinde Deklaratif Pipeline (`Jenkinsfile`) sözdizimi ile çok aşamalı (`stages`, `steps`, `post`) bir CI hattı tanımlamak, Flake8 linter ve Pytest birim testlerini otomatize etmek ve JUnit XML test sonuçlarını arşivlemek.

## 3. Mimari / Akış
```text
  [ Git Repository (Jenkinsfile + App) ]
                     |
                     v (Webhook / SCM Trigger)
  [ Jenkins Controller v2.568 LTS ]
                     |
                     +---> Stage 1: Checkout SCM
                     +---> Stage 2: Linting (flake8)
                     +---> Stage 3: Unit Tests (pytest --junitxml)
                     +---> Stage 4: Artifact Packaging (*.tar.gz)
                     |
                     v
  [ Post Actions: JUnit Test Report Archiving & Build Status ]
```

## 4. Ön Koşullar
- Jenkins Controller çalışır durumda olmalıdır (`http://localhost:8080`)
- Merkezi referans platform için `https://devopsatolyesi.com/jenkins` adresini inceleyebilirsiniz
- Python 3 ve `python3-venv` paketi kurulu olmalıdır
Aşağıdaki komutlarla Python ve çalışma ortamını kontrol edin:
```bash
python3 --version
python3 -m venv --help >/dev/null
mkdir -p ~/labs/LAB-JNK-01/src ~/labs/LAB-JNK-01/tests
cd ~/labs/LAB-JNK-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Uygulama ve Birim Test Kodlarını Oluşturma
Hesaplama iş mantığını ve testlerini hazırlayın:
```bash
cat <<'EOF' > src/calculator.py
def add(a: float, b: float) -> float:
    return a + b

def subtract(a: float, b: float) -> float:
    return a - b

def multiply(a: float, b: float) -> float:
    return a * b

def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
EOF

cat <<'EOF' > tests/test_calculator.py
import pytest
from src.calculator import add, subtract, multiply, divide

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0

def test_subtract():
    assert subtract(10, 4) == 6

def test_multiply():
    assert multiply(3, 4) == 12

def test_divide():
    assert divide(10, 2) == 5

def test_divide_zero():
    with pytest.raises(ValueError):
        divide(5, 0)
EOF

cat <<'EOF' > requirements.txt
pytest==8.0.2
pytest-cov==4.1.0
flake8==7.0.0
EOF
```

### Adım 2 — `Jenkinsfile` Deklaratif Pipeline Dosyasını Yazma
Checkout, Linting, Test ve Paketleme adımlarını içeren `Jenkinsfile` dosyasını oluşturun:
```groovy
cat <<'EOF' > Jenkinsfile
pipeline {
    agent any

    environment {
        APP_NAME = "calculator-service"
        BUILD_ENV = "ci"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "--> [1] Kaynak kod repodan cekiliyor..."
                checkout scm
            }
        }

        stage('Linting') {
            steps {
                echo "--> [2] Flake8 ile kod kalitesi denetleniyor..."
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --no-cache-dir -r requirements.txt
                    flake8 src/ --max-line-length=100
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo "--> [3] Pytest calistiriliyor ve JUnit XML raporu uretiliyor..."
                sh '''
                    . .venv/bin/activate
                    mkdir -p reports
                    pytest --junitxml=reports/junit-report.xml --cov=src tests/
                '''
            }
        }

        stage('Build Packaging') {
            steps {
                echo "--> [4] Dagitim paketi olusturuluyor..."
                sh '''
                    tar -czf ${APP_NAME}-${BUILD_NUMBER}.tar.gz src/
                '''
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'reports/junit-report.xml'
            archiveArtifacts artifacts: '*.tar.gz', allowEmptyArchive: true
        }
        success {
            echo "CI PIPELINE BASARIYLA TAMAMLANDI."
        }
        failure {
            echo "CI PIPELINE BASARISIZ OLDU!"
        }
    }
}
EOF
```

### Adım 3 — Test Adımlarını Çalıştırma ve JUnit Raporunu Üretme
Boru hattındaki test komutlarını yerel ortamda koşturarak rapor dosyasını üretin:
```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -q -r requirements.txt
mkdir -p reports
pytest --junitxml=reports/junit-report.xml tests/
```

## 6. Beklenen Sonuç
Birim testlerin başarıyla geçtiğini gösteren Pytest terminal çıktısı:
```text
====== 5 passed in ...s ======
- Generated xml file: .../reports/junit-report.xml
```

Üretilen XML rapor içeriğinde 5 testin başarı durumu görülmelidir:
```bash
cat reports/junit-report.xml | grep -o 'tests="5"'
```

## 8. Sorun Giderme

### Belirti
Jenkins pipeline `Unit Tests` aşamasında durur ve `pytest: command not found` hatası verir.

### Kanıt
Jenkins Console Output loglarında sanal ortamın aktif edilmediği veya modülün bulunamadığı görülür.

### Kontrol Komutu
```bash
. .venv/bin/activate && which pytest
```

### Muhtemel Neden
Kabuk komutu çalıştırılırken `source .venv/bin/activate` adımı atlanmış veya bağımlılıklar kurulmamıştır.

### Çözüm
`Jenkinsfile` içindeki `sh` bloğunda her aşamanın sanal ortamı aktif ettiğinden emin olun:
```groovy
sh '''
    . .venv/bin/activate
    pytest --junitxml=reports/junit-report.xml tests/
'''
```

### Tekrar Doğrulama
Jenkins arayüzünde "Build Now" butonuna basarak veya terminalde test scriptini tekrar çalıştırarak teyit edin.

## 10. Production Notu
Üretim ortamlarında Jenkins işleri Controller (master) düğümü üzerinde çalıştırılmaz; Kubernetes pod agent'ları veya geçici (ephemeral) Docker konteynerleri üzerinde izole olarak koşturulur. Ayrıca sonsuz döngüye giren süreçlerin kaynak tüketmesini önlemek için `options { timeout(time: 15, unit: 'MINUTES') }` direktifi mutlaka eklenmelidir.

## 11. Challenge
`Jenkinsfile` içerisine `parallel` bloğu ekleyerek `Linting` ve `Unit Tests` aşamalarını eşzamanlı çalışacak şekilde yeniden yapılandırın.
