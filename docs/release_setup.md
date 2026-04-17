# Vibeo Release Setup

Bu dokuman, Vibeo'yu Google Play ve App Store yayinina hazirlarken tamamlanmasi gereken teknik adimlari tek yerde toplar.

## Android Release

1. Bir release keystore olustur.

```bash
keytool -genkey -v -keystore vibeo-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vibeo
```

2. `android/key.properties.example` dosyasini `android/key.properties` olarak kopyala.

3. Aasagidaki alanlari gercek degerlerle doldur:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

4. Release bundle al:

```bash
flutter build appbundle --release
```

5. Cikti konumu:

`build/app/outputs/bundle/release/app-release.aab`

## GitHub Actions Secrets

Android workflow icin su secret'lar tanimlanmali:

- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

## iOS Release

Windows uzerinden son IPA ve App Store signing dogrulamasi yapilamaz. iOS yayin icin macOS gereklidir.

1. Apple Developer hesabinda bundle id ve signing profillerini hazirla.
2. Xcode uzerinden `Runner` target signing ayarlarini tamamla.
3. Arsiv al ve App Store Connect'e gonder.

## Submission Checklist

- Production Firebase projesi dogrulandi
- Gizlilik politikasi yayinda
- Hesap silme akisi cihazda test edildi
- Android AAB ic testten gecti
- iOS archive App Store Connect'e yuklendi
- Ekran goruntuleri, aciklama, anahtar kelimeler ve yas derecelendirmesi hazir