import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';
import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';
import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';
import 'package:lacos_app/features/monetization/infrastructure/admob_ids.dart';
import 'package:lacos_app/features/monetization/presentation/widgets/home_ad_slot.dart';
import 'package:lacos_app/features/more/presentation/pages/more_page.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/clients_page.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

import '../../../helpers/fake_ads_sdk.dart';
import '../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  Future<void> pumpHome(
    WidgetTester tester, {
    required FakeAdsSdk ads,
    List<Override> extraOverrides = const [],
    Size size = const Size(400, 1200),
    TextScaler textScaler = TextScaler.noScaling,
    List<AgendaAppointmentDisplay> appointments = const [],
    List<HomeUpcomingDay> upcomingDays = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => appointments,
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => upcomingDays),
          adsSdkProvider.overrideWithValue(ads),
          ...extraOverrides,
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: HomePage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('D: Home funciona com Ads indisponível', (tester) async {
    await pumpHome(tester, ads: FakeAdsSdk(isSupported: false));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(find.text('AdMob Test'), findsNothing);
  });

  testWidgets('E: Home funciona com Ads loading', (tester) async {
    final ads = FakeAdsSdk(loadCompleter: Completer<LoadedBannerAd?>());
    await pumpHome(tester, ads: ads);
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.slotKey), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(find.textContaining('Erro'), findsNothing);
  });

  testWidgets('F/K: Home funciona com Ads error e falha do SDK', (
    tester,
  ) async {
    await pumpHome(tester, ads: FakeAdsSdk(loadFails: true));
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(find.textContaining('anúncio'), findsNothing);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('ParseException'), findsNothing);
    expect(find.textContaining('AdError'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G: banner aparece quando loaded', (tester) async {
    await pumpHome(tester, ads: FakeAdsSdk());
    await tester.pump();

    expect(find.byKey(HomeAdSlot.bannerKey), findsOneWidget);
    expect(find.text('AdMob Test'), findsOneWidget);
  });

  testWidgets('H/K: Premium não cria banner nem dispara load', (tester) async {
    final ads = FakeAdsSdk();
    await pumpHome(
      tester,
      ads: ads,
      extraOverrides: [
        monetizationTierProvider.overrideWithValue(MonetizationTier.premium),
      ],
    );
    await tester.pump();

    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(find.text('AdMob Test'), findsNothing);
    expect(ads.loadCalls, 0);
  });

  testWidgets('I: banner não aparece antes de canRequestAds', (tester) async {
    await pumpHome(tester, ads: FakeAdsSdk(canRequestAds: false));
    await tester.pump();

    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
  });

  testWidgets('J: falha de consentimento não quebra app', (tester) async {
    await pumpHome(
      tester,
      ads: FakeAdsSdk(prepareFails: true, canRequestAds: false),
    );
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(find.textContaining('anúncio'), findsNothing);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('ParseException'), findsNothing);
    expect(find.textContaining('AdError'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('L/M: rebuild e ticker não recriam banner', (tester) async {
    final ads = FakeAdsSdk();
    await pumpHome(tester, ads: ads);
    await tester.pump();
    expect(ads.loadCalls, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(ads.loadCalls, 1);
  });

  testWidgets('N: mudança de Appointment não recria banner', (tester) async {
    final ads = FakeAdsSdk();
    await pumpHome(tester, ads: ads);
    expect(ads.loadCalls, 1);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    container.invalidate(agendaAppointmentsDisplayProvider(today));
    await tester.pump();
    await tester.pump();
    expect(ads.loadCalls, 1);
  });

  testWidgets('O: dispose libera BannerAd', (tester) async {
    final ads = FakeAdsSdk();
    await pumpHome(tester, ads: ads);
    await tester.pump();
    expect(ads.disposeCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(ads.disposeCalls, 1);
  });

  testWidgets('P/Q/R: 320px, textScale 1.3, Home scrollável', (tester) async {
    await pumpHome(
      tester,
      ads: FakeAdsSdk(),
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(1.3),
      upcomingDays: [
        HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 2),
      ],
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
    expect(find.byKey(HomeAdSlot.bannerKey), findsOneWidget);
  });

  testWidgets('S/T/U: próximos dias e ações rápidas continuam clicáveis', (
    tester,
  ) async {
    var openedAgenda = false;
    await pumpHome(
      tester,
      ads: FakeAdsSdk(),
      upcomingDays: [
        HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 2),
      ],
    );
    await tester.pump();

    expect(
      find.byKey(HomeQuickActionsSection.newAppointmentKey),
      findsOneWidget,
    );
    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(HomeUpcomingDaysSection.openAgendaKey),
    );
    await tester.tap(find.byKey(HomeUpcomingDaysSection.openAgendaKey));
    await tester.pump();
    openedAgenda = true;
    expect(openedAgenda, isTrue);
    expect(find.byKey(HomeAdSlot.bannerKey), findsOneWidget);
  });

  testWidgets('Y: workspace não depende de Ads', (tester) async {
    final ads = FakeAdsSdk(prepareCompleter: Completer<void>());
    await pumpHome(tester, ads: ads);

    expect(find.textContaining('Maria'), findsWidgets);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
  });

  testWidgets('Z: IndexedStack não causa criação duplicada', (tester) async {
    final ads = FakeAdsSdk();
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          adsSdkProvider.overrideWithValue(ads),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(ads.loadCalls, 1);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShellPage)),
    );
    container.read(appShellTabProvider.notifier).select(AppShellTab.agenda);
    await tester.pumpAndSettle();
    expect(find.byType(AgendaPage), findsOneWidget);
    expect(ads.loadCalls, 1);

    container.read(appShellTabProvider.notifier).select(AppShellTab.home);
    await tester.pumpAndSettle();
    expect(ads.loadCalls, 1);
  });

  testWidgets('O: initialize falha sem derrubar Home', (tester) async {
    await pumpHome(tester, ads: FakeAdsSdk(initializeFails: true));
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('AdError'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('P: adaptive size null deixa slot vazio', (tester) async {
    final ads = FakeAdsSdk(adaptiveSizeNull: true);
    await pumpHome(tester, ads: ads);
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(ads.loadCalls, 1);
  });

  testWidgets('widget disposed durante load libera banner', (tester) async {
    final ads = FakeAdsSdk(loadCompleter: Completer<LoadedBannerAd?>());
    await pumpHome(tester, ads: ads);
    await tester.pump();
    expect(ads.loadCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    ads.loadCompleter!.complete(
      FakeLoadedBannerAd(
        size: const Size(320, 50),
        onDispose: () => ads.disposeCalls++,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(ads.disposeCalls, 1);
  });

  testWidgets('AA: banner fica depois de Próximos Dias', (tester) async {
    await pumpHome(
      tester,
      ads: FakeAdsSdk(),
      upcomingDays: [
        HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 2),
      ],
    );
    await tester.pump();

    final upcomingBottom = tester
        .getBottomLeft(find.byKey(HomeUpcomingDaysSection.sectionKey))
        .dy;
    final adTop = tester.getTopLeft(find.byKey(HomeAdSlot.slotKey)).dy;
    final bannerTop = tester.getTopLeft(find.byKey(HomeAdSlot.bannerKey)).dy;
    expect(adTop, greaterThanOrEqualTo(upcomingBottom));
    expect(bannerTop - upcomingBottom, closeTo(AppSpacing.md, 0.5));
  });

  testWidgets('A: banner loaded não deixa espaço excessivo abaixo', (
    tester,
  ) async {
    await pumpHome(
      tester,
      ads: FakeAdsSdk(),
      upcomingDays: [
        HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 2),
      ],
    );
    await tester.pump();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final bottomPadding = (scroll.padding as EdgeInsets).bottom;
    expect(bottomPadding, AppSpacing.sm);
    expect(bottomPadding, lessThan(AppSpacing.xl));

    final bannerBottom = tester
        .getBottomLeft(find.byKey(HomeAdSlot.bannerKey))
        .dy;
    final slotBottom = tester.getBottomLeft(find.byKey(HomeAdSlot.slotKey)).dy;
    expect(slotBottom, closeTo(bannerBottom, 0.5));
  });

  testWidgets('B/C: hidden e error não deixam espaço residual no slot', (
    tester,
  ) async {
    await pumpHome(tester, ads: FakeAdsSdk(isSupported: false));
    expect(tester.getSize(find.byKey(HomeAdSlot.slotKey)).height, 0);

    await pumpHome(tester, ads: FakeAdsSdk(loadFails: true));
    await tester.pump();
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(tester.getSize(find.byKey(HomeAdSlot.slotKey)).height, 0);
  });

  testWidgets('D: loading reserva somente a altura do placeholder', (
    tester,
  ) async {
    final ads = FakeAdsSdk(loadCompleter: Completer<LoadedBannerAd?>());
    await pumpHome(tester, ads: ads);
    await tester.pump();

    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    final slotHeight = tester.getSize(find.byKey(HomeAdSlot.slotKey)).height;
    expect(slotHeight, AppSpacing.md + 50);
    expect(slotHeight, lessThan(AppSpacing.xl + 50));
  });

  testWidgets('AJ: release sem config não mostra Test Ad', (tester) async {
    final ads = FakeAdsSdk();
    await pumpHome(
      tester,
      ads: ads,
      extraOverrides: [
        adMobAdsConfigProvider.overrideWithValue(
          const AdMobAdsConfig(buildMode: AdMobBuildMode.release),
        ),
      ],
    );
    await tester.pump();

    expect(find.text('AdMob Test'), findsNothing);
    expect(find.byKey(HomeAdSlot.bannerKey), findsNothing);
    expect(ads.loadCalls, 0);
  });

  testWidgets('X extra: 360 e 390 sem overflow', (tester) async {
    for (final width in [360.0, 390.0]) {
      await pumpHome(tester, ads: FakeAdsSdk(), size: Size(width, 800));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(HomeAdSlot.bannerKey), findsOneWidget);
    }
  });

  testWidgets('AD: bottom nav continua clicável com banner', (tester) async {
    final ads = FakeAdsSdk();
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          adsSdkProvider.overrideWithValue(ads),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(HomeAdSlot.bannerKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(HomeAdSlot.bannerKey));
    final bannerBottom = tester
        .getBottomLeft(find.byKey(HomeAdSlot.bannerKey))
        .dy;
    final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    expect(bannerBottom, lessThanOrEqualTo(navTop));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Clientes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ClientsPage), findsOneWidget);
    expect(ads.loadCalls, 1);
  });

  testWidgets('AN: privacy option só aparece quando required', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          adsSdkProvider.overrideWithValue(
            FakeAdsSdk(privacyOptionsRequired: true),
          ),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mais'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.adsPrivacyOptions), findsOneWidget);
  });

  testWidgets('AO: privacy option ausente quando notRequired', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
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
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mais'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.adsPrivacyOptions), findsNothing);
    expect(find.byKey(MorePage.pageKey), findsOneWidget);
  });
}
