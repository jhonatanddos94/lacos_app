import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/support_config.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/more/application/providers/support_providers.dart';
import 'package:lacos_app/features/more/presentation/pages/help_support_page.dart';

import '../../../../helpers/fake_external_url_launcher.dart';

void main() {
  const config = SupportConfig(
    whatsappPhone: '5567999999999',
    whatsappInitialMessage: 'Olá! Preciso de ajuda com o aplicativo Laços.',
  );

  Future<void> pumpHelp(
    WidgetTester tester, {
    required FakeExternalUrlLauncher launcher,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
    int Function()? onWorkspaceLoad,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportConfigProvider.overrideWithValue(config),
          externalUrlLauncherProvider.overrideWithValue(launcher),
          if (onWorkspaceLoad != null)
            workspaceProvider.overrideWith((ref) async {
              onWorkspaceLoad();
              return null;
            }),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: HelpSupportPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('A–E: página mostra conteúdo e CTA acessível', (tester) async {
    await pumpHelp(tester, launcher: FakeExternalUrlLauncher());

    expect(find.byKey(HelpSupportPage.pageKey), findsOneWidget);
    expect(find.text(AppStrings.moreHelpSupport), findsOneWidget);
    expect(find.text(AppStrings.moreHelpIntro), findsOneWidget);
    expect(find.text(AppStrings.moreHelpBody), findsOneWidget);
    expect(find.text(AppStrings.supportCardTitle), findsOneWidget);
    expect(find.text(AppStrings.supportCardDescription), findsOneWidget);
    expect(find.text(AppStrings.supportExternalNotice), findsOneWidget);
    expect(find.text(AppStrings.supportWhatsAppAction), findsOneWidget);
    expect(
      tester.getSize(find.byKey(HelpSupportPage.whatsappButtonKey)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets(
    'J/N/Y: tap usa fake launcher uma vez e sucesso não mostra erro',
    (tester) async {
      final launcher = FakeExternalUrlLauncher();
      await pumpHelp(tester, launcher: launcher);

      await tester.tap(find.byKey(HelpSupportPage.whatsappButtonKey));
      await tester.pump();

      expect(launcher.calls, 1);
      expect(launcher.launchedUris.single.host, 'wa.me');
      expect(find.text(AppStrings.supportWhatsAppOpenError), findsNothing);
    },
  );

  testWidgets('K: dois taps rápidos não duplicam launch', (tester) async {
    final launcher = FakeExternalUrlLauncher()..completer = Completer<bool>();
    await pumpHelp(tester, launcher: launcher);

    final button = find.byKey(HelpSupportPage.whatsappButtonKey);
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    expect(launcher.calls, 1);
    launcher.completer!.complete(true);
    await tester.pump();
  });

  testWidgets('O/Q: falha mostra feedback e mantém página funcional', (
    tester,
  ) async {
    final launcher = FakeExternalUrlLauncher(result: false);
    await pumpHelp(tester, launcher: launcher);

    await tester.tap(find.byKey(HelpSupportPage.whatsappButtonKey));
    await tester.pump();

    expect(find.text(AppStrings.supportWhatsAppOpenError), findsOneWidget);
    expect(find.byKey(HelpSupportPage.pageKey), findsOneWidget);
    expect(find.byKey(HelpSupportPage.whatsappButtonKey), findsOneWidget);
  });

  testWidgets('P: exception técnica não vaza', (tester) async {
    final launcher = FakeExternalUrlLauncher()
      ..error = Exception('PlatformException URL token');
    await pumpHelp(tester, launcher: launcher);

    await tester.tap(find.byKey(HelpSupportPage.whatsappButtonKey));
    await tester.pump();

    expect(find.text(AppStrings.supportWhatsAppOpenError), findsOneWidget);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R–U: 320/390px e textScale 1.3/1.5 sem overflow', (
    tester,
  ) async {
    for (final scenario in [
      (const Size(320, 640), const TextScaler.linear(1.3)),
      (const Size(320, 640), const TextScaler.linear(1.5)),
      (const Size(390, 844), TextScaler.noScaling),
    ]) {
      await pumpHelp(
        tester,
        launcher: FakeExternalUrlLauncher(),
        size: scenario.$1,
        textScaler: scenario.$2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
      expect(find.byKey(HelpSupportPage.pageKey), findsOneWidget);
    }
  });

  testWidgets('V: abrir e tocar suporte não lê workspace/Parse', (
    tester,
  ) async {
    var workspaceLoads = 0;
    final launcher = FakeExternalUrlLauncher();
    await pumpHelp(
      tester,
      launcher: launcher,
      onWorkspaceLoad: () => workspaceLoads++,
    );

    await tester.tap(find.byKey(HelpSupportPage.whatsappButtonKey));
    await tester.pump();

    expect(workspaceLoads, 0);
    expect(launcher.calls, 1);
  });
}
