import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details_query.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_provider_invalidation.dart';
import 'package:lacos_app/features/appointments/application/models/updated_appointment.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_details_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_operational_state_resolver.dart';
import 'package:lacos_app/features/appointments/presentation/appointment_form_mode.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_form_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/dialogs/appointment_cancel_dialog.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_flow_result.dart';
import 'package:lacos_app/features/appointments/presentation/dialogs/complete_appointment_dialog.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_success_sheet_host.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_presentation_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_operational_badge_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_operational_badge_chip.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_service_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_highlights_card.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class AppointmentDetailsBottomSheet extends ConsumerStatefulWidget {
  const AppointmentDetailsBottomSheet({
    required this.appointmentId,
    required this.day,
    super.key,
  });

  final String appointmentId;
  final DateTime day;

  @override
  ConsumerState<AppointmentDetailsBottomSheet> createState() =>
      _AppointmentDetailsBottomSheetState();
}

class _AppointmentDetailsBottomSheetState
    extends ConsumerState<AppointmentDetailsBottomSheet> {
  String? _cancelError;
  String? _completeError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cancelAppointmentControllerProvider.notifier).reset();
      ref.read(completeAppointmentControllerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(
      appointmentDetailsProvider(
        AppointmentDetailsQuery(
          appointmentId: widget.appointmentId,
          day: widget.day,
        ),
      ),
    );
    final isCanceling = ref
        .watch(cancelAppointmentControllerProvider)
        .isLoading;
    final isCompleting = ref
        .watch(completeAppointmentControllerProvider)
        .isLoading;
    final isBusy = isCanceling || isCompleting;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            const AppointmentBottomSheetHandle(),
            Flexible(
              child: detailsAsync.when(
                loading: () => const _AppointmentDetailsLoading(),
                error: (_, _) => _AppointmentDetailsError(
                  onRetry: () => ref.invalidate(
                    appointmentDetailsProvider(
                      AppointmentDetailsQuery(
                        appointmentId: widget.appointmentId,
                        day: widget.day,
                      ),
                    ),
                  ),
                ),
                data: (details) => _AppointmentDetailsContent(
                  details: details,
                  isBusy: isBusy,
                  cancelError: _cancelError,
                  completeError: _completeError,
                  onEdit: details.appointment.status.canBeEdited && !isBusy
                      ? () => _openEditAppointment(context, details)
                      : null,
                  onComplete:
                      details.appointment.status.canBeCompleted && !isBusy
                      ? () => _confirmCompleteAppointment(details)
                      : null,
                  onCancel: details.appointment.status.canBeCanceled && !isBusy
                      ? () => _confirmCancelAppointment(details)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCompleteAppointment(AppointmentDetails details) async {
    if (!details.appointment.status.canBeCompleted) {
      return;
    }

    if (details.services.isEmpty) {
      _showMessage(AppStrings.appointmentCompleteServicesUnavailable);
      return;
    }

    setState(() => _completeError = null);

    ref.read(completeAppointmentControllerProvider.notifier)
      ..reset()
      ..setServices(mapPlannedServicesToCompletedParams(details.services));

    final serviceRecord = await showDialog<ServiceRecord>(
      context: context,
      builder: (context) => CompleteAppointmentDialog(
        appointmentId: details.appointment.id,
        clientName: details.client.name,
        services: details.services,
      ),
    );

    if (!mounted) return;

    if (serviceRecord != null) {
      invalidateAppointmentAfterCompletion(
        ref,
        appointmentId: details.appointment.id,
        clientId: details.client.id,
        day: details.appointment.startAt,
      );
      ref.invalidate(clientMemoriesProvider(details.client.id));
      ref
          .read(appointmentMemoryUsageProvider(details.appointment.id).notifier)
          .clear();

      final successAction = await showCompleteAppointmentSuccessBottomSheet(
        context: context,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        CompleteAppointmentFlowResult(
          appointment: _completedAppointmentFrom(details),
          successAction: successAction,
        ),
      );
      return;
    }

    final errorMessage = ref
        .read(completeAppointmentControllerProvider)
        .errorMessage;
    if (errorMessage == null) return;

    setState(() {
      _completeError = errorMessage;
    });
  }

  Appointment _completedAppointmentFrom(AppointmentDetails details) {
    final appointment = details.appointment;
    final now = DateTime.now();

    return Appointment(
      id: appointment.id,
      salonId: appointment.salonId,
      ownerId: appointment.ownerId,
      clientId: appointment.clientId,
      professionalId: appointment.professionalId,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      status: AppointmentStatus.completed,
      notes: appointment.notes,
      completedAt: now,
      isActive: appointment.isActive,
      createdAt: appointment.createdAt,
      updatedAt: now,
    );
  }

  Future<void> _confirmCancelAppointment(AppointmentDetails details) async {
    if (!details.appointment.status.canBeCanceled) {
      if (details.appointment.status == AppointmentStatus.completed) {
        _showMessage(AppStrings.appointmentCannotCancelCompleted);
      }
      return;
    }

    setState(() => _cancelError = null);
    ref.read(cancelAppointmentControllerProvider.notifier).reset();

    final canceledAppointment = await showDialog<Appointment>(
      context: context,
      builder: (context) => AppointmentCancelDialog(
        appointmentId: details.appointment.id,
        clientName: details.client.name,
      ),
    );

    if (!mounted) return;

    if (canceledAppointment != null) {
      Navigator.of(context).pop(canceledAppointment);
      return;
    }

    if (!mounted) return;

    final errorMessage = ref
        .read(cancelAppointmentControllerProvider)
        .errorMessage;
    if (errorMessage == null) return;

    setState(() {
      _cancelError = errorMessage;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEditAppointment(
    BuildContext context,
    AppointmentDetails details,
  ) async {
    if (!details.appointment.status.canBeEdited) {
      _showMessage(AppStrings.appointmentCannotEdit);
      return;
    }

    final appointment = details.appointment;
    final query = AppointmentDetailsQuery(
      appointmentId: appointment.id,
      day: appointment.startAt,
    );

    invalidateAppointmentDetailsProviders(
      ref,
      appointmentId: appointment.id,
      day: appointment.startAt,
    );

    late AppointmentDetails freshDetails;
    try {
      freshDetails = await ref.read(appointmentDetailsProvider(query).future);
    } on Object {
      if (!mounted) return;
      _showMessage(AppStrings.appointmentDetailsLoadError);
      return;
    }

    if (freshDetails.services.isEmpty) {
      _showMessage(AppStrings.appointmentEditServicesUnavailable);
      return;
    }

    if (!mounted) return;
    if (!context.mounted) return;

    final updatedAppointment = await showModalBottomSheet<UpdatedAppointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => AppointmentFormBottomSheet(
        mode: AppointmentFormMode.edit,
        initialData: freshDetails,
      ),
    );

    if (!mounted) return;

    if (updatedAppointment != null) {
      invalidateAppointmentAfterUpdate(
        ref,
        appointmentId: updatedAppointment.appointment.id,
        updatedDay: updatedAppointment.appointment.startAt,
        originalDay: appointment.startAt,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(updatedAppointment.appointment);
    }
  }
}

class _AppointmentDetailsLoading extends StatelessWidget {
  const _AppointmentDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AppointmentDetailsError extends StatelessWidget {
  const _AppointmentDetailsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.appointmentDetailsLoadError,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: AppStrings.tryAgain,
            variant: AppButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailsContent extends StatelessWidget {
  const _AppointmentDetailsContent({
    required this.details,
    this.onEdit,
    this.onCancel,
    this.onComplete,
    this.isBusy = false,
    this.cancelError,
    this.completeError,
  });

  final AppointmentDetails details;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final bool isBusy;
  final String? cancelError;
  final String? completeError;

  static const _presentationMapper = AppointmentPresentationMapper();
  static const _badgeMapper = AppointmentOperationalBadgeMapper();
  static const _operationalStateResolver =
      AppointmentOperationalStateResolver();

  bool get _isReadOnly =>
      !details.appointment.status.canBeEdited &&
      !details.appointment.status.canBeCompleted &&
      !details.appointment.status.canBeCanceled;

  bool _shouldShowMemoryHighlights(AppointmentStatus status) {
    return status != AppointmentStatus.completed &&
        status != AppointmentStatus.canceled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointment = details.appointment;
    final notes = details.notes?.trim();
    final servicesSummary = _ServicesSummary.from(details.services);
    final durationLabel = formatAppointmentDuration(
      appointment.startAt,
      appointment.endAt,
    );
    final professionalLine = _buildProfessionalLine(details);
    final operationalState = _operationalStateResolver.resolve(
      status: appointment.status,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      now: DateTime.now(),
    );
    final showOverdueBanner =
        operationalState == AppointmentOperationalState.overdue;
    final badgePresentation = _badgeMapper.resolve(
      operationalState: operationalState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.appointmentDetailsTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showOverdueBanner) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _OperationalOverdueBanner(endAt: appointment.endAt),
                ],
                const SizedBox(height: AppSpacing.sm),
                _ClientHeroCard(
                  clientName: details.client.name,
                  photoUrl: details.client.photoUrl,
                  dateLabel: formatAppointmentDateLabel(appointment.startAt),
                  timeRange:
                      '${formatAppointmentClockTime(appointment.startAt)} – '
                      '${formatAppointmentClockTime(appointment.endAt)}',
                  durationLabel: durationLabel,
                  badgePresentation: badgePresentation,
                ),
                if (_shouldShowMemoryHighlights(appointment.status)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _AppointmentMemoryHighlightsSection(
                    clientId: details.client.id,
                    appointmentId: appointment.id,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _CompactMetaLine(text: professionalLine),
                if (servicesSummary.hasPrice) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  _CompactMetaLine(
                    text: _buildTotalValueLine(
                      servicesSummary,
                      operationalState: operationalState,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _SectionLabel(title: AppStrings.appointmentServiceSection),
                const SizedBox(height: AppSpacing.xxxs),
                _CompactSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var index = 0;
                        index < details.services.length;
                        index++
                      ) ...[
                        if (index > 0)
                          Divider(
                            height: AppSpacing.sm,
                            thickness: 1,
                            color: AppColors.divider.withValues(alpha: 0.55),
                          ),
                        _ServiceRow(service: details.services[index]),
                      ],
                      if (servicesSummary.hasData) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.divider.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _ServicesTotalRow(summary: servicesSummary),
                      ],
                    ],
                  ),
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CompactNotesBlock(notes: notes),
                ],
                if (details.appointment.status ==
                    AppointmentStatus.canceled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CancellationDetailsBlock(appointment: details.appointment),
                ],
              ],
            ),
          ),
        ),
        if (!_isReadOnly || cancelError != null || completeError != null)
          _DetailsActionsFooter(
            onEdit: onEdit,
            onComplete: onComplete,
            onCancel: onCancel,
            isBusy: isBusy,
            cancelError: cancelError,
            completeError: completeError,
            showEditButton: details.appointment.status.canBeEdited,
          ),
      ],
    );
  }

  String _buildProfessionalLine(AppointmentDetails details) {
    final name = details.professional.name;
    final subtitle = _professionalSubtitle(details);

    final value = subtitle != null && subtitle.isNotEmpty
        ? '$name • $subtitle'
        : name;

    return '${AppStrings.appointmentProfessionalSection}: $value';
  }

  String _buildTotalValueLine(
    _ServicesSummary summary, {
    required AppointmentOperationalState operationalState,
  }) {
    return '${_presentationMapper.estimatedTotalPrefix(status: details.appointment.status, operationalState: operationalState)} ${formatServicePrice(summary.totalPrice)}';
  }

  String? _professionalSubtitle(AppointmentDetails details) {
    final specialties = details.professional.specialties?.trim();
    if (specialties != null && specialties.isNotEmpty) {
      return specialties;
    }

    final role = details.professional.role?.trim();
    if (role != null && role.isNotEmpty) {
      return role;
    }

    return null;
  }
}

