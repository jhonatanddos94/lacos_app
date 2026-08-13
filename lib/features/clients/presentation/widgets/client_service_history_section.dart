import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_preview.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_formatters.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';

class ClientServiceHistorySection extends ConsumerWidget {
  const ClientServiceHistorySection({
    required this.client,
    required this.onViewAll,
    super.key,
  });

  static const previewSkeletonKey = Key('client_service_history_skeleton');

  final Client client;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      clientServiceHistoryPreviewProvider(client.id),
    );

    return previewAsync.when(
      loading: () => const _ClientServiceHistoryLoadingCard(),
      error: (_, _) => _ClientServiceHistoryErrorCard(
        onRetry: () => ref.invalidate(clientServiceHistoryProvider(client.id)),
      ),
      data: (preview) {
        if (!preview.hasContent) {
          return _ClientServiceHistoryEmptyCard(onViewAll: onViewAll);
        }

        return _ClientServiceHistoryPreviewCard(
          client: client,
          preview: preview,
          onViewAll: onViewAll,
        );
      },
    );
  }
}

class _ClientServiceHistoryLoadingCard extends StatelessWidget {
  const _ClientServiceHistoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.clientServiceHistoryLoadingLabel,
      child: _HistoryCardShell(
        showChevron: true,
        child: Column(
          key: ClientServiceHistorySection.previewSkeletonKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            AppSkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: AppSpacing.xxxs),
            AppSkeletonBox(width: 180, height: 14),
            SizedBox(height: AppSpacing.xs),
            AppSkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: AppSpacing.xxxs),
            AppSkeletonBox(width: 140, height: 14),
          ],
        ),
      ),
    );
  }
}

class _ClientServiceHistoryErrorCard extends StatelessWidget {
  const _ClientServiceHistoryErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HistoryCardShell(
      showChevron: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.clientServiceHistoryLoadError,
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

class _ClientServiceHistoryEmptyCard extends StatelessWidget {
  const _ClientServiceHistoryEmptyCard({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HistoryCardShell(
      showChevron: true,
      onHeaderTap: onViewAll,
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
              Icons.receipt_long_outlined,
              color: AppColors.purple700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.noServiceHistoryYet,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  AppStrings.clientHistoryComingSoon,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientServiceHistoryPreviewCard extends ConsumerWidget {
  const _ClientServiceHistoryPreviewCard({
    required this.client,
    required this.preview,
    required this.onViewAll,
  });

  final Client client;
  final ClientServiceHistoryPreview preview;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return _HistoryCardShell(
      showChevron: true,
      onHeaderTap: onViewAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < preview.items.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.xs),
            _PreviewHistoryTile(
              item: preview.items[index],
              onTap: () => _openDetails(context, ref, preview.items[index]),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: AppStrings.clientServiceHistoryOpenFullLabel,
              child: TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.clientServiceHistoryViewAll,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.purple700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref,
    ClientServiceHistoryItem item,
  ) async {
    if (!item.canOpenDetails) return;

    await openAgendaAppointmentFlow(
      context: context,
      ref: ref,
      appointment: AgendaAppointmentDisplay(
        appointmentId: item.appointmentId!,
        clientId: item.clientId,
        clientName: client.name,
        servicesSummary: item.servicesSummary,
        startAt: item.occurredAt,
        endAt: item.occurredAt,
        status: item.openFlowStatus,
      ),
    );
  }
}

class _PreviewHistoryTile extends StatelessWidget {
  const _PreviewHistoryTile({required this.item, required this.onTap});

  final ClientServiceHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = item.totalAmount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.canOpenDetails ? onTap : null,
        borderRadius: AppRadius.borderSm,
        child: Semantics(
          button: item.canOpenDetails,
          label: AppStrings.clientServiceHistoryOpenDetailsLabel,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ClientServiceHistoryDateFormatters.formatItemDate(
                          item.occurredAt,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.servicesSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (amount != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatServicePrice(amount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.purple800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.canOpenDetails)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCardShell extends StatelessWidget {
  const _HistoryCardShell({
    required this.child,
    this.showChevron = false,
    this.onHeaderTap,
  });

  final Widget child;
  final bool showChevron;
  final VoidCallback? onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.level0,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHeaderTap,
              borderRadius: AppRadius.borderSm,
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.purple700,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xxxs),
                  Expanded(
                    child: Text(
                      AppStrings.clientServiceHistory,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (showChevron)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.graphite,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
