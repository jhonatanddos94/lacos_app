import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_attention_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_day_states.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_today_summary_section.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  Future<void> pumpHome(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          ...overrides,
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
  }

  List<Override> dayOverrides(
    Future<List<AgendaAppointmentDisplay>> Function() load,
  ) {
    return [
      workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
      agendaAppointmentsDisplayProvider.overrideWith((ref, day) => load()),
    ];
  }

  testWidgets('workspace loading não bloqueia a Home inteira', (tester) async {
    final completer = Completer<List<AgendaAppointmentDisplay>>();

    await pumpHome(
      tester,
      overrides: [
        workspaceProvider.overrideWith((ref) => Completer<Workspace?>().future),
        agendaAppointmentsDisplayProvider.overrideWith(
          (ref, day) => completer.future,
        ),
      ],
    );
    await tester.pump();

    expect(find.byKey(HomeHeader.headerSkeletonKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(HomeDayLoadingSkeleton.skeletonKey), findsOneWidget);

    completer.complete(const []);
    await tester.pump();
    await tester.pump();

    expect(find.text(AppStrings.homeAgendaFreeToday), findsOneWidget);
    expect(find.byKey(HomeHeader.headerSkeletonKey), findsOneWidget);
  });

  testWidgets('header usa profissional e salão reais', (tester) async {
    await pumpHome(tester, overrides: dayOverrides(() async => const []));
    await tester.pumpAndSettle();

    expect(find.textContaining('Maria'), findsOneWidget);
    expect(find.text('Studio Aurora'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('erro de workspace não mostra stack trace', (tester) async {
    await pumpHome(
      tester,
      overrides: [
        workspaceProvider.overrideWith((ref) async {
          throw StateError('workspace-fail');
        }),
        agendaAppointmentsDisplayProvider.overrideWith(
          (ref, day) async => const [],
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Profissional'), findsOneWidget);
    expect(find.text(AppStrings.homeAgendaFreeToday), findsOneWidget);
    expect(find.textContaining('workspace-fail'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.byKey(HomeHeader.retryButtonKey), findsOneWidget);
  });

  testWidgets('day loading mostra skeleton e preserva header', (tester) async {
    final completer = Completer<List<AgendaAppointmentDisplay>>();

    await pumpHome(
      tester,
      overrides: [
        workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
        agendaAppointmentsDisplayProvider.overrideWith(
          (ref, day) => completer.future,
        ),
      ],
    );
    await tester.pump();

    expect(find.textContaining('Maria'), findsOneWidget);
    expect(find.byKey(HomeDayLoadingSkeleton.skeletonKey), findsOneWidget);
    expect(find.text('Ana Paula Silva'), findsNothing);

    completer.complete(const []);
    await tester.pump();
    await tester.pump();
  });

  testWidgets('day error mostra retry local e mantém ações rápidas', (
    tester,
  ) async {
    await pumpHome(
      tester,
      overrides: [
        workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
        agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
          throw StateError('day-fail');
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeDayLoadError), findsOneWidget);
    expect(find.textContaining('day-fail'), findsNothing);
    expect(find.byKey(HomeDayErrorCard.retryKey), findsOneWidget);
    expect(find.text(AppStrings.homeQuickActionsTitle), findsOneWidget);
  });

  testWidgets('dia vazio mostra agenda livre sem zeros', (tester) async {
    await pumpHome(tester, overrides: dayOverrides(() async => const []));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeAgendaFreeToday), findsOneWidget);
    expect(find.text(AppStrings.homeEmptyDayDescription), findsOneWidget);
    expect(find.text(AppStrings.homeNewAppointmentCta), findsOneWidget);
    expect(
      find.text('0 concluídos • 0 em andamento • 0 próximos'),
      findsNothing,
    );
    expect(find.text(AppStrings.homeNoNextAppointment), findsNothing);
    expect(find.byKey(HomeNextAppointmentEmpty.sectionKey), findsNothing);
    expect(find.byKey(HomeAttentionSection.sectionKey), findsNothing);
  });

  testWidgets('renderiza próximo real e current', (tester) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'current',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 13, 30),
            servicesSummary: 'Hidratação',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
    expect(find.text(AppStrings.homeInProgressTitle), findsOneWidget);
    expect(find.text('Josefa'), findsOneWidget);
    expect(find.text('Hidratação'), findsOneWidget);
    expect(find.text('13:30'), findsOneWidget);
    expect(
      find.text(AppStrings.appointmentOperationalStateCurrentLabel),
      findsOneWidget,
    );
    expect(find.text(AppStrings.homeNoNextAppointment), findsNothing);
    expect(find.byKey(HomeNextAppointmentEmpty.sectionKey), findsNothing);
  });

  testWidgets('overdue aparece na atenção', (tester) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'overdue',
            clientName: 'Atrasada',
            startAt: DateTime(2026, 8, 13, 10, 0),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeAttentionSection.sectionKey), findsOneWidget);
    expect(find.text('1 atendimento aguardando conclusão'), findsOneWidget);
    expect(find.text(AppStrings.homeNoNextAppointment), findsNothing);
    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsNothing);
  });

  testWidgets('sem overdue a seção de atenção não aparece', (tester) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'upcoming',
            clientName: 'Bia',
            startAt: DateTime(2026, 8, 13, 16, 0),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeAttentionSection.sectionKey), findsNothing);
    expect(find.text('Bia'), findsOneWidget);
    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
    expect(find.text(AppStrings.homeNextAppointmentTitle), findsOneWidget);
    expect(find.text(AppStrings.homeNoNextAppointment), findsNothing);
  });

  testWidgets('nenhum texto mock antigo aparece', (tester) async {
    await pumpHome(tester, overrides: dayOverrides(() async => const []));
    await tester.pumpAndSettle();

    expect(find.text('Ana Paula Silva'), findsNothing);
    expect(find.textContaining('Prefere café'), findsNothing);
    expect(find.textContaining('aniversário'), findsNothing);
    expect(find.textContaining('Registrar'), findsNothing);
    expect(find.text('RESUMO DO SALÃO'), findsNothing);
    expect(find.text('AGENDA DE HOJE'), findsNothing);
    expect(find.text('Juliana Mendes'), findsNothing);
    expect(find.byKey(HomeTodaySummarySection.sectionKey), findsOneWidget);
  });

  testWidgets('completed não vira próximo atendimento', (tester) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'completed',
            clientName: 'Feita',
            startAt: DateTime(2026, 8, 13, 9, 0),
            status: AppointmentStatus.completed,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feita'), findsNothing);
    expect(find.text(AppStrings.homeNoNextAppointment), findsNothing);
    expect(find.byKey(HomeNextAppointmentEmpty.sectionKey), findsNothing);
    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsNothing);
    expect(find.text(AppStrings.homeTodayFinishedTitle), findsOneWidget);
    expect(find.text('1 atendimento concluído'), findsOneWidget);
    expect(find.text(AppStrings.homeAgendaFreeToday), findsNothing);
  });

  testWidgets('concluído e cancelado sem próximo mostram estado compacto', (
    tester,
  ) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'completed',
            clientName: 'Feita',
            startAt: DateTime(2026, 8, 13, 9, 0),
            status: AppointmentStatus.completed,
          ),
          homeTestAppointment(
            id: 'canceled',
            clientName: 'Cancelada',
            startAt: DateTime(2026, 8, 13, 11, 0),
            status: AppointmentStatus.canceled,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 atendimento concluído'), findsOneWidget);
    expect(find.text('1 cancelado'), findsOneWidget);
    expect(find.text(AppStrings.homeNoNextAppointment), findsNothing);
    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsNothing);
    expect(find.text(AppStrings.homeAgendaFreeToday), findsNothing);
    expect(find.text(AppStrings.homeEmptyDayDescription), findsNothing);
  });

  testWidgets('ações rápidas mostram labels completos', (tester) async {
    await pumpHome(tester, overrides: dayOverrides(() async => const []));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeQuickActionNewAppointment), findsOneWidget);
    expect(find.text(AppStrings.homeQuickActionNewClient), findsOneWidget);
    expect(find.text(AppStrings.homeQuickActionSearchClient), findsOneWidget);
    expect(find.text('Ver agenda'), findsNothing);
    expect(find.text('Novo\nagendamento'), findsNothing);
    expect(
      find.byKey(HomeQuickActionsSection.newAppointmentKey),
      findsOneWidget,
    );
    expect(find.byKey(HomeQuickActionsSection.newClientKey), findsOneWidget);
    expect(find.byKey(HomeQuickActionsSection.searchClientKey), findsOneWidget);
  });

  testWidgets('ações rápidas cabem em tela estreita sem overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          ...dayOverrides(() async => const []),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.homeQuickActionNewAppointment), findsOneWidget);
    expect(find.text(AppStrings.homeQuickActionNewClient), findsOneWidget);
    expect(find.text(AppStrings.homeQuickActionSearchClient), findsOneWidget);
    expect(find.text(AppStrings.homeEmptyDayDescription), findsOneWidget);
  });

  testWidgets('vários upcoming mostram somente um card operacional', (
    tester,
  ) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'first',
            clientName: 'Bia',
            startAt: DateTime(2026, 8, 13, 16, 0),
          ),
          homeTestAppointment(
            id: 'second',
            clientName: 'Carla',
            startAt: DateTime(2026, 8, 13, 17, 0),
          ),
          homeTestAppointment(
            id: 'third',
            clientName: 'Duda',
            startAt: DateTime(2026, 8, 13, 18, 0),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('Carla'), findsNothing);
    expect(find.text('Duda'), findsNothing);
  });

  testWidgets('current vence upcoming no card operacional', (tester) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          homeTestAppointment(
            id: 'upcoming',
            clientName: 'Bia',
            startAt: DateTime(2026, 8, 13, 16, 0),
          ),
          homeTestAppointment(
            id: 'current',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 13, 30),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
    expect(find.text(AppStrings.homeInProgressTitle), findsOneWidget);
    expect(find.text('Josefa'), findsOneWidget);
    expect(find.text('Bia'), findsNothing);
  });

  testWidgets('dez appointments não criam lista na Home', (tester) async {
    await pumpHome(
      tester,
      overrides: dayOverrides(
        () async => [
          for (var index = 0; index < 10; index++)
            homeTestAppointment(
              id: 'apt-$index',
              clientName: 'Cliente $index',
              startAt: DateTime(2026, 8, 13, 15, index),
            ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
    expect(find.text('Cliente 0'), findsOneWidget);
    expect(find.text('10 atendimentos hoje'), findsOneWidget);
    expect(find.text('Cliente 9'), findsNothing);
  });

  testWidgets('ações rápidas cabem em 320px com textScale 1.0', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          ...dayOverrides(() async => const []),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.homeQuickActionSearchClient), findsOneWidget);
  });
}
