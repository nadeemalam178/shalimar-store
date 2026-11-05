import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated for Shalimar Store project `shalimar-store`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCRDdaIHuuL61c4HyDkSgovdmCAjfpx29k',
    appId: '1:741135454571:web:3b200e8f5bb84acb127c2e',
    messagingSenderId: '741135454571',
    projectId: 'shalimar-store',
    storageBucket: 'shalimar-store.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRDdaIHuuL61c4HyDkSgovdmCAjfpx29k',
    appId: '1:741135454571:android:3b200e8f5bb84acb127c2e',
    messagingSenderId: '741135454571',
    projectId: 'shalimar-store',
    storageBucket: 'shalimar-store.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRDdaIHuuL61c4HyDkSgovdmCAjfpx29k',
    appId: '1:741135454571:ios:3b200e8f5bb84acb127c2e',
    messagingSenderId: '741135454571',
    projectId: 'shalimar-store',
    storageBucket: 'shalimar-store.firebasestorage.app',
  );
}