class _ClientHeroCard extends StatelessWidget {
  const _ClientHeroCard({
    required this.clientName,
    required this.dateLabel,
    required this.timeRange,
    required this.durationLabel,
    required this.badgePresentation,
    this.photoUrl,
  });

  final String clientName;
  final String? photoUrl;
  final String dateLabel;
  final String timeRange;
  final String durationLabel;
  final AppointmentOperationalBadgePresentation badgePresentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleParts = [
      dateLabel,
      timeRange,
      if (durationLabel.isNotEmpty) durationLabel,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.purple100),
        boxShadow: AppShadows.level1,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClientAvatar(
            name: clientName,
            photoUrl: photoUrl,
            radius: 22,
            backgroundColor: AppColors.purple100,
            initialTextStyle: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.purple800,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.lacosPurple,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: AppSpacing.xxxs,
                  runSpacing: AppSpacing.xxxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      scheduleParts.join(' • '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    AppointmentOperationalBadgeChip(
                      presentation: badgePresentation,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetaLine extends StatelessWidget {
  const _CompactMetaLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.graphite,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = formatServiceDetails(
      durationMinutes: service.durationMinutes,
      price: service.price,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          service.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            details,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.15,
            ),
          ),
        ],
      ],
    );
  }
}

class _ServicesSummary {
  const _ServicesSummary({
    required this.totalDurationMinutes,
    required this.totalPrice,
    required this.hasPrice,
  });

