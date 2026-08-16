import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_provider_invalidation.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_form_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_form_bottom_sheet.dart';
import 'package:lacos_app/features/home/application/models/home_today_snapshot.dart';
import 'package:lacos_app/features/home/application/providers/home_operational_ticker_provider.dart';
import 'package:lacos_app/features/home/application/providers/home_providers.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/application/services/home_today_summary_formatter.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_attention_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_day_states.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_today_summary_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';
import 'package:lacos_app/features/monetization/presentation/widgets/home_ad_slot.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/salon/presentation/navigation/salon_navigation.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _isNavigating = false;

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_isNavigating) return;

    _isNavigating = true;
    try {
      await action();
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _openProfile() {
    return _runGuarded(() => openProfessionalProfile(context));
  }

  Future<void> _openSalon() {
    return _runGuarded(() => openSalonPage(context));
  }

  Future<void> _openNewAppointment() {
    return _runGuarded(() async {
      final today = ref.read(calendarTodayProvider).toDateTime();
      final created = await showModalBottomSheet<CreatedAppointment>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
        builder: (context) => AppointmentFormBottomSheet(initialDate: today),
      );

      if (!mounted || created == null) return;

      invalidateAppointmentAfterCreate(
        ref,
        clientId: created.appointment.clientId,
        day: created.appointment.startAt,
      );
    });
  }

  Future<void> _openNewClient() {
    return _runGuarded(() async {
      final created = await showModalBottomSheet<Client>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
        builder: (context) => const ClientFormBottomSheet(),
      );

      if (!mounted || created == null) return;

      ref.invalidate(clientsProvider);
    });
  }

  Future<void> _openAgendaToday() {
    return _runGuarded(() async {
      ref.read(appShellTabProvider.notifier).openAgendaToday();
    });
  }

  Future<void> _openAgendaOn(DateTime day) {
    return _runGuarded(() async {
      ref.read(appShellTabProvider.notifier).openAgendaOn(AgendaDay.from(day));
    });
  }

  Future<void> _openClientsSearch() {
    return _runGuarded(() async {
      ref.read(appShellTabProvider.notifier).openClientsSearch();
    });
  }

  Future<void> _openAppointment(AgendaAppointmentDisplay appointment) {
    return _runGuarded(() async {
      await openAgendaAppointmentFlow(
        context: context,
        appointment: appointment,
        now: ref.read(appClockProvider).now(),
      );
    });
  }

  Future<void> _openAttention(List<AgendaAppointmentDisplay> overdue) {
    if (overdue.length == 1) {
      return _openAppointment(overdue.first);
    }

    return _openAgendaToday();
  }

  Future<void> _refreshToday() {
    final today = ref.read(calendarTodayProvider);
    return Future.wait([
      ref.refresh(agendaAppointmentsDisplayProvider(today).future),
      ref.refresh(homeUpcomingDaysProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final dayState = ref.watch(homeTodaySnapshotProvider);
    final upcomingDaysState = ref.watch(homeUpcomingDaysProvider);
    final now = ref.watch(homeOperationalNowProvider);
    final today = ref.watch(calendarTodayProvider).toDateTime();

    final professionalName =
        workspaceState.valueOrNull?.professional?.name ??
        AppStrings.homeDefaultProfessionalName;
    final professionalPhotoUrl = workspaceState.valueOrNull?.professional?.photoUrl;
    final salonName =
        workspaceState.valueOrNull?.salon?.name ??
        AppStrings.homeDefaultSalonName;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshToday,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeader(
                    professionalName: professionalName,
                    professionalPhotoUrl: professionalPhotoUrl,
                    salonName: salonName,
                    now: now,
                    isLoading:
                        workspaceState.isLoading && !workspaceState.hasValue,
                    hasError:
                        workspaceState.hasError && !workspaceState.hasValue,
                    onRetry: workspaceState.hasError
                        ? () => ref.invalidate(workspaceProvider)
                        : null,
                    onProfileTap: _openProfile,
                    onSalonTap: _openSalon,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDayContent(dayState, now),
                  const SizedBox(height: AppSpacing.sm),
                  HomeQuickActionsSection(
                    onNewAppointment: _openNewAppointment,
                    onNewClient: _openNewClient,
                    onSearchClient: _openClientsSearch,
                  ),
                  if (upcomingDaysState.hasValue &&
                      upcomingDaysState.requireValue.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    HomeUpcomingDaysSection(
                      days: upcomingDaysState.requireValue,
                      today: today,
                      onOpenAgenda: _openAgendaToday,
                      onOpenDay: _openAgendaOn,
                    ),
                  ],
                  const HomeAdSlot(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayContent(
    AsyncValue<HomeTodaySnapshot> dayState,
    DateTime now,
  ) {
    if (dayState.hasValue) {
      final snapshot = dayState.requireValue;
      return _HomeDayContent(
        snapshot: snapshot,
        now: now,
        onOpenAgenda: _openAgendaToday,
        onNewAppointment: _openNewAppointment,
        onOpenNext: snapshot.nextAppointment == null
            ? null
            : () => _openAppointment(snapshot.nextAppointment!),
        onOpenAttention: () => _openAttention(snapshot.overdueAppointments),
      );
    }

    if (dayState.hasError) {
      return HomeDayErrorCard(
        onRetry: () {
          ref.invalidate(
            agendaAppointmentsDisplayProvider(ref.read(calendarTodayProvider)),
          );
        },
      );
    }

    return const HomeDayLoadingSkeleton();
  }
}

class _HomeDayContent extends StatelessWidget {
  const _HomeDayContent({
    required this.snapshot,
    required this.now,
    required this.onOpenAgenda,
    required this.onNewAppointment,
    required this.onOpenNext,
    required this.onOpenAttention,
  });

  final HomeTodaySnapshot snapshot;
  final DateTime now;
  final VoidCallback onOpenAgenda;
  final VoidCallback onNewAppointment;
  final VoidCallback? onOpenNext;
  final VoidCallback onOpenAttention;

  @override
  Widget build(BuildContext context) {
    final presentation = HomeTodaySummaryFormatter.format(
      totalCount: snapshot.totalCount,
      summary: snapshot.summary,
      nextUpcomingStartAt: snapshot.nextUpcomingAppointment?.startAt,
    );
    final nextAppointment = snapshot.nextAppointment;
    final overdueCount = snapshot.overdueAppointments.length;
    final onOpenNext = this.onOpenNext;
    final showNextCard = nextAppointment != null && onOpenNext != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeTodaySummarySection(
          presentation: presentation,
          onOpenAgenda: onOpenAgenda,
          onNewAppointment: onNewAppointment,
        ),
        if (showNextCard) ...[
          const SizedBox(height: AppSpacing.sm),
          HomeNextAppointmentCard(
            appointment: nextAppointment,
            now: now,
            onTap: onOpenNext,
          ),
        ],
        if (overdueCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          HomeAttentionSection(
            overdueCount: overdueCount,
            onTap: onOpenAttention,
          ),
        ],
      ],
    );
  }
}
