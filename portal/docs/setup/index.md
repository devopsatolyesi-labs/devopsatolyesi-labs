# Lab Ortamı Hazırlığı

Bu bölüm yalnız katıldığınız eğitim için gereken araçları ve lab dosyası kullanımını gösterir.

## Lab Paketini Kullanma

1. Lab sayfasındaki **Bu labın başlangıç dosyalarını indir (ZIP)** bağlantısına tıklayın.
2. ZIP dosyasını Cockpit **Files > Upload** ile öğrenci sunucusuna yükleyin.
3. Cockpit terminalinde aşağıdaki komutları çalıştırın:

```bash
mkdir -p ~/labs
mv ~/LAB-*.zip ~/labs/ 2>/dev/null || true
cd ~/labs
unzip LAB-ID.zip
cd LAB-ID
find . -maxdepth 3 -type f -print
sed -n '1,220p' README.md
```

`LAB-ID` değerini seçtiğiniz labın kimliğiyle değiştirin. Örnek: `LAB-DOC-03`.

ZIP paketi şunları içerir:

- `README.md`: uygulanacak adımlar,
- `starter/`: öğrencinin tamamlayacağı başlangıç dosyaları,
- `scripts/`: doğrulama, sıfırlama ve temizlik komutları,
- `images/`: lab diyagramları.

Çözüm dosyaları öğrenci ZIP paketine eklenmez. Script içeriği, çalıştırmadan önce inceleyebilmeniz için lab sayfasında da gösterilir.

## Ortak Ön Kontrol

```bash
uname -a
df -h /
free -h
git --version
curl --version | head -1
unzip -v | head -1
```

Eksik araç veya yetki varsa lab başlamadan eğitmene bildirin.
