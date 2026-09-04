# Eğitim İçeriği Erişim Modeli

`training-content/catalog.json`, lab envanteri, eğitim üyeliği ve paket üretimi için tek kaynaktır. Portalın menüsü ve indirilebilir ZIP dosyaları bu katalogdan üretilmelidir; `portal/docs` altında bağımsız bir ikinci katalog tutulmamalıdır.

## Yetkilendirme

- `admin`: bütün eğitimleri, taslakları ve çözüm dosyalarını görür.
- `instructor`: yalnız atandığı eğitimleri görür; çözüm paketini indirebilir.
- `student`: yalnız kayıtlı olduğu eğitimleri görür; çözüm dosyalarını indiremez.

Başlangıç hesapları `admin`, `devops`, `kubernetes` ve `docker` olarak tanımlıdır. Parola veya parola özeti kataloğa yazılmaz. Keycloak kullanıcı kimliğini ve genel rolü doğrular. Portal veritabanı eğitim paketlerini, bu paketlerdeki labları ve kullanıcı üyeliklerini tutar.

Admin paneli şu işlemleri tek yerden yapacaktır:

1. Keycloak üzerinde kullanıcı oluşturma veya devre dışı bırakma.
2. Katalogdaki lablardan yeni eğitim paketi oluşturma.
3. Pakete lab ekleme, çıkarma ve sıralama.
4. Kullanıcıyı pakete üye etme veya üyelikten çıkarma.
5. Öğrenci ya da eğitmen ZIP paketini üretme.

Veri modeli `portal/backend/schema.sql` içindedir. Labın teknik kaynağı Git'teki katalog olarak kalır; admin paneli lab içeriğini kopyalamaz, yalnız seçer ve sıralar.

## Paket Kuralı

Öğrenci paketi her lab için rehberi `README.md` adıyla, `starter/` ve `scripts/` içeriğini taşır. `solution/` yalnız instructor paketindedir.

```bash
python3 scripts/validate-content-catalog.py
python3 scripts/package-course-labs.py --course docker-kubernetes-2-day
python3 scripts/package-course-labs.py --course devops-practitioner-5-day
```

Üretilen dosyalar `dist/lab-packages/` altındadır ve kaynak kontrolüne eklenmez.
