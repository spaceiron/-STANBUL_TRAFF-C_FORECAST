// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web desteklenmiyor.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Bu platform desteklenmiyor.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDZ9Ag9SdpuNj2Qc7ADlgfeJzelU7PnSgI',
    appId:             '1:364001890523:android:fa285ecf48b98e7ed3fcfe',
    messagingSenderId: '364001890523',
    projectId:         'istanbul-traffic-forecast',
    storageBucket:     'istanbul-traffic-forecast.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDZ9Ag9SdpuNj2Qc7ADlgfeJzelU7PnSgI',
    appId:             '1:364001890523:ios:fa285ecf48b98e7ed3fcfe',
    messagingSenderId: '364001890523',
    projectId:         'istanbul-traffic-forecast',
    storageBucket:     'istanbul-traffic-forecast.firebasestorage.app',
    iosBundleId:       'com.example.istanbulTrafficForecast',
  );
}