# Vibeo

Vibeo, AI destekli sosyal içerik ve yaratıcı üretim odaklı Flutter uygulamasıdır. Proje Firebase altyapısı üzerinde çalışır ve mobil yayın hedefi App Store ile Google Play'dir.

## Üretim Durumu

Kod tabanı şu an için yayın öncesi temel gereksinimlerin önemli kısmını karşılar:

- Firebase bootstrap hata ekranı mevcut
- Gizlilik politikası ve kullanım koşulları uygulama içinde mevcut
- Profil ekranında destek, değerlendirme ve hesap silme akışı mevcut
- Web dağıtımı Firebase Hosting üzerinden yapılabiliyor
- `flutter analyze` temiz çalışıyor

## Temel Komutlar

Bağımlılıkları çek:

```bash
flutter pub get
```

Analiz çalıştır:

```bash
flutter analyze
```

Web build al:

```bash
flutter build web
```

Android release bundle üret:

```bash
flutter build appbundle
```

iOS release build kontrolü:

```bash
flutter build ipa
```

Firebase Hosting deploy:

```bash
firebase deploy --only hosting --project vibeo-58032
```

## Yayın Öncesi Kontrol Listesi

### Kod ve Ürün

- Firebase production proje ayarlarını doğrula
- App içi hesap silme akışını gerçek production verisiyle test et
- Moderasyon, raporlama ve paylaşım akışlarını cihazda test et
- Boş durum, ağ hatası ve oturum düşme senaryolarını gerçek cihazda test et

### Google Play

- Release keystore yapılandırmasını tamamla
- `applicationId`, uygulama adı ve sürüm numarasını son hale getir
- Play Console veri güvenliği formunu doldur
- Gizlilik politikası URL'sini yayın kaydına ekle
- En az 12 ekran görüntüsü ve feature graphic yükle
- Internal testing ile AAB doğrula

### App Store

- Apple Developer signing ve provisioning profillerini tamamla
- App Privacy cevaplarını Firebase, kimlik doğrulama ve kullanıcı içeriğine göre doldur
- Hesap silme akışını App Review senaryosunda doğrula
- Export compliance ve izin açıklamalarını tekrar kontrol et
- App Store Connect ekran görüntüleri, açıklama ve age rating alanlarını doldur

## Bilinen Manuel İşler

- Android signing dosyaları bu repoda tutulmuyor
- iOS signing ve App Store Connect metadata manuel tamamlanmalı
- Store açıklamaları, ekran görüntüleri ve pazarlama metinleri ayrıca hazırlanmalı

## Hazır Şablonlar

- Android signing örneği: `android/key.properties.example`
- Release adımları: `docs/release_setup.md`
- Store listing metin şablonu: `docs/store_listing_template.md`

## Hosting

Firebase Hosting projesi `vibeo-58032` olarak yapılandırılmıştır.

Canlı URL:

`https://vibeo-58032.web.app`
