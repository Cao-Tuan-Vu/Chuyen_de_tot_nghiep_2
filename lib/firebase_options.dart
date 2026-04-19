import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for this project.
///
/// Note: Android values are configured from `google-services.json`.
/// For iOS/Web/Desktop, run `flutterfire configure` to generate full options.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos. '
          'Run flutterfire configure.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows. '
          'Run flutterfire configure.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux. '
          'Run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2PMeYcSFRATNr4rHHoZNZAVT5W5KiRVM',
    appId: '1:319308367191:android:8441def48e404a3a74aa12',
    messagingSenderId: '319308367191',
    projectId: 'news-app-6ef88',
    databaseURL: 'https://news-app-6ef88-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'news-app-6ef88.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLCarktkI_sx9ph8YcXsy28n9-YbgSiW4',
    appId: '1:319308367191:web:504f2f8ee671b2b874aa12',
    messagingSenderId: '319308367191',
    projectId: 'news-app-6ef88',
    authDomain: 'news-app-6ef88.firebaseapp.com',
    databaseURL: 'https://news-app-6ef88-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'news-app-6ef88.firebasestorage.app',
    measurementId: 'G-DZW0ZQ0V1Y',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCf2kAJXgWXHWLOi6j9Nqf3lREuRiApQW4',
    appId: '1:319308367191:ios:ab52b51e7f78efa674aa12',
    messagingSenderId: '319308367191',
    projectId: 'news-app-6ef88',
    databaseURL: 'https://news-app-6ef88-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'news-app-6ef88.firebasestorage.app',
    iosBundleId: 'com.example.btl',
  );

}