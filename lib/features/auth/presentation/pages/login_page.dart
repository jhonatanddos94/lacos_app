import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login_background.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login_brand_header.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login_footer.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login_form.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login_welcome_section.dart';

/// Tela de login do Laços.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
        body: LoginBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: AppSpacing.screenPadding.copyWith(
                    top: AppSpacing.xl,
                    bottom: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - AppSpacing.xl - AppSpacing.lg,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            LoginBrandHeader(),
                            SizedBox(height: AppSpacing.md),
                            LoginWelcomeSection(),
                            SizedBox(height: AppSpacing.xl),
                            LoginForm(),
                            SizedBox(height: AppSpacing.lg),
                            LoginFooter(),
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
