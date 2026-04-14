import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Bu platform desteklenmiyor: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXeORIk64WNqHdsEpDY-iMpDSjVn47jYo',
    appId: '1:74675326225:android:bb1e083dad5a6ec7abd0b0',
    messagingSenderId: '74675326225',
    projectId: 'vibeo-58032',
    storageBucket: 'vibeo-58032.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA6D07NCVDuLkhfILOQJ4bKV_KtkyTNyNA',
    appId: '1:74675326225:ios:40742a0d2c80a4b9abd0b0',
    messagingSenderId: '74675326225',
    projectId: 'vibeo-58032',
    storageBucket: 'vibeo-58032.firebasestorage.app',
    iosBundleId: 'com.vibeo.app',
  );
}
