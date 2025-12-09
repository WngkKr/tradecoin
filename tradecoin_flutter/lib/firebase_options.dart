// Firebase 설정 파일 (React에서 가져온 설정)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // emotra-9ebdb 프로젝트 설정
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5ZSuv5WSkgvH_JfhG-UCXrLjAr064S2A',
    appId: '1:324977398952:web:8693e08ec7edc8065f9e9d',
    messagingSenderId: '324977398952',
    projectId: 'emotra-9ebdb',
    authDomain: 'emotra-9ebdb.firebaseapp.com',
    storageBucket: 'emotra-9ebdb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: '1:your-app-id:android:your-android-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'emotra-9ebdb',
    storageBucket: 'emotra-9ebdb.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: '1:your-app-id:ios:your-ios-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'emotra-9ebdb',
    storageBucket: 'emotra-9ebdb.appspot.com',
    iosBundleId: 'com.tradecoin.flutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: '1:your-app-id:ios:your-macos-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'emotra-9ebdb',
    storageBucket: 'emotra-9ebdb.appspot.com',
    iosBundleId: 'com.tradecoin.flutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-windows-api-key',
    appId: '1:your-app-id:web:your-windows-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'emotra-9ebdb',
    authDomain: 'emotra-9ebdb.firebaseapp.com',
    storageBucket: 'emotra-9ebdb.appspot.com',
  );
}