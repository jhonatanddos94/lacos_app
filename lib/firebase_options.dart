import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuração do Firebase para o Laços.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _notConfigured('Web');
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => _notConfigured('macOS'),
      _ => _notConfigured(defaultTargetPlatform.name),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJDulq7FNotvn5LEun-8fL8iRLzyPqi78',
    appId: '1:94174449027:android:c6f402237790394cdd3ab6',
    messagingSenderId: '94174449027',
    projectId: 'app-lacos',
    storageBucket: 'app-lacos.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApOM90E2hFi6B5qSRSTQc3MVJ5nHPAOwg',
    appId: '1:94174449027:ios:2caa41600529421bdd3ab6',
    messagingSenderId: '94174449027',
    projectId: 'app-lacos',
    storageBucket: 'app-lacos.firebasestorage.app',
    iosBundleId: 'com.algorythm.primeiroApp',
  );

  static Never _notConfigured(String platform) {
    throw UnsupportedError(
      'Firebase não configurado para $platform. '
      'Adicione o app no Firebase Console e execute: flutterfire configure',
    );
  }
}