  final int totalDurationMinutes;
  final double totalPrice;
  final bool hasPrice;

  bool get hasData => totalDurationMinutes > 0 || (hasPrice && totalPrice > 0);

  factory _ServicesSummary.from(List<Service> services) {
    var totalDuration = 0;
    double? totalPrice;
    var hasAnyPrice = false;

    for (final service in services) {
      final duration = service.durationMinutes;
      if (duration != null && duration > 0) {
        totalDuration += duration;
      }

      final price = service.price;
      if (price != null) {
        hasAnyPrice = true;
        totalPrice = (totalPrice ?? 0) + price;
      }
    }

    return _ServicesSummary(
      totalDurationMinutes: totalDuration,
      totalPrice: totalPrice ?? 0,
      hasPrice: hasAnyPrice,
    );
  }

  String buildLabel() {
    final parts = <String>[];

    if (totalDurationMinutes > 0) {
      parts.add(formatServiceDuration(totalDurationMinutes));
    }

    if (hasPrice) {
      parts.add(formatServicePrice(totalPrice));
    }

    return parts.join(' • ');
  }
}

class _ServicesTotalRow extends StatelessWidget {
  const _ServicesTotalRow({required this.summary});

  final _ServicesSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLabel = AppStrings.appointmentDetailsTotalPrefix.replaceAll(
      ':',
      '',
    );

