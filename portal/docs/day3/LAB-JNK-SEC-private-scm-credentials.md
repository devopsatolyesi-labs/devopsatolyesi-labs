# LAB-JNK-SEC — Jenkins Güvenlik ve Özel Depo Kimlik Doğrulama (Kasıtlı Hata Çözümü)

## Metadata
- **Seviye:** INTERMEDIATE / TROUBLESHOOTING
- **Önerilen Gün:** Gün 3
- **Tahmini Süre:** 30 dk
- **İlişkili Jenkins Klasörü:** `Labs/07-Security/01-private-scm-credentials-MANUAL`
- **Jenkins URL:** [https://jenkins.devopsatolyesi.com](https://jenkins.devopsatolyesi.com)
- **Lab Tipi:** Intentional Manual Failure & Recovery (Kasıtlı Hata ve Çözüm Simülasyonu)

---

## 1. Labın Amacı ve Kasıtlı Hata İlkesi

> [!IMPORTANT]
> Bu laboratuvar **kasıtlı olarak ilk çalıştırmada başarısız olacak şekilde** tasarlanmıştır. Gerçek dünya operasyonlarında en sık karşılaşılan hatalardan biri, CI/CD sunucusunun özel (private) bir Git deposuna erişim için yetkilendirilmemiş olmasıdır (`HTTP 401/403` veya `Authentication failed`).

Öğrencinin bu laboratuvardaki görevi:
1. Hatayı analiz etmek.
2. Jenkins Credential Provider üzerinde güvenli bir kimlik bilgisi (credential) tanımlamak.
3. Pipeline konfigürasyonunu güncelleyerek bu kimlik bilgisini bağlamak ve hatayı gidermektir.

---

## 2. Adım Adım Simülasyon ve Çözüm

### Adım 1 — Kasıtlı Hatayı Gözlemleme
1. [https://jenkins.devopsatolyesi.com](https://jenkins.devopsatolyesi.com) adresine gidin.
2. **Labs** -> **07-Security** -> **01-private-scm-credentials-MANUAL** işini açın.
3. **Build Now** butonuna basın.
4. Konsol çıktısını inceleyin:
```text
Cloning the remote Git repository
Cloning repository https://github.com/devopsatolyesi-labs/jenkins-lab-private-app.git
ERROR: Error cloning remote repo 'origin'
hudson.plugins.git.GitException: Command "git fetch --tags --force --progress -- https://github.com/devopsatolyesi-labs/jenkins-lab-private-app.git" returned status code 128:
stdout: 
stderr: fatal: could not read Username for 'https://github.com': No such device or address
Finished: FAILURE
```
Hatanın nedeni açıktır: `jenkins-lab-private-app` deposu özeldir ve anonim erişime kapalıdır.

---

### Adım 2 — Jenkins Üzerinde Kimlik Bilgisi (Credential) Oluşturma
1. Jenkins sol ana menüsünden **Manage Jenkins** (Jenkins'i Yönet) seçeneğine tıklayın.
2. **Security** başlığı altındaki **Credentials** seçeneğine girin.
3. **System** -> **Global credentials (unrestricted)** bağlantısına tıklayın.
4. Sol menüden **+ Add Credentials** butonuna basın:
   - **Kind:** `Username with password` (veya `Secret text`)
   - **Scope:** `Global (Jenkins, nodes, items, all child items, etc)`
   - **Username:** Sizin GitHub / GitLab kullanıcı adınız veya token adınız.
   - **Password:** Oluşturduğunuz GitHub Personal Access Token (PAT) veya GitLab Access Token.
   - **ID:** `training-github-token` *(Bu ID önemlidir, pipeline bunu arayacaktır)*
   - **Description:** `Training Private Repo Access Token`
5. **Create** butonuna basarak kaydedin.

---

### Adım 3 — Job Konfigürasyonunu Güncelleme ve Doğrulama
1. Tekrar **Labs** -> **07-Security** -> **01-private-scm-credentials-MANUAL** işine dönün.
2. Sol menüden **Configure** seçeneğine tıklayın.
3. **Pipeline** sekmesine inin. **Credentials** açılır kutusundan az önce eklediğiniz `training-github-token` kimliğini seçin.
4. **Save** butonuna basın.
5. Tekrar **Build Now** butonuna basın.
6. Konsol çıktısında checkout adımının başarıyla tamamlandığını ve testlerin çalıştığını doğrulayın:
```text
 > git fetch --tags --force --progress -- https://github.com/devopsatolyesi-labs/jenkins-lab-private-app.git +refs/heads/*:refs/remotes/origin/*
Checking out Revision ... (refs/remotes/origin/main)
...
[Pipeline] echo
Private application build and test succeeded!
Finished: SUCCESS
```

---

## 3. Güvenlik En İyi Uygulamaları (Best Practices)

1. **Asla Kod İçinde Saklamayın:** Token veya şifreleri asla `Jenkinsfile` içine açık metin (plain text) olarak yazmayın.
2. **En Az Yetki İlkesi (Least Privilege):** Jenkins'e tanımlanan token'lar yalnızca ilgili deponun `read` (okuma) yetkisine sahip olmalıdır; yönetici veya tam hesap yetkisi verilmemelidir.
3. **Audit ve Rotasyon:** Kullanılmayan veya süresi dolan credential'lar düzenli olarak silinmeli veya yenilenmelidir.
