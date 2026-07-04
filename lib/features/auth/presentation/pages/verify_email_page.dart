import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/auth/presentation/widgets/shared/auth_background.dart';
import 'package:lacos_app/features/auth/presentation/widgets/shared/auth_brand_header.dart';
import 'package:lacos_app/features/auth/presentation/widgets/verify_email/verify_email_content.dart';

/// Tela de verificação de e-mail do Laços.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  static const _systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.warmWhite,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: AuthBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: AppSpacing.screenPadding.copyWith(
                    top: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - AppSpacing.md - AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            AuthBrandHeader(),
                            SizedBox(height: AppSpacing.md),
                            VerifyEmailContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
