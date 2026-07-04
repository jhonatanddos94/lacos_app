import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/application/providers/clients_providers.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcuts_section.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_header.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_list_section.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  static const _fabSize = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(clientsDashboardProvider);
    final bottomInset = AppSpacing.sm + _fabSize + AppSpacing.md;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.md,
              bottom: bottomInset,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ClientsHeader(),
                    const SizedBox(height: AppSpacing.md),
                    const ClientsSearchBar(),
                    const SizedBox(height: AppSpacing.md),
                    ClientShortcutsSection(shortcuts: dashboard.shortcuts),
                    const SizedBox(height: AppSpacing.md),
                    ClientsListSection(clients: dashboard.clients),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.screenHorizontal,
            bottom: AppSpacing.sm,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.lacosPurple,
              foregroundColor: AppColors.onPrimary,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
