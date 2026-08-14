import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/professional/presentation/pages/professional_profile_page.dart';
import 'package:lacos_app/features/salon/presentation/navigation/salon_navigation.dart';
import 'package:lacos_app/features/salon/presentation/pages/salon_page.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  setUp(() {
    resetProfessionalProfileNavigationGuardForTest();
    resetSalonNavigationGuardForTest();
  });
  tearDown(() {
    resetProfessionalProfileNavigationGuardForTest();
    resetSalonNavigationGuardForTest();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
    Size size = const Size(400, 900),
    TextScaler textScaler = TextScaler.noScaling,
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
            (ref, day) async => const [],
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          ...extraOverrides,
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1/2/3: avatar é clicável, abre Perfil e não abre Conta', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byKey(HomeHeader.profileAvatarKey), findsOneWidget);
    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProfessionalProfilePage), findsOneWidget);
    expect(find.text('Maria Santos'), findsWidgets);
    expect(find.text(AppStrings.logout), findsOneWidget);
    expect(find.text(AppStrings.comingSoon), findsNothing);
  });

  testWidgets('4/5: ícone direito é store_outlined e abre Salão', (tester) async {
    await pumpHome(tester);

    expect(find.byIcon(HomeHeader.salonHeaderIcon), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    expect(find.byIcon(Icons.account_circle_outlined), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);

    await tester.tap(find.byKey(HomeHeader.salonButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SalonPage), findsOneWidget);
    expect(find.text('Studio Aurora'), findsWidgets);
    expect(find.text(AppStrings.mySalon), findsWidgets);
  });

  testWidgets('6/7: semantics/tooltip de perfil e salão', (tester) async {
    await pumpHome(tester);

    expect(find.byTooltip(AppStrings.profile), findsOneWidget);
    expect(find.byTooltip(AppStrings.mySalon), findsOneWidget);

    final profileSemantics = tester.getSemantics(
      find.byKey(HomeHeader.profileAvatarKey),
    );
    expect(profileSemantics.label, AppStrings.profile);
    expect(profileSemantics.tooltip, AppStrings.profile);

    final salonSemantics = tester.getSemantics(
      find.byKey(HomeHeader.salonButtonKey),
    );
    expect(salonSemantics.label, AppStrings.mySalon);
    expect(salonSemantics.tooltip, AppStrings.mySalon);
  });

  testWidgets('8: touch targets do header >= 48', (tester) async {
    await pumpHome(tester);

    expect(
      tester.getSize(find.byKey(HomeHeader.profileAvatarKey)).shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(HomeHeader.salonButtonKey)).shortestSide,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('9/10: HomeHeader 320px e textScale 1.3 sem overflow', (
    tester,
  ) async {
    await pumpHome(
      tester,
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.byKey(HomeHeader.salonButtonKey), findsOneWidget);
  });

  testWidgets('HomeHeader 360px e textScale 1.5 sem overflow', (tester) async {
    await pumpHome(
      tester,
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(1.5),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(HomeHeader.salonButtonKey)).shortestSide,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('11: logout permanece no Perfil', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfessionalProfilePage.logoutButtonKey), findsOneWidget);
  });

  testWidgets('12: bottom sheet Conta não existe mais na Home', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.comingSoon), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeHeader.salonButtonKey));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.logout), findsNothing);
  });

  testWidgets('14: abrir perfil/salão não refaz fetch do workspace', (
    tester,
  ) async {
    var workspaceReads = 0;

    await pumpHome(
      tester,
      extraOverrides: [
        workspaceProvider.overrideWith((ref) async {
          workspaceReads++;
          return homeTestWorkspace();
        }),
      ],
    );

    final readsAfterHome = workspaceReads;

    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.pumpAndSettle();
    expect(workspaceReads, readsAfterHome);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeHeader.salonButtonKey));
    await tester.pumpAndSettle();
    expect(workspaceReads, readsAfterHome);
  });

  testWidgets('15: duplo toque no avatar não empilha dois perfis', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.tap(
      find.byKey(HomeHeader.profileAvatarKey),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ProfessionalProfilePage), findsOneWidget);
  });

  testWidgets('15: duplo toque no botão do salão não empilha dois salões', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeHeader.salonButtonKey));
    await tester.tap(
      find.byKey(HomeHeader.salonButtonKey),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SalonPage), findsOneWidget);
  });
}
