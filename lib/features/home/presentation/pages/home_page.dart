import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/home/application/providers/home_dashboard_providers.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/home/presentation/widgets/next_appointment_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/salon_summary_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/today_schedule_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceProvider);
    final dashboard = ref.watch(homeDashboardProvider);

    return workspaceState.when(
      data: (workspace) =>
          _HomeContent(workspace: workspace, dashboard: dashboard),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _HomeError(onRetry: () => ref.invalidate(workspaceProvider)),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.workspace, required this.dashboard});

  final Workspace? workspace;
  final HomeDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final professionalName = workspace?.professional?.name ?? 'Profissional';
    final salonName = workspace?.salon?.name ?? 'Seu salão';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
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
                  salonName: salonName,
                ),
                const SizedBox(height: AppSpacing.md),
                NextAppointmentCard(appointment: dashboard.nextAppointment),
                const SizedBox(height: AppSpacing.md),
                QuickActionsSection(actions: dashboard.quickActions),
                const SizedBox(height: AppSpacing.md),
                SalonSummarySection(metrics: dashboard.summary),
                const SizedBox(height: AppSpacing.md),
                TodayScheduleSection(appointments: dashboard.todaySchedule),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warmAmber,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Não foi possível carregar sua área de trabalho.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
