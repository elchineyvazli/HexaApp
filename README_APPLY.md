# Hexa Feed Engine V1

Bu paket yalnızca `lib/features/feed/` içindeki Feed Engine katmanını değiştirir.
`pubspec.yaml` değişikliği gerektirmez.

## Uygulama

Paket içindeki `lib/` klasörünü proje kökündeki `lib/` klasörünün üzerine kopyala.
Mevcut dosyaların yedeğini veya git commit'ini önceden al.

## Davranış

- Video açıldığında üretici, açıklama, Signal, yorum, kaydetme, paylaşma ve arama arayüzü görünmez.
- Tek dokunma videoyu oynatır/durdurur; ekranda play/pause ikonu çıkmaz.
- Çift dokunma Signal gönderir. Daha önce Signal verilmişse kaldırmaz; sadece sayıyı gösterir.
- Signal sayısı yalnızca çift dokunma sonrası kısa süre görünür.
- Uzun basma videoyu durdurur ve interaction capsule'ı açar.
- Capsule üreticiyi, Signal sayısını, yorumları, kaydetmeyi ve paylaşmayı gösterir.
- Capsule dışına dokunmak capsule'ı kapatır ve video önceden oynuyorsa devam ettirir.
- Capsule açıkken dikey feed kaydırması kilitlenir.
- Android geri hareketi önce capsule'ı kapatır.
- Video görüntülenme eşiği takibi korunur ve ayrı controller dosyasına taşınır.
- Firestore Signal işlemleri UI dosyasından ayrılmıştır.

## Dosya sınırı

Paket içindeki en uzun Dart dosyası 397 satırdır. Hiçbir Dart dosyası 400 satıra ulaşmaz.

## Not

Bu çalışma ortamında Flutter/Dart SDK bulunmadığı için `flutter analyze` çalıştırılamadı.
Dosyalar yapısal olarak ve parantez/ayraç dengesi açısından kontrol edildi.
