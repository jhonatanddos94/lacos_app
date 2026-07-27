import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_flow_result.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_operational_badge_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_operational_badge_chip.dart';
import 'package:lacos_app/features/clients/application/models/client_next_appointment_preview.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';

const _badgeMapper = AppointmentOperationalBadgeMapper();

class ClientNextAppointmentSection extends ConsumerStatefulWidget {
  const ClientNextAppointmentSection({required this.clientId, super.key});

  static const nextAppointmentSkeletonLineKey = Key(
    'client_next_appointment_skeleton_line',
  );

  final String clientId;

  @override
  ConsumerState<ClientNextAppointmentSection> createState() =>
      _ClientNextAppointmentSectionState();
}

class _ClientNextAppointmentSectionState
    extends ConsumerState<ClientNextAppointmentSection>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<ClientNextAppointmentPreview?>>?
  _previewSubscription;
  Timer? _expiryTimer;

  String? _scheduledAppointmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _previewSubscription = ref.listenManual(
      clientNextAppointmentProvider(widget.clientId),
      (_, next) => _scheduleExpiryInvalidation(next.valueOrNull),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewSubscription?.close();
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(clientNextAppointmentProvider(widget.clientId));
    }
  }

  void _scheduleExpiryInvalidation(ClientNextAppointmentPreview? preview) {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    if (!mounted || preview == null) {
      _scheduledAppointmentId = null;
      return;
    }

    if (_scheduledAppointmentId == preview.appointmentId) {
      return;
    }

    final remaining = preview.endAt.difference(DateTime.now());
    _scheduledAppointmentId = preview.appointmentId;

    if (remaining <= Duration.zero) {
      ref.invalidate(clientNextAppointmentProvider(widget.clientId));
      return;
    }

    _expiryTimer = Timer(remaining, () {
      _scheduledAppointmentId = null;
      if (!mounted) return;
      ref.invalidate(clientNextAppointmentProvider(widget.clientId));
    });
  }

  Future<void> _openDetails(ClientNextAppointmentPreview preview) async {
    final result = await openAgendaAppointmentFlow(
      context: context,
      ref: ref,
      appointment: preview.toAgendaDisplay(),
    );

    if (!mounted || result == null) return;

    _invalidateAfterFlow(result);
  }

  void _invalidateAfterFlow(Object result) {
    if (result is CompleteAppointmentFlowResult) {
      ref.invalidate(
        clientNextAppointmentProvider(result.appointment.clientId),
      );
      if (result.appointment.clientId != widget.clientId) {
        ref.invalidate(clientNextAppointmentProvider(widget.clientId));
      }
      return;
    }

    if (result is Appointment) {
      ref.invalidate(clientNextAppointmentProvider(result.clientId));
      if (result.clientId != widget.clientId) {
        ref.invalidate(clientNextAppointmentProvider(widget.clientId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(
      clientNextAppointmentProvider(widget.clientId),
    );

    return previewAsync.when(
      loading: () => const _ClientNextAppointmentLoadingCard(),
      error: (_, _) => _ClientNextAppointmentErrorCard(
        onRetry: () =>
            ref.invalidate(clientNextAppointmentProvider(widget.clientId)),
      ),
      data: (preview) {
        if (preview == null) {
          return const _ClientNextAppointmentEmptyCard();
        }

        return _ClientNextAppointmentContentCard(
          preview: preview,
          onTap: () => _openDetails(preview),
        );
      },
    );
  }
}

class _ClientNextAppointmentLoadingCard extends StatelessWidget {
  const _ClientNextAppointmentLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.clientNextAppointmentLoadingLabel,
      child: _ClientNextAppointmentCardShell(
        child: const _ClientNextAppointmentSkeletonBody(),
      ),
    );
  }
}

class _ClientNextAppointmentSkeletonBody extends StatelessWidget {
  const _ClientNextAppointmentSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSkeletonBox(
                key:
                    ClientNextAppointmentSection.nextAppointmentSkeletonLineKey,
                height: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const AppSkeletonBox(width: 58, height: 22),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxs),
        const AppSkeletonBox(width: 120, height: 16),
        const SizedBox(height: AppSpacing.xxxs),
        const AppSkeletonBox(width: 40, height: 12),
        const SizedBox(height: AppSpacing.xs),
        const AppSkeletonBox(width: double.infinity, height: 14),
        const SizedBox(height: AppSpacing.xxxs),
        const AppSkeletonBox(width: double.infinity, height: 14),
        const SizedBox(height: AppSpacing.xxxs),
        const AppSkeletonBox(width: 180, height: 14),
      ],
    );
  }
}

class _ClientNextAppointmentErrorCard extends StatelessWidget {
  const _ClientNextAppointmentErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ClientNextAppointmentCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.clientNextAppointmentLoadError,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: Text(AppStrings.tryAgain)),
        ],
      ),
    );
  }
}

class _ClientNextAppointmentEmptyCard extends StatelessWidget {
  const _ClientNextAppointmentEmptyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ClientNextAppointmentCardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.purple50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: AppColors.purple700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.clientNextAppointmentEmpty,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientNextAppointmentContentCard extends StatelessWidget {
  const _ClientNextAppointmentContentCard({
    required this.preview,
    required this.onTap,
  });

  final ClientNextAppointmentPreview preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgePresentation = _badgeMapper.resolve(
      operationalState: preview.operationalState,
      isNext: true,
    );
    final dateLabel = formatAppointmentDateLabel(preview.startAt);
    final startTime = formatAppointmentClockTime(preview.startAt);
    final endTime = formatAppointmentClockTime(preview.endAt);
    final durationLabel = formatAppointmentDuration(
      preview.startAt,
      preview.endAt,
    );

    return Semantics(
      button: true,
      label: AppStrings.clientNextAppointmentOpenDetailsLabel,
      child: _ClientNextAppointmentCardShell(
        showChevron: true,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppointmentOperationalBadgeChip(
                  presentation: badgePresentation,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              '$startTime – $endTime',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.purple800,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (durationLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                durationLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              preview.professionalName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              preview.servicesSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientNextAppointmentCardShell extends StatelessWidget {
  const _ClientNextAppointmentCardShell({
    required this.child,
    this.showChevron = false,
    this.onTap,
  });

  final Widget child;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.paddingSm,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.divider),
            boxShadow: const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.purple700,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xxxs),
                  Expanded(
                    child: Text(
                      AppStrings.clientNextAppointment,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (showChevron)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.purple700,
                      size: AppIconSizes.sm,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
