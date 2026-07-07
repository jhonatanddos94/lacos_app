import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_appointments_list.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_selector.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_error_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_fab.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_header.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_refresh_failed_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_refreshing_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_schedule_skeleton.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_form_bottom_sheet.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  static const _maxContentWidth = 560.0;
  static const _fabInset = AppSpacing.md;
  static const _fabClearance = 56.0 + _fabInset;

  late DateTime _selectedDay;
  var _isRefreshingAfterCreate = false;
  var _refreshAfterCreateFailed = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = normalizeAppointmentDate(DateTime.now());
  }

  DateTime get _normalizedSelectedDay => normalizeAppointmentDate(_selectedDay);

  AgendaDay get _selectedAgendaDay => AgendaDay.from(_selectedDay);

  List<DateTime> get _visibleDays {
    final start = _normalizedSelectedDay.subtract(const Duration(days: 3));
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  String get _selectedDayKey =>
      '${_selectedAgendaDay.year}-'
      '${_selectedAgendaDay.month}-'
      '${_selectedAgendaDay.day}';

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = normalizeAppointmentDate(day));
  }

  Future<void> _refreshAppointmentsForDay(AgendaDay day) async {
    await Future.wait([
      ref.refresh(agendaAppointmentsDisplayProvider(day).future),
      ref.refresh(appointmentsByDayProvider(day).future),
    ]);
  }

  Future<void> _openAppointmentDetails(
    AgendaAppointmentDisplay appointment,
  ) async {
    final canceledAppointment = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => AppointmentDetailsBottomSheet(
        appointmentId: appointment.appointmentId,
        day: appointment.startAt,
      ),
    );

    if (!mounted || canceledAppointment == null) return;

    final canceledDay = AgendaDay.from(canceledAppointment.startAt);

    try {
      await _refreshAppointmentsForDay(canceledDay);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.appointmentCancelSuccess)),
      );
    } on Object {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.agendaRefreshAfterCreateFailed),
        ),
      );
    }
  }

  Future<void> _openNewAppointment() async {
    final createdAppointment = await showModalBottomSheet<CreatedAppointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const AppointmentFormBottomSheet(),
    );

    if (!mounted || createdAppointment == null) return;

    final createdDay = AgendaDay.from(createdAppointment.appointment.startAt);

    if (!isSameAppointmentDate(createdDay.toDateTime(), _normalizedSelectedDay)) {
      setState(() => _selectedDay = createdDay.toDateTime());
    }

    setState(() {
      _isRefreshingAfterCreate = true;
      _refreshAfterCreateFailed = false;
    });

    try {
      await _refreshAppointmentsForDay(createdDay);
      if (!mounted) return;

      setState(() => _isRefreshingAfterCreate = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.appointmentCreatedSuccess)),
      );
    } on Object {
      if (!mounted) return;

      setState(() {
        _isRefreshingAfterCreate = false;
        _refreshAfterCreateFailed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.agendaRefreshAfterCreateFailed),
        ),
      );
    }
  }

  Future<void> _retryRefreshAfterCreate() async {
    setState(() {
      _isRefreshingAfterCreate = true;
      _refreshAfterCreateFailed = false;
    });

    try {
      await _refreshAppointmentsForDay(_selectedAgendaDay);
      if (!mounted) return;

      setState(() {
        _isRefreshingAfterCreate = false;
        _refreshAfterCreateFailed = false;
      });
    } on Object {
      if (!mounted) return;

      setState(() {
        _isRefreshingAfterCreate = false;
        _refreshAfterCreateFailed = true;
      });
    }
  }

  void _retryLoadAppointments() {
    if (_refreshAfterCreateFailed) {
      unawaited(_retryRefreshAfterCreate());
      return;
    }

    unawaited(_refreshAppointmentsForDay(_selectedAgendaDay));
  }

  String _appointmentsContentKey(
    AsyncValue<List<AgendaAppointmentDisplay>> appointmentsAsync,
  ) {
    if (_isRefreshingAfterCreate) {
      return 'refreshing-$_selectedDayKey';
    }

    if (_refreshAfterCreateFailed) {
      return 'refresh-failed-$_selectedDayKey';
    }

    return appointmentsAsync.when(
      loading: () => 'loading-$_selectedDayKey',
      error: (_, _) => 'error-$_selectedDayKey',
      data: (appointments) => appointments.isEmpty
          ? 'empty-$_selectedDayKey'
          : 'data-$_selectedDayKey-${appointments.length}',
    );
  }

  Widget _buildAppointmentsContent(
    AsyncValue<List<AgendaAppointmentDisplay>> appointmentsAsync,
  ) {
    if (_isRefreshingAfterCreate) {
      return AgendaRefreshingAfterCreateState(
        appointments: appointmentsAsync.value ?? const [],
        selectedDay: _normalizedSelectedDay,
        bottomPadding: _fabClearance,
        onAppointmentTap: _openAppointmentDetails,
      );
    }

    if (_refreshAfterCreateFailed) {
      return AgendaRefreshAfterCreateFailedState(
        appointments: appointmentsAsync.value ?? const [],
        selectedDay: _normalizedSelectedDay,
        bottomPadding: _fabClearance,
        onRetry: () => unawaited(_retryRefreshAfterCreate()),
        onAppointmentTap: _openAppointmentDetails,
      );
    }

    return appointmentsAsync.when(
      loading: () => AgendaSkeletonList(bottomPadding: _fabClearance),
      error: (error, _) => AgendaErrorState(
        message: resolveAgendaErrorMessage(error),
        onRetry: _retryLoadAppointments,
      ),
      data: (appointments) => AgendaAppointmentsList(
        appointments: appointments,
        selectedDay: _normalizedSelectedDay,
        bottomPadding: _fabClearance,
        onAppointmentTap: _openAppointmentDetails,
      ),
    );
  }

  Widget _buildAnimatedAppointmentsContent(
    AsyncValue<List<AgendaAppointmentDisplay>> appointmentsAsync,
  ) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(_appointmentsContentKey(appointmentsAsync)),
        child: _buildAppointmentsContent(appointmentsAsync),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(
      agendaAppointmentsDisplayProvider(_selectedAgendaDay),
    );

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: AgendaHeader(
                      selectedDay: _normalizedSelectedDay,
                      appointments: appointmentsAsync.value,
                      isLoading: _isRefreshingAfterCreate ||
                          (appointmentsAsync.isLoading &&
                              !appointmentsAsync.hasValue),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: AgendaDaySelector(
                      days: _visibleDays,
                      selectedDay: _normalizedSelectedDay,
                      onDaySelected: _selectDay,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: _buildAnimatedAppointmentsContent(appointmentsAsync),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AgendaFab(
            inset: _fabInset,
            onPressed: _openNewAppointment,
          ),
        ],
      ),
    );
  }
}
