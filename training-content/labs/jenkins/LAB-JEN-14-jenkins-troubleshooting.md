# LAB-JEN-14 — Jenkins Troubleshooting ve Sorun Giderme Senaryoları

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| İleri | 50 dakika | `jenkins` | `8080` |

[LAB-JEN-14.zip](/downloads/LAB-JEN-14.zip)


---

## Amaç

Bu laboratuvar bir **War Room / Diagnostic Challenge** formatındadır. Gerçek üretim ortamlarında en sık karşılaşılan 4 kritik Jenkins pipeline hatası simüle edilecek, kök neden analizi (RCA) yapılarak her biri kalıcı olarak onarılacaktır:

- **Hata 1: Permission Denied on Docker Socket:** Jenkins agent'ının `/var/run/docker.sock` erişim yetkisini kaybetmesi.
- **Hata 2: Groovy Syntax & Invalid Pipeline DSL:** Declarative pipeline sözdizimi hatalarının çözümlenmesi.
- **Hata 3: Out of Disk Space & Stale Workspaces:** Disk dolması sonucu build'lerin çökmesi ve `cleanWs()` otomasyonu.
- **Hata 4: Credential Binding & Secret Scope Mismatch:** Hatalı credential ID veya yetkisiz klasör scope'u sorunlarının onarımı.

---

## Ön Koşullar

- LAB-JEN-01 ila LAB-JEN-13 arasındaki tüm kavramlara hakim olunmalıdır.

---

## Adım Adım Uygulama Rehberi

### Senaryo 1: Bozuk Pipeline Sözdizimini (DSL) Onarma

Aşağıdaki hatalı pipeline kodunu inceleyin:

```groovy
// HATALI KOD
pipeline {
    agent any
    stages {
        stage('Build')
            steps {
                echo 'Derleniyor'
            }
    }
}
```

**Kök Neden:** `stage('Build')` ifadesinden sonra açılış süslü parantezi (`{`) unutulmuştur.
**Onarım:**
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Derleniyor'
            }
        }
    }
}
```

---

### Senaryo 2: Çalışma Alanı Disk Temizliği (`cleanWs`)

Sık build alan projelerde disk dolmasını önlemek için Declarative Pipeline'a `cleanWs()` post-step'i ekleyin:

```groovy
pipeline {
    agent any

    options {
        // Son 5 build'i sakla, eski log ve dosyaları sil
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
    }

    stages {
        stage('Generate Heavy Artifacts') {
            steps {
                sh 'mkdir -p temp_data && dd if=/dev/zero of=temp_data/blob.dat bs=1M count=10'
            }
        }
    }

    post {
        always {
            // Her build sonrasında çalışma alanını tamamen temizle
            cleanWs(cleanWhenAborted: true, cleanWhenFailure: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true)
        }
    }
}
```

---

### Senaryo 3: Credential Maskeleme ve ID Uyuşmazlığı

Eğer konsolda `Could not find credentials entry with ID 'gitlab-token'` hatası alınıyorsa:
1. Jenkins UI -> **Credentials** bölümüne gidin.
2. ID'nin büyük/küçük harf duyarlılığına dikkat edin (`GitLab-Token` vs `gitlab-token`).
3. Pipeline kodundaki ID ile Credential Store'daki ID'yi birebir eşitleyin.

---

## Doğal Doğrulama

1. Jenkins Log Viewer üzerinden sistem loglarını inceleyin:
   ```bash
   curl -s -u admin:${JENKINS_TOKEN} http://localhost:8080/log/all | head -n 30
   ```
2. Onarılan pipeline'ı çalıştırıp `SUCCESS` aldığını teyit edin.

---

## Doğal Doğrulama ve Beklenen Sonuç

| Problem | Teşhis | Çözüm |
| :--- | :--- | :--- |
| `No space left on device` | Disk alanı tükenmiş | `docker system prune` ve Jenkins `cleanWs()` uygulayın. |
| `WorkflowScript: ... unexpected token` | Groovy parantez hatası | Parantezleri ve blok yapılarını eşleyin. |
