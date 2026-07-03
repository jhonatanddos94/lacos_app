import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:lacos_app/firebase_options.dart';

/// Indica se o Firebase foi inicializado nesta sessão.
bool isFirebaseInitialized = false;

/// Inicializa o Firebase quando a configuração estiver disponível.
Future<void> initializeFirebase() async {
  if (isFirebaseInitialized) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } on UnsupportedError catch (error) {
    debugPrint('Firebase: $error');
  } on FirebaseException catch (error) {
    debugPrint(
      'Firebase: configuração inválida (${error.code}). '
      'Execute flutterfire configure.',
    );
  }
}
