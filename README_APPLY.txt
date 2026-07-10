HEXA MVP PATCH 01 — TEMA + ROUTER + ALT NAVİGASYON

1) Projeyi yedekle:
   git checkout -b mvp-release
   git add .
   git commit -m "Backup before MVP patch 01"

2) Bu paketteki dosyaları aynı yolların üzerine kopyala:
   lib/main.dart
   lib/core/theme/hexa_theme.dart
   lib/core/router/hexa_router.dart
   lib/features/navigation/main_scaffold.dart

3) Proje kökünde çalıştır:
   dart format lib/main.dart lib/core/theme/hexa_theme.dart lib/core/router/hexa_router.dart lib/features/navigation/main_scaffold.dart
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   flutter run

4) Gönderilecek sonuç:
   - flutter analyze tam çıktısı
   - flutter test tam çıktısı
   - Uygulama açıldıysa Ana Sayfa ekran görüntüsü
   - Hata varsa hata metni ve kırmızı ekran görüntüsü

Not: Bu paket GitHub master sürümündeki mevcut dosya yapısına göre hazırlanmıştır.
