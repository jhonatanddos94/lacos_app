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
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_day_status.dart';
import 'package:lacos_app/features/agenda/application/organizers/agenda_display_organizer.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_list_entries_builder.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_appointment_highlight_controller.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_appointment_scroll.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_appointments_list.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_sheet_host.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_selector.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_error_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_fab.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_header.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_refresh_failed_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_refreshing_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_schedule_skeleton.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_provider_invalidation.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_flow_result.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_form_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_memory_flow.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  static const _maxContentWidth = 560.0;
  static const _fabInset = AppSpacing.md;
  static const _fabHeight = 56.0;
  static const _fabScrollClearance = _fabHeight + (_fabInset * 2);

  late DateTime _selectedDay;
  var _isRefreshingAfterCreate = false;
  var _refreshAfterCreateFailed = false;
  final _appointmentsScrollController = ScrollController();
  final _createdAppointmentHighlight = AgendaAppointmentHighlightController();

  @override
  void initState() {
    super.initState();
    _selectedDay = normalizeAppointmentDate(DateTime.now());
  }

  @override
  void dispose() {
    _appointmentsScrollController.dispose();
    _createdAppointmentHighlight.dispose();
    super.dispose();
  }

  DateTime get _normalizedSelectedDay => normalizeAppointmentDate(_selectedDay);

  AgendaDay get _selectedAgendaDay => AgendaDay.from(_selectedDay);

  bool get _isOperationalDay => isOperationalAgendaDay(_normalizedSelectedDay);

  double get _scrollBottomPadding =>
      _isOperationalDay ? _fabScrollClearance : AppSpacing.md;

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

  Future<void> _openCalendar() async {
    final selectedDate = await showAgendaCalendarSheet(
      context: context,
      initialDate: _normalizedSelectedDay,
    );

    if (!mounted || selectedDate == null) return;

    _selectDay(selectedDate);
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
    final originalDay = AgendaDay.from(appointment.startAt);

    final updatedResult = await openAgendaAppointmentFlow(
      context: context,
      ref: ref,
      appointment: appointment,
    );

    if (!mounted || updatedResult == null) return;

    if (updatedResult is CompleteAppointmentFlowResult) {
      await _handleCompletedAppointmentFlow(updatedResult);
      return;
    }

    if (updatedResult is! Appointment) return;

    final updatedAppointment = updatedResult;

    final updatedDay = AgendaDay.from(updatedAppointment.startAt);

    if (updatedAppointment.status == AppointmentStatus.completed) {
      await _handleAppointmentStatusChange(day: updatedDay);
      return;
    }

    if (updatedAppointment.status == AppointmentStatus.canceled) {
      await _handleAppointmentStatusChange(
        day: updatedDay,
        message: AppStrings.appointmentCancelSuccess,
      );
      return;
    }

    await _handleAppointmentUpdated(
      originalDay: originalDay,
      updatedAppointment: updatedAppointment,
    );
  }

  Future<void> _handleCompletedAppointmentFlow(
    CompleteAppointmentFlowResult result,
  ) async {
    final updatedDay = AgendaDay.from(result.appointment.startAt);

    try {
      await _refreshAppointmentsForDay(updatedDay);
      if (!mounted) return;

      await handleCompleteAppointmentMemoryFlow(
        context: context,
        ref: ref,
        result: result,
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

  Future<void> _handleAppointmentStatusChange({
    required AgendaDay day,
    String? message,
  }) async {
    try {
      await _refreshAppointmentsForDay(day);
      if (!mounted) return;

      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } on Object {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.agendaRefreshAfterCreateFailed),
        ),
      );
    }
  }

  Future<void> _handleAppointmentUpdated({
    required AgendaDay originalDay,
    required Appointment updatedAppointment,
  }) async {
    final updatedDay = AgendaDay.from(updatedAppointment.startAt);

    if (!isSameAppointmentDate(
      updatedDay.toDateTime(),
      _normalizedSelectedDay,
    )) {
      setState(() => _selectedDay = updatedDay.toDateTime());
    }

    setState(() {
      _isRefreshingAfterCreate = true;
      _refreshAfterCreateFailed = false;
    });

    try {
      invalidateAppointmentAfterUpdate(
        ref,
        appointmentId: updatedAppointment.id,
        updatedDay: updatedAppointment.startAt,
        originalDay: originalDay.toDateTime(),
      );

      await _refreshAppointmentsForDays([originalDay, updatedDay]);
      if (!mounted) return;

      setState(() => _isRefreshingAfterCreate = false);

      final refreshedAppointments =
          ref.read(agendaAppointmentsDisplayProvider(updatedDay)).value ??
          const <AgendaAppointmentDisplay>[];
      final entries = AgendaListEntriesBuilder.build(
        AgendaDisplayOrganizer.organize(refreshedAppointments),
      );
      final updatedIndex = AgendaListEntriesBuilder.indexForAppointmentId(
        entries,
        updatedAppointment.id,
      );

      _createdAppointmentHighlight.applyHighlight(
        appointmentId: updatedAppointment.id,
        onChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
      );

      if (updatedIndex != null) {
        AgendaAppointmentScroll.animateToAppointmentIndex(
          scrollController: _appointmentsScrollController,
          index: updatedIndex,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.appointmentUpdatedSuccess)),
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

  Future<void> _refreshAppointmentsForDays(List<AgendaDay> days) async {
    final uniqueDays = <String, AgendaDay>{};
    for (final day in days) {
      uniqueDays['${day.year}-${day.month}-${day.day}'] = day;
    }

    await Future.wait(
      uniqueDays.values.expand(
        (day) => [
          ref.refresh(agendaAppointmentsDisplayProvider(day).future),
          ref.refresh(appointmentsByDayProvider(day).future),
        ],
      ),
    );
  }

  Future<void> _openNewAppointment() async {
    if (!_isOperationalDay) return;

    final createdAppointment = await showModalBottomSheet<CreatedAppointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) =>
          AppointmentFormBottomSheet(initialDate: _normalizedSelectedDay),
    );

    if (!mounted || createdAppointment == null) return;

    final createdDay = AgendaDay.from(createdAppointment.appointment.startAt);

    if (!isSameAppointmentDate(
      createdDay.toDateTime(),
      _normalizedSelectedDay,
    )) {
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

      final refreshedAppointments =
          ref.read(agendaAppointmentsDisplayProvider(createdDay)).value ??
          const <AgendaAppointmentDisplay>[];
      final entries = AgendaListEntriesBuilder.build(
        AgendaDisplayOrganizer.organize(refreshedAppointments),
      );
      final createdIndex = AgendaListEntriesBuilder.indexForAppointmentId(
        entries,
        createdAppointment.appointment.id,
      );

      _createdAppointmentHighlight.applyHighlight(
        appointmentId: createdAppointment.appointment.id,
        onChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
      );

      if (createdIndex != null) {
        AgendaAppointmentScroll.animateToAppointmentIndex(
          scrollController: _appointmentsScrollController,
          index: createdIndex,
        );
      }

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
        scrollBottomPadding: _scrollBottomPadding,
        onAppointmentTap: _openAppointmentDetails,
      );
    }

    if (_refreshAfterCreateFailed) {
      return AgendaRefreshAfterCreateFailedState(
        appointments: appointmentsAsync.value ?? const [],
        selectedDay: _normalizedSelectedDay,
        scrollBottomPadding: _scrollBottomPadding,
        onRetry: () => unawaited(_retryRefreshAfterCreate()),
        onAppointmentTap: _openAppointmentDetails,
      );
    }

    return appointmentsAsync.when(
      loading: () =>
          AgendaSkeletonList(scrollBottomPadding: _scrollBottomPadding),
      error: (error, _) => AgendaErrorState(
        message: resolveAgendaErrorMessage(error),
        onRetry: _retryLoadAppointments,
      ),
      data: (appointments) => AgendaAppointmentsList(
        appointments: appointments,
        selectedDay: _normalizedSelectedDay,
        scrollBottomPadding: _scrollBottomPadding,
        isPastDay: !_isOperationalDay,
        highlightedAppointmentId:
            _createdAppointmentHighlight.highlightedAppointmentId,
        scrollController: _appointmentsScrollController,
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
                      isLoading:
                          _isRefreshingAfterCreate ||
                          (appointmentsAsync.isLoading &&
                              !appointmentsAsync.hasValue),
                      isPastDay: !_isOperationalDay,
                      onCalendarPressed: _openCalendar,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  bottom: AppSpacing.sm,
                ),
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
                      child: _buildAnimatedAppointmentsContent(
                        appointmentsAsync,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isOperationalDay)
            Positioned(
              right: _fabInset,
              bottom: MediaQuery.paddingOf(context).bottom + _fabInset,
              child: AgendaFab(onPressed: _openNewAppointment),
            ),
        ],
      ),
    );
  }
}
