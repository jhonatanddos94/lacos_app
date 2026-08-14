import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/widgets/splash_loading_indicator.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/presentation/pages/login_page.dart';
import 'package:lacos_app/features/splash/presentation/pages/splash_page.dart';

import '../../../../helpers/lacos_app_test_helper.dart';

void main() {
  /// Mantém a Splash em loading para testes de layout sem disparar navegação.
  List<Override> splashLayoutOverrides() {
    return [
      workspaceProvider.overrideWith(
        (ref) => Completer<Workspace?>().future,
      ),
    ];
  }

  Future<void> flushSplashTimers(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
  }

  Future<void> pumpSplash(
    WidgetTester tester, {
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...splashLayoutOverrides(), ...overrides],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: SplashPage()),
        ),
      ),
    );
    await tester.pump();
  }

  double brandLogoWidth(WidgetTester tester) {
    return tester.getSize(find.byKey(SplashPage.brandLogoKey)).width;
  }

  group('SplashPage — marca e conteúdo', () {
    testWidgets('A–C: marca, nome Laços e subtítulo continuam visíveis', (
      tester,
    ) async {
      await pumpSplash(tester, size: const Size(390, 844));

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.bySemanticsLabel('Laços'), findsOneWidget);
      expect(find.text(AppStrings.splashPreparing), findsOneWidget);
      expect(find.text(AppStrings.splashYourEnvironment), findsOneWidget);
      expect(find.byType(SplashLoadingIndicator), findsOneWidget);

      await flushSplashTimers(tester);
    });
  });

  group('SplashPage — responsividade sem overflow', () {
    Future<void> expectNoOverflowAt(
      WidgetTester tester, {
      required Size size,
      TextScaler textScaler = TextScaler.noScaling,
    }) async {
      await pumpSplash(tester, size: size, textScaler: textScaler);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.splashPreparing), findsOneWidget);
      await flushSplashTimers(tester);
    }

    testWidgets('D: 320x640 sem overflow', (tester) async {
      await expectNoOverflowAt(tester, size: const Size(320, 640));
    });

    testWidgets('E: 360x800 sem overflow', (tester) async {
      await expectNoOverflowAt(tester, size: const Size(360, 800));
    });

    testWidgets('F: 390x844 sem overflow', (tester) async {
      await expectNoOverflowAt(tester, size: const Size(390, 844));
    });

    testWidgets('G: textScale 1.3 sem overflow', (tester) async {
      await expectNoOverflowAt(
        tester,
        size: const Size(390, 844),
        textScaler: const TextScaler.linear(1.3),
      );
    });

    testWidgets('H: textScale 1.5 sem overflow', (tester) async {
      await expectNoOverflowAt(
        tester,
        size: const Size(320, 640),
        textScaler: const TextScaler.linear(1.5),
      );
    });

    testWidgets('viewport maior sem overflow', (tester) async {
      await expectNoOverflowAt(tester, size: const Size(800, 1280));
    });
  });

  group('SplashPage — dimensão da marca', () {
    testWidgets('I: laço respeita largura responsiva por viewport', (
      tester,
    ) async {
      const cases = <({Size size, double expectedWidth})>[
        (size: Size(320, 640), expectedWidth: 165),
        (size: Size(360, 800), expectedWidth: 172.8),
        (size: Size(390, 844), expectedWidth: 187.2),
        (size: Size(800, 1280), expectedWidth: 255),
      ];

      for (final testCase in cases) {
        await pumpSplash(tester, size: testCase.size);
        expect(
          brandLogoWidth(tester),
          closeTo(testCase.expectedWidth, 0.1),
        );
        await flushSplashTimers(tester);
      }
    });
  });

  testWidgets('J: fluxo de navegação permanece intacto', (tester) async {
    await pumpLacosApp(tester, overrides: unauthenticatedAppOverrides());
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);

    await pumpUntilLoginReady(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Bem-vinda de volta!'), findsOneWidget);
  });
}
