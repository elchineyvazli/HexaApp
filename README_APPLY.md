# Hexa Android cihaz içi video sıkıştırma

## Gerçek durum

Projede thumbnail ve metadata okuma zaten vardı. Eksik olan şey, kaynak videoyu
Firebase'e göndermeden önce yeniden encode ederek 40 MB sınırına indirmekti.

Bu patch:

- `functions/` kullanmaz.
- TypeScript kullanmaz.
- Cloud Transcoder kullanmaz.
- Android cihazda Media3 Transformer kullanır.
- 360p videoyu 360p, 1080p videoyu 1080p, 4K videoyu 4K tutar.
- Çözünürlük desteklenmiyorsa gizlice düşürmek yerine hata verir.
- 40 MB altındaki videoyu yeniden encode etmez.
- 40 MB üzerindeki videoyu H.264 + AAC MP4 olarak sıkıştırır.
- İki bitrate denemesi yapar.
- Nihai dosya 40 MB üstündeyse upload'a izin vermez.

## Yeni dosyalar

- `lib/features/feed/upload/video_compression_models.dart`
- `lib/features/feed/upload/video_compression_service.dart`
- `android/app/src/main/kotlin/com/example/hexa_prod/HexaVideoCompressionPlugin.kt`
- `android/app/src/main/kotlin/com/example/hexa_prod/HexaVideoCompressor.kt`

## Değiştirilen dosyalar

- `lib/features/feed/upload_screen.dart`
- `lib/features/feed/upload_service.dart`
- `lib/features/feed/video_upload_preparer.dart`
- `lib/features/feed/video_upload_validation.dart`
- `lib/features/feed/video_upload_limits.dart`
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/example/hexa_prod/MainActivity.kt`

## Bilerek değiştirilmedi

- `pubspec.yaml`: Yeni Flutter paketi gerekmiyor.
- `AndroidManifest.xml`: Yeni izin gerekmiyor.

## Henüz uygulanmaması gereken iki güvenlik kuralı

Son `firestore.rules` ve `storage.rules` sürümleri paylaşılmadığı için bu patch
onları tahmin ederek değiştirmez.

Uygulama çalışmadan önce:

1. Storage video create sınırı 200 MB yerine 40 MB olmalı.
2. Firestore `sourceSizeBytes` sınırı 40 MB olmalı.
3. Firestore video create işlemi:
   - `processingStatus == "ready"`
   - `status == "ready"`
   değerlerini kabul etmeli.
4. Cloud Transcoder alanları zorunlu olmamalı.

## Kurulum

```powershell
flutter clean
flutter pub get
flutter run
```

Android Gradle ilk derlemede Media3 1.10.1 paketlerini indirecektir.

## Test

- 10 MB video: sıkıştırmadan hazırlanmalı.
- 80 MB video: sıkıştırılmalı ve 40 MB altında olmalı.
- 360p video: çözünürlük değişmemeli.
- 1080p video: çözünürlük değişmemeli.
- 4K video: cihaz destekliyorsa çözünürlük değişmemeli.
- Desteklemeyen cihazda açık hata gösterilmeli.