    return Row(
      children: [
        Text(
          totalLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          summary.buildLabel(),
          textAlign: TextAlign.right,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _OperationalOverdueBanner extends StatelessWidget {
  const _OperationalOverdueBanner({required this.endAt});

  final DateTime endAt;

  static const _presentationMapper = AppointmentPresentationMapper();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relativeTime = _presentationMapper.overdueBannerRelativeTime(
      endAt: endAt,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: const Color(0xFFE8C9A0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _presentationMapper.overdueBannerMessage(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (relativeTime != null) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              relativeTime,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.88),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CancellationDetailsBlock extends StatelessWidget {
  const _CancellationDetailsBlock({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canceledByLabel = formatAppointmentCanceledByLabel(
      appointment.canceledBy,
    );
    final reasonText = formatAppointmentCancellationReasonDisplay(
      appointment.cancellationReason,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F4),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canceledByLabel != null)
            Text(
              canceledByLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          if (canceledByLabel != null) const SizedBox(height: AppSpacing.xxxs),
          Text(
            reasonText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactNotesBlock extends StatelessWidget {
  const _CompactNotesBlock({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.purple50.withValues(alpha: 0.55),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.purple100.withValues(alpha: 0.85)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: AppIconSizes.sm * 0.75,
            color: AppColors.purple700,
          ),
          const SizedBox(width: AppSpacing.xxxs),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.graphite,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '${AppStrings.appointmentDetailsNotesSection}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: notes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CompactSectionCard extends StatelessWidget {
  const _CompactSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.level1,
      ),
      child: child,
    );
  }
}

class _DetailsActionsFooter extends StatelessWidget {
  const _DetailsActionsFooter({
    this.onEdit,
    this.onComplete,
    this.onCancel,
    this.isBusy = false,
    this.cancelError,
    this.completeError,
    this.showEditButton = true,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final bool isBusy;
  final String? cancelError;
  final String? completeError;
  final bool showEditButton;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (completeError != null) ...[
                Text(
                  completeError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (cancelError != null) ...[
                Text(
                  cancelError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (onComplete != null) ...[
                AppButton(
                  label: AppStrings.appointmentCompleteAction,
                  icon: Icons.check_circle_outline,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onComplete,
                ),
                const SizedBox(height: AppSpacing.xxxs),
              ],
              if (showEditButton && onEdit != null) ...[
                AppButton(
                  label: AppStrings.appointmentEditAction,
                  icon: Icons.edit_outlined,
                  variant: onComplete != null
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onEdit,
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: AppSpacing.xxxs),
                _CancelAppointmentButton(
                  onPressed: onCancel,
                  isLoading: isBusy,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelAppointmentButton extends StatelessWidget {
  const _CancelAppointmentButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: AppColors.softRose,
        side: BorderSide(color: AppColors.softRose.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_outlined, size: AppIconSizes.sm),
          const SizedBox(width: AppSpacing.xxxs),
          Text(AppStrings.appointmentCancelAction),
        ],
      ),
    );
  }
}

class _AppointmentMemoryHighlightsSection extends ConsumerWidget {
  const _AppointmentMemoryHighlightsSection({
    required this.clientId,
    required this.appointmentId,
  });

  final String clientId;
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights = ref.watch(clientMemoryHighlightsProvider(clientId));
    if (!highlights.hasContent) {
      return const SizedBox.shrink();
    }

    final usageState = ref.watch(appointmentMemoryUsageProvider(appointmentId));
    final usageController = ref.read(
      appointmentMemoryUsageProvider(appointmentId).notifier,
    );

    return ClientMemoryHighlightsCard(
      highlights: highlights,
      usedMemoryIds: usageState.usedMemoryIds,
      onToggleUsed: usageController.toggleUsed,
    );
  }
}
