import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lacos_app/core/router/app_router.dart';
import 'package:lacos_app/core/theme/app_theme.dart';

/// Widget raiz do aplicativo Laços.
class LacosApp extends ConsumerWidget {
  const LacosApp({super.key});

  static const appLocale = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Laços',
      debugShowCheckedModeBanner: false,
      locale: appLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [appLocale],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
