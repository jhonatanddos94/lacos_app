import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';
import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';
import 'package:lacos_app/features/monetization/domain/premium_product_config.dart';
import 'package:lacos_app/features/monetization/presentation/pages/premium_page.dart';
import 'package:lacos_app/features/more/application/providers/app_package_info_provider.dart';
import 'package:lacos_app/features/more/presentation/navigation/more_navigation.dart';
import 'package:lacos_app/features/more/presentation/pages/more_page.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

import '../../../../helpers/fake_ads_sdk.dart';
import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);
  var workspaceLoads = 0;

  setUp(() {
    workspaceLoads = 0;
    resetMoreNavigationGuardsForTest();
  });

  tearDown(resetMoreNavigationGuardsForTest);

  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(400, 1200),
    TextScaler textScaler = TextScaler.noScaling,
    List<Override> extraOverrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async {
            workspaceLoads++;
            return homeTestWorkspace();
          }),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          adsSdkProvider.overrideWithValue(FakeAdsSdk()),
          appPackageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Laços',
              packageName: 'lacos_app',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
          ...extraOverrides,
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: AppShellPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mais'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPremiumPage(
    WidgetTester tester, {
    MonetizationTier tier = MonetizationTier.free,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [monetizationTierProvider.overrideWithValue(tier)],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: PremiumPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('A/C/D: Mais mostra card Premium com preço', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(find.byKey(MorePage.premiumCardKey), findsOneWidget);
    expect(find.text(AppStrings.premiumTitle), findsOneWidget);
    expect(
      find.text(PremiumProductConfig.current.pricePerPeriod),
      findsOneWidget,
    );
    expect(find.text(AppStrings.premiumCardCta), findsOneWidget);
  });

  testWidgets('B: card fica antes de SEU NEGÓCIO', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    final cardY = tester.getTopLeft(find.byKey(MorePage.premiumCardKey)).dy;
    final businessY = tester
        .getTopLeft(find.text(AppStrings.moreBusinessSection))
        .dy;
    expect(cardY, lessThan(businessY));
  });

  testWidgets('E/G/H: card abre PremiumPage e back retorna à Mais', (
    tester,
  ) async {
    await pumpShell(tester);
    await openMore(tester);

    await tester.tap(find.byKey(MorePage.premiumCardKey));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(PremiumPage), findsNothing);
    expect(find.byKey(MorePage.pageKey), findsOneWidget);
  });

  testWidgets('F: duplo toque não empilha PremiumPage', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    await tester.tap(find.byKey(MorePage.premiumCardKey));
    await tester.tap(
      find.byKey(MorePage.premiumCardKey),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PremiumPage), findsOneWidget);
  });

  testWidgets('I/J/K: PremiumPage mostra título e benefícios honestos', (
    tester,
  ) async {
    await pumpPremiumPage(tester);

    expect(find.text(AppStrings.premiumPageHeadline), findsOneWidget);
    expect(find.text(AppStrings.premiumBenefitAdsTitle), findsOneWidget);
    expect(find.text(AppStrings.premiumBenefitEvolutionTitle), findsOneWidget);
  });

  testWidgets('L/M/N: não mostra IA, equipe nem recursos inexistentes', (
    tester,
  ) async {
    await pumpPremiumPage(tester);

    expect(find.textContaining('Inteligência'), findsNothing);
    expect(find.textContaining('Assistente'), findsNothing);
    expect(find.textContaining('equipe'), findsNothing);
    expect(find.textContaining('ilimitad'), findsNothing);
    expect(find.textContaining('backup'), findsNothing);
    expect(find.textContaining('suporte prioritário'), findsNothing);
  });

  testWidgets('O/AJ: CTA disabled não concede Premium', (tester) async {
    await pumpPremiumPage(tester);

    final button = tester.widget<AppButton>(find.byKey(PremiumPage.ctaKey));
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(PremiumPage.ctaKey), warnIfMissed: false);
    await tester.pump();

    expect(find.byKey(PremiumPage.ctaKey), findsOneWidget);
    expect(find.byKey(PremiumPage.activeStatusKey), findsNothing);
    expect(find.byKey(PremiumPage.priceKey), findsOneWidget);
  });

  testWidgets('R/S: override Premium mostra status e esconde CTA/preço', (
    tester,
  ) async {
    await pumpPremiumPage(tester, tier: MonetizationTier.premium);

    expect(find.text(AppStrings.premiumActiveStatus), findsOneWidget);
    expect(find.byKey(PremiumPage.ctaKey), findsNothing);
    expect(find.byKey(PremiumPage.priceKey), findsNothing);
    expect(find.text(AppStrings.premiumCtaPreparing), findsNothing);
  });

  testWidgets('Y/Z: abrir Mais e Premium não consulta workspace extra', (
    tester,
  ) async {
    await pumpShell(tester);
    final afterShell = workspaceLoads;

    await openMore(tester);
    expect(workspaceLoads, afterShell);

    await tester.tap(find.byKey(MorePage.premiumCardKey));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumPage), findsOneWidget);
    expect(workspaceLoads, afterShell);
  });

  testWidgets('AB/AC/AD: 320/360/390 sem overflow no card e na página', (
    tester,
  ) async {
    for (final width in [320.0, 360.0, 390.0]) {
      await pumpShell(tester, size: Size(width, 640));
      await openMore(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(MorePage.premiumCardKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('AE/AF: textScale 1.3 e 1.5 sem overflow', (tester) async {
    for (final scale in [1.3, 1.5]) {
      await pumpPremiumPage(
        tester,
        size: const Size(320, 640),
        textScaler: TextScaler.linear(scale),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(PremiumPage.pageKey), findsOneWidget);
    }
  });

  testWidgets('AG: PremiumPage é scrollável', (tester) async {
    await pumpPremiumPage(tester, size: const Size(320, 640));

    expect(tester.widget(find.byKey(PremiumPage.pageKey)), isA<ListView>());
  });

  testWidgets('AH/AI: card tem touch target >= 48 e semantics', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(
      tester.getSize(find.byKey(MorePage.premiumCardKey)).shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSemantics(find.byKey(MorePage.premiumCardKey))
          .label,
      AppStrings.premiumCardSemantics(
        PremiumProductConfig.current.pricePerPeriod,
      ),
    );
  });

  testWidgets('AO: Mais continua com Salão, Perfil e Suporte', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(find.byKey(MorePage.salonItemKey), findsOneWidget);
    expect(find.byKey(MorePage.profileItemKey), findsOneWidget);
    expect(find.byKey(MorePage.helpItemKey), findsOneWidget);
    expect(find.byKey(MorePage.aboutItemKey), findsOneWidget);
  });
}
