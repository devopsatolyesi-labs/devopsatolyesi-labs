# Lab İçerik Standardı

Lab metni sade ve uygulanabilir olmalıdır. Uzun kurgu ve tekrar kullanılmaz.

Her lab şu sırayı izler:

1. **Amaç:** En fazla üç kısa madde.
2. **Ön koşullar:** Gereken araçlar, profil, port ve önceki lablar.
3. **Adımlar:** Tek işlem yapan, numaralı ve kopyalanabilir komutlar.
4. **İpucu:** Yalnız öğrencinin takılma ihtimali yüksek noktada; cevabı doğrudan vermeden.
5. **Beklenen sonuç:** Görülmesi gereken somut çıktı.
6. **Doğrulama:** `scripts/validate.sh` ile gerçek davranış testi.
7. **Temizlik:** Yalnız laba ait kaynakları kaldıran `scripts/cleanup.sh`.

Bir kavramı anlamak için gerekli olmayan tarihçe, pazarlama dili ve uzun senaryo kaldırılır. Hata mesajları öğrenciye neyi kontrol edeceğini açıkça söyler.
