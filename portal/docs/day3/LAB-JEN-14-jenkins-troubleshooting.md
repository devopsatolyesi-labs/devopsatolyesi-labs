# LAB-JEN-14 — Jenkins Troubleshooting ve Sorun Giderme Senaryoları

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 50 dakika | `jenkins` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-JEN-14.zip)](/downloads/LAB-JEN-14.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 50 dakika | `jenkins`, `troubleshooting`, `bash` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-JEN-14.zip)](/downloads/LAB-JEN-14.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

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

## Sorun Giderme Karar Ağacı

```mermaid
graph TD
    Fail[Pipeline Build FAILED] --> CheckLog[Konsol Loglarını Oku]
    CheckLog --> Case1{permission denied: docker.sock?}
    Case1 -->|Evet| Fix1[Kullanıcı ID / Socket İzinlerini Düzelt]
    Case1 -->|Hayır| Case2{WorkflowScript syntax error?}
    Case2 -->|Evet| Fix2[Jenkinsfile DSL Sözdizimini Düzelt]
    Case2 -->|Hayır| Case3{No space left on device?}
    Case3 -->|Evet| Fix3[cleanWs() ve logRotator Ekle]
    Case3 -->|Hayır| Case4{Could not find credentials?}
    Case4 -->|Evet| Fix4[Credential ID ve Scope Doğrula]
```

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

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Jenkins Controller'da disk dolduğunda Jenkins UI neden aniden kilitlenir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Jenkins tüm build durumlarını, logları ve XML yapılandırma dosyalarını diske senkron olarak yazar. Disk tamamen dolduğunda JVM dosya yazamaz ve thread'ler kilitlenir. Bu nedenle her controller'da `buildDiscarder` ve periyodik disk alanı izleme (Disk Allocation Alert) zorunludur.

??? question "Soru 2: `cleanWs()` adımı build failure olduğunda da çalıştırılmalı mıdır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Debug yapılması gerekiyorsa failure durumunda workspace silinmeyebilir (`cleanWhenFailure: false`). Ancak üretim ortamlarında büyük dosyalar diski doldurabileceğinden veya hassas dosyalar diskte kalabileceğinden dikkatli yönetilmelidir.

---

## Beklenen Sonuç & Sorun Giderme

| Problem | Teşhis | Çözüm |
| :--- | :--- | :--- |
| `No space left on device` | Disk alanı tükenmiş | `docker system prune` ve Jenkins `cleanWs()` uygulayın. |
| `WorkflowScript: ... unexpected token` | Groovy parantez hatası | Parantezleri ve blok yapılarını eşleyin. |
