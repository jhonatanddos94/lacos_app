import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/app/app.dart';
import 'package:lacos_app/core/config/firebase_bootstrap.dart';

/// Inicializa e executa o aplicativo.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();

  runApp(
    const ProviderScope(
      child: LacosApp(),
    ),
  );
}
