import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_quick_choice_chip.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_month_group.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_filter_service.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_formatters.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';

class ClientServiceHistoryPage extends ConsumerStatefulWidget {
  const ClientServiceHistoryPage({required this.client, super.key});

  final Client client;

  @override
  ConsumerState<ClientServiceHistoryPage> createState() =>
      _ClientServiceHistoryPageState();
}

class _ClientServiceHistoryPageState
    extends ConsumerState<ClientServiceHistoryPage> {
  static const _systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.warmWhite,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  var _filter = ClientServiceHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      clientServiceHistoryProvider(widget.client.id),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        appBar: AppBar(
          title: Text(AppStrings.clientServiceHistory),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(clientServiceHistoryProvider(widget.client.id));
            await ref.read(
              clientServiceHistoryProvider(widget.client.id).future,
            );
          },
          child: historyAsync.when(
            loading: () => const _HistoryLoadingBody(),
            error: (_, _) => _HistoryErrorBody(
              onRetry: () => ref.invalidate(
                clientServiceHistoryProvider(widget.client.id),
              ),
            ),
            data: (items) {
              final filtered = ClientServiceHistoryFilterService.apply(
                items: items,
                filter: _filter,
              );
              final groups = ClientServiceHistoryGrouper.groupByMonth(filtered);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HistoryFilterBar(
                    filter: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  Expanded(
                    child: groups.isEmpty
                        ? _HistoryEmptyBody(filter: _filter)
                        : _HistoryTimelineBody(
                            client: widget.client,
                            groups: groups,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.filter,
    required this.onChanged,
  });

  final ClientServiceHistoryFilter filter;
  final ValueChanged<ClientServiceHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Wrap(
        spacing: AppSpacing.xxxs,
        runSpacing: AppSpacing.xxxs,
        children: [
          AppointmentQuickChoiceChip(
            label: AppStrings.clientServiceHistoryFilterAll,
            selected: filter == ClientServiceHistoryFilter.all,
            onTap: () => onChanged(ClientServiceHistoryFilter.all),
          ),
          AppointmentQuickChoiceChip(
            label: AppStrings.clientServiceHistoryFilterCompleted,
            selected: filter == ClientServiceHistoryFilter.completed,
            onTap: () => onChanged(ClientServiceHistoryFilter.completed),
          ),
          AppointmentQuickChoiceChip(
            label: AppStrings.clientServiceHistoryFilterCanceled,
            selected: filter == ClientServiceHistoryFilter.canceled,
            onTap: () => onChanged(ClientServiceHistoryFilter.canceled),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingBody extends StatelessWidget {
  const _HistoryLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMd,
      children: const [
        AppSkeletonBox(width: 140, height: 16),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBox(width: double.infinity, height: 72),
        SizedBox(height: AppSpacing.xs),
        AppSkeletonBox(width: double.infinity, height: 72),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBox(width: 120, height: 16),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBox(width: double.infinity, height: 72),
      ],
    );
  }
}

class _HistoryEmptyBody extends StatelessWidget {
  const _HistoryEmptyBody({required this.filter});

  final ClientServiceHistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, message) = switch (filter) {
      ClientServiceHistoryFilter.all => (
        AppStrings.noServiceHistoryYet,
        AppStrings.clientHistoryComingSoon,
      ),
      ClientServiceHistoryFilter.completed => (
        AppStrings.clientServiceHistoryEmptyCompleted,
        null,
      ),
      ClientServiceHistoryFilter.canceled => (
        AppStrings.clientServiceHistoryEmptyCanceled,
        null,
      ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMd,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.receipt_long_outlined,
          size: AppIconSizes.lg,
          color: AppColors.purple300,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryErrorBody extends StatelessWidget {
  const _HistoryErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingMd,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppStrings.clientServiceHistoryLoadError,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(AppStrings.tryAgain),
          ),
        ),
      ],
    );
  }
}

class _HistoryTimelineBody extends ConsumerWidget {
  const _HistoryTimelineBody({
    required this.client,
    required this.groups,
  });

  final Client client;
  final List<ClientServiceHistoryMonthGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _MonthGroupSection(
          group: group,
          onItemTap: (item) => _openDetails(context, ref, item),
        );
      },
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

class _MonthGroupSection extends StatelessWidget {
  const _MonthGroupSection({
    required this.group,
    required this.onItemTap,
  });

  final ClientServiceHistoryMonthGroup group;
  final ValueChanged<ClientServiceHistoryItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            group.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.purple800,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in group.items) ...[
            _HistoryTimelineTile(
              item: item,
              onTap: () => onItemTap(item),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _HistoryTimelineTile extends StatelessWidget {
  const _HistoryTimelineTile({
    required this.item,
    required this.onTap,
  });

  final ClientServiceHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCanceled = item.kind == ClientServiceHistoryKind.canceled;
    final amount = item.totalAmount;
    final professional = item.professionalName?.trim();
    final titleColor = isCanceled
        ? AppColors.textSecondary
        : AppColors.graphite;
    final statusColor = isCanceled
        ? AppColors.textSecondary
        : AppColors.purple700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.canOpenDetails ? onTap : null,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          padding: AppSpacing.paddingSm,
          decoration: BoxDecoration(
            color: isCanceled
                ? AppColors.surface.withValues(alpha: 0.85)
                : AppColors.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isCanceled
                  ? AppColors.divider.withValues(alpha: 0.8)
                  : AppColors.divider,
            ),
          ),
          child: Opacity(
            opacity: isCanceled ? 0.88 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    ClientServiceHistoryDateFormatters.formatItemDayMonth(
                      item.occurredAt,
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isCanceled
                          ? AppColors.textSecondary
                          : AppColors.purple800,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.servicesSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      if (_subtitle(
                            professional: professional,
                            amount: amount,
                          ).isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          _subtitle(
                            professional: professional,
                            amount: amount,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (isCanceled &&
                          item.cancellationReasonPreview != null) ...[
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          AppStrings.clientServiceHistoryCancellationReasonLabel(
                            item.cancellationReasonPreview!,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        formatAppointmentStatusLabel(item.openFlowStatus),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.canOpenDetails)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle({required String? professional, required double? amount}) {
    final parts = <String>[];
    if (professional != null && professional.isNotEmpty) {
      parts.add(professional);
    }
    if (amount != null) {
      parts.add(formatServicePrice(amount));
    }
    return parts.join(' • ');
  }
}
