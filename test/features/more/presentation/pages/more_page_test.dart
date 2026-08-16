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
import 'package:lacos_app/features/more/application/providers/app_package_info_provider.dart';
import 'package:lacos_app/features/more/presentation/navigation/more_navigation.dart';
import 'package:lacos_app/features/more/presentation/pages/about_page.dart';
import 'package:lacos_app/features/more/presentation/pages/help_support_page.dart';
import 'package:lacos_app/features/more/presentation/pages/more_page.dart';
import 'package:lacos_app/features/more/presentation/widgets/more_menu_tile.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/professional/presentation/pages/professional_profile_page.dart';
import 'package:lacos_app/features/salon/presentation/navigation/salon_navigation.dart';
import 'package:lacos_app/features/salon/presentation/pages/salon_page.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';

import '../../../../helpers/fake_ads_sdk.dart';
import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);
  var workspaceLoads = 0;

  setUp(() {
    workspaceLoads = 0;
    resetProfessionalProfileNavigationGuardForTest();
    resetSalonNavigationGuardForTest();
    resetMoreNavigationGuardsForTest();
  });

  tearDown(() {
    resetProfessionalProfileNavigationGuardForTest();
    resetSalonNavigationGuardForTest();
    resetMoreNavigationGuardsForTest();
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    FakeAdsSdk? ads,
    Size size = const Size(400, 1200),
    TextScaler textScaler = TextScaler.noScaling,
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
          adsSdkProvider.overrideWithValue(ads ?? FakeAdsSdk()),
          appPackageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Laços',
              packageName: 'lacos_app',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
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

  Finder moreText(String text) {
    return find.descendant(
      of: find.byKey(MorePage.pageKey),
      matching: find.text(text),
    );
  }

  testWidgets('A/B: header mostra Mais e o subtítulo', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(moreText(AppStrings.moreTitle), findsOneWidget);
    expect(moreText(AppStrings.moreSubtitle), findsOneWidget);
    expect(find.text('Mais em breve'), findsNothing);
  });

  testWidgets('C: grupos de seção existem', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(moreText(AppStrings.moreBusinessSection), findsOneWidget);
    expect(moreText(AppStrings.moreAccountSection), findsOneWidget);
    expect(moreText(AppStrings.moreSupportSection), findsOneWidget);
    expect(find.byKey(MorePage.businessGroupKey), findsOneWidget);
    expect(find.byKey(MorePage.accountGroupKey), findsOneWidget);
    expect(find.byKey(MorePage.supportGroupKey), findsOneWidget);
  });

  testWidgets('D/E/F/G: itens de navegação têm ícone', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(
      find.descendant(
        of: find.byKey(MorePage.salonItemKey),
        matching: find.byIcon(MoreMenuTile.salonIcon),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(MorePage.profileItemKey),
        matching: find.byIcon(MoreMenuTile.profileIcon),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(MorePage.helpItemKey),
        matching: find.byIcon(MoreMenuTile.helpIcon),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(MorePage.aboutItemKey),
        matching: find.byIcon(MoreMenuTile.aboutIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('H: privacy tem ícone quando required', (tester) async {
    await pumpShell(tester, ads: FakeAdsSdk(privacyOptionsRequired: true));
    await openMore(tester);

    expect(
      find.descendant(
        of: find.byKey(MorePage.privacyItemKey),
        matching: find.byIcon(MoreMenuTile.privacyIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('I/J: suporte agrupa Ajuda e Sobre com divider', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(
      find.descendant(
        of: find.byKey(MorePage.supportGroupKey),
        matching: find.byKey(MorePage.helpItemKey),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(MorePage.supportGroupKey),
        matching: find.byKey(MorePage.aboutItemKey),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(MorePage.supportGroupKey),
        matching: find.byKey(MorePage.supportDividerKey),
      ),
      findsOneWidget,
    );
  });

  testWidgets('K/L: chevron só em navegação; privacy sem chevron', (
    tester,
  ) async {
    await pumpShell(tester, ads: FakeAdsSdk(privacyOptionsRequired: true));
    await openMore(tester);

    for (final key in [
      MorePage.salonItemKey,
      MorePage.profileItemKey,
      MorePage.helpItemKey,
      MorePage.aboutItemKey,
    ]) {
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsOneWidget,
      );
    }

    expect(
      find.descendant(
        of: find.byKey(MorePage.privacyItemKey),
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('M: privacy hidden não deixa seção residual', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(find.byKey(MorePage.privacyItemKey), findsNothing);
    expect(find.byKey(MorePage.privacyGroupKey), findsNothing);
    expect(moreText(AppStrings.morePrivacySection), findsNothing);
    expect(find.text(AppStrings.adsPrivacyOptions), findsNothing);
  });

  testWidgets('N/O: 320px e 390px sem overflow', (tester) async {
    for (final width in [320.0, 390.0]) {
      await pumpShell(
        tester,
        ads: FakeAdsSdk(privacyOptionsRequired: true),
        size: Size(width, 640),
      );
      await openMore(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
      expect(find.byKey(MorePage.pageKey), findsOneWidget);
    }
  });

  testWidgets('P/Q: textScale 1.3 e 1.5 sem overflow', (tester) async {
    for (final scaler in [
      const TextScaler.linear(1.3),
      const TextScaler.linear(1.5),
    ]) {
      await pumpShell(
        tester,
        ads: FakeAdsSdk(privacyOptionsRequired: true),
        size: const Size(320, 640),
        textScaler: scaler,
      );
      await openMore(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(MorePage.pageKey), findsOneWidget);
    }
  });

  testWidgets('R: touch targets >= 48', (tester) async {
    await pumpShell(tester, ads: FakeAdsSdk(privacyOptionsRequired: true));
    await openMore(tester);

    for (final key in [
      MorePage.salonItemKey,
      MorePage.profileItemKey,
      MorePage.helpItemKey,
      MorePage.aboutItemKey,
      MorePage.privacyItemKey,
    ]) {
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('S: navegações continuam funcionando', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    await tester.tap(find.byKey(MorePage.salonItemKey));
    await tester.pumpAndSettle();
    expect(find.byType(SalonPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MorePage.profileItemKey));
    await tester.pumpAndSettle();
    expect(find.byType(ProfessionalProfilePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MorePage.helpItemKey));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MorePage.aboutItemKey));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
  });

  testWidgets('T: UMP continua funcionando', (tester) async {
    final ads = FakeAdsSdk(privacyOptionsRequired: true);
    await pumpShell(tester, ads: ads);
    await openMore(tester);

    await tester.tap(find.byKey(MorePage.privacyItemKey));
    await tester.pumpAndSettle();

    expect(ads.privacyOptionsCalls, 1);
    expect(find.byType(MorePage), findsOneWidget);
  });

  testWidgets('U: duplo toque não empilha rotas', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    await tester.tap(find.byKey(MorePage.profileItemKey));
    await tester.tap(find.byKey(MorePage.profileItemKey), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ProfessionalProfilePage), findsOneWidget);
  });

  testWidgets('V: abrir Mais não cria query Parse extra', (tester) async {
    await pumpShell(tester);
    final loadsAfterShell = workspaceLoads;

    await openMore(tester);

    expect(find.byKey(MorePage.pageKey), findsOneWidget);
    expect(workspaceLoads, loadsAfterShell);
  });

  testWidgets('W: IndexedStack permanece estável na tab Mais', (tester) async {
    await pumpShell(tester);
    await openMore(tester);

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, AppShellTab.more.index);
    expect(find.byType(MorePage, skipOffstage: false), findsOneWidget);
  });

  testWidgets('X/Y/Z: logout e Configurações não aparecem', (
    tester,
  ) async {
    await pumpShell(tester);
    await openMore(tester);

    expect(find.text(AppStrings.logout), findsNothing);
    expect(find.text('Configurações'), findsNothing);
  });
}
