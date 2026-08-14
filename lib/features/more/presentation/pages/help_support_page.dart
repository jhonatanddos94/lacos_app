import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/more/application/providers/support_providers.dart';
import 'package:lacos_app/features/more/application/services/support_whatsapp_service.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class HelpSupportPage extends ConsumerStatefulWidget {
  const HelpSupportPage({super.key});

  static const pageKey = Key('help-support-page');
  static const supportCardKey = Key('help-support-card');
  static const whatsappButtonKey = Key('help-support-whatsapp-button');

  @override
  ConsumerState<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends ConsumerState<HelpSupportPage> {
  var _isOpening = false;

  Future<void> _openWhatsApp() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    final result = await ref.read(supportWhatsAppServiceProvider).open();
    if (!mounted) return;
    setState(() => _isOpening = false);

    if (result
        case SupportLaunchResult.failed || SupportLaunchResult.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.supportWhatsAppOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.graphite,
        elevation: 0,
        title: Text(
          AppStrings.moreHelpSupport,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: HelpSupportPage.pageKey,
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.lg,
          ),
          children: [
            Text(
              AppStrings.moreHelpIntro,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.moreHelpBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              key: HelpSupportPage.supportCardKey,
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.divider),
                boxShadow: AppShadows.level1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.purple50,
                        ),
                        child: const Icon(
                          Icons.support_agent_outlined,
                          color: AppColors.purple700,
                          size: AppIconSizes.md,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.supportCardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    AppStrings.supportCardDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.supportExternalNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: HelpSupportPage.whatsappButtonKey,
                    label: AppStrings.supportWhatsAppAction,
                    onPressed: _isOpening ? null : _openWhatsApp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
