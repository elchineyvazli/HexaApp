# Hexa Transcoding Backend

Bu paket Google Cloud Transcoder API ve Firebase Functions Gen 2 kullanır.

## Gerçek durum

Projede `hlsUrl`, `renditionUrls` ve işleme durumları için istemci modeli vardı; ancak çalışan bir Transcoder/Functions backend'i yoktu. Bu paket gerçek backend'i ekler.

## Akış

1. Flutter kaynak videoyu ve thumbnail'ı Storage'a yükler.
2. Video belgesi `processingStatus: uploaded` ile oluşturulur.
3. `startVideoTranscode` Transcoder API `preset/web-hd` işini başlatır.
4. `reconcileVideoTranscodes` her dakika işleri kontrol eder.
5. Başarıda `sd.mp4` ve `hd.mp4` için Firebase download token oluşturulur.
6. Firestore'a `360p` ve `720p` rendition URL'leri yazılır.
7. Belge `ready` olur ve feed/profilde görünür.

Transcoder preset'i ayrıca HLS üretir. Güvenli HLS manifest dağıtımı ayrı bir CDN/proxy tasarımı gerektirdiğinden bu sürüm HLS yolunu saklar ama `hlsUrl` alanını boş bırakır. Uygulama güvenli token'lı MP4 rendition'ları kullanır.

## Bölgeyi doğrula

Bucket adı: `hexa-b1825.firebasestorage.app`

Bucket konumunu kontrol et:

```bash
gcloud storage buckets describe gs://hexa-b1825.firebasestorage.app \
  --format='value(location)'
```

`functions/.env.example` dosyasını `functions/.env` olarak kopyala. Bucket'a en yakın desteklenen Transcoder bölgesini yaz. Varsayılan `europe-west1` sadece güvenli bir başlangıç değeridir.

## Kurulum

```bash
cp functions/.env.example functions/.env
npm --prefix functions install
npm --prefix functions run build
```

Gerekli API'ler:

```bash
gcloud services enable \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  eventarc.googleapis.com \
  artifactregistry.googleapis.com \
  cloudscheduler.googleapis.com \
  transcoder.googleapis.com
```

Functions servis hesabını bul:

```bash
gcloud functions describe startVideoTranscode \
  --gen2 \
  --region=europe-west1 \
  --format='value(serviceConfig.serviceAccountEmail)'
```

İlk deploy'dan önce servis hesabı henüz görünmüyorsa proje numarasını kullanarak Gen 2 varsayılan compute servis hesabına `roles/transcoder.admin` ver:

```bash
PROJECT_ID=hexa-b1825
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
FUNCTION_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${FUNCTION_SA}" \
  --role="roles/transcoder.admin"
```

Transcoder servis ajanı ilk işte otomatik oluşturulur ve aynı projedeki bucket'lara varsayılan erişim alır. İlk işte izin hatası olursa servis ajanının oluşması için birkaç dakika bekle.

## Deploy

```bash
firebase use hexa-b1825
firebase deploy --only functions,firestore:rules,storage
```

## Kontrol

Yeni video belgesinde sırasıyla şu durumları görmelisin:

```text
uploaded -> submitting -> processing -> ready
```

Başarıda:

```text
renditionUrls.360p
renditionUrls.720p
transcoderJobName
transcodedStoragePrefix
transcodingCompletedAt
```

Başarısızlıkta:

```text
processingStatus: failed
processingError: ...
```

## Notlar

- Transcoder API asenkrondur; kullanıcı upload ekranında işlem bitmesini beklemez.
- `preset/web-hd` resmi preset'i `sd.mp4`, `hd.mp4` ve HLS çıktıları üretir.
- Kaynak width/height limiti 4096'a indirildi; bu Transcoder API giriş limitidir.
- Feed ve profil yalnızca `ready` videoları gösterir.
- Her dosya 500 satırın altındadır.
