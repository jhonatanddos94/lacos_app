import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/theme/app_theme.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/clients/presentation/pages/clients_page.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';
import 'package:lacos_app/features/shell/presentation/widgets/app_navigation_bar.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(appShellTabProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightStatusBarOverlay,
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: IndexedStack(
          index: selectedTab.index,
          children: const [
            AgendaPage(),
            ClientsPage(),
            HomePage(),
            _ShellPlaceholder(label: 'Serviços'),
            _ShellPlaceholder(label: 'Mais'),
          ],
        ),
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: selectedTab.index,
          onDestinationSelected: (index) {
            ref.read(appShellTabProvider.notifier).selectIndex(index);
          },
        ),
      ),
    );
  }
}

class _ShellPlaceholder extends StatelessWidget {
  const _ShellPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Text(
            '$label em breve',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
