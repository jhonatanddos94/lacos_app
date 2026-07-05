import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/presentation/navigation/auth_workspace_navigation.dart';

class VerifyEmailContent extends ConsumerStatefulWidget {
  const VerifyEmailContent({super.key});

  @override
  ConsumerState<VerifyEmailContent> createState() => _VerifyEmailContentState();
}

class _VerifyEmailContentState extends ConsumerState<VerifyEmailContent> {
  static const _resendCooldownSeconds = 60;

  Timer? _cooldownTimer;
  int _secondsRemaining = 0;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  Future<void> _checkVerification() async {
    if (_isChecking || _isResending) return;

    setState(() => _isChecking = true);
    await ref.read(authControllerProvider.notifier).reloadCurrentUser();
    if (!mounted) return;
    setState(() => _isChecking = false);

    final authState = ref.read(authControllerProvider);
    if (authState case AuthAuthenticated(
      :final user,
    ) when user.isEmailVerified) {
      _handleVerified();
      return;
    }

    if (authState is! AuthError) {
      _showMessage(
        'Seu e-mail ainda não foi confirmado.\n\n'
        'Após clicar no link enviado para seu e-mail, volte aqui e tente '
        'novamente.',
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending || _isChecking || _secondsRemaining > 0) return;

    setState(() => _isResending = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationEmail();
    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      _showMessage('E-mail reenviado com sucesso.');
      _startCooldown();
    }
  }

  Future<void> _signOut() async {
    if (_isChecking || _isResending) return;

    final success = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    if (success) {
      context.go(RoutePaths.login);
    }
  }

  Future<void> _handleVerified() async {
    await navigateFromAuthenticatedWorkspace(ref, context);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final email = switch (authState) {
      AuthAuthenticated(user: final user) => user.email,
      _ => null,
    };
    final isBusy = _isChecking || _isResending;
    final canResend = !isBusy && _secondsRemaining == 0;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next case AuthError(:final message)) {
        _showMessage(message);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verifique seu e-mail',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.purple900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enviamos um e-mail de confirmação para:',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _EmailPill(email: email),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Abra sua caixa de entrada (e verifique também a pasta de spam) '
          'e clique no link de confirmação para ativar sua conta.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _VerifyActionCard(
          icon: Icons.refresh_rounded,
          title: 'Já confirmei meu e-mail',
          subtitle: 'Verificar agora',
          isLoading: _isChecking,
          enabled: !isBusy,
          onTap: _checkVerification,
        ),
        const SizedBox(height: AppSpacing.xs),
        _VerifyActionCard(
          icon: Icons.send_outlined,
          title: 'Reenviar e-mail de confirmação',
          subtitle: canResend
              ? 'Você já pode reenviar.'
              : 'Você poderá reenviar em:',
          trailing: canResend ? null : _CountdownBadge(_secondsRemaining),
          isLoading: _isResending,
          enabled: canResend,
          onTap: _resendEmail,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SignOutCard(enabled: !isBusy, onTap: _signOut),
        const SizedBox(height: AppSpacing.sm),
        const _SecurityFooter(),
      ],
    );
  }
}

class _EmailPill extends StatelessWidget {
  const _EmailPill({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: AppRadius.borderMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mail_outline,
              color: AppColors.purple700,
              size: AppIconSizes.md,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                email ?? 'E-mail cadastrado',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.purple800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyActionCard extends StatelessWidget {
  const _VerifyActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.trailing,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BaseCard(
      enabled: enabled,
      onTap: onTap,
      child: Row(
        children: [
          _CircleIcon(icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (isLoading)
            const SizedBox(
              width: AppIconSizes.md,
              height: AppIconSizes.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.purple700,
                ),
        ],
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BaseCard(
      enabled: enabled,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.purple700,
              size: AppIconSizes.md,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Sair da conta',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({
    required this.child,
    required this.enabled,
    required this.onTap,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.58,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.borderMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMd,
              boxShadow: AppShadows.level1,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.purple50,
      ),
      child: Icon(icon, color: AppColors.purple700, size: AppIconSizes.md),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge(this.seconds);

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: AppRadius.borderSm,
      ),
      child: Text(
        '$minutes:$remainder',
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.purple800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.purple700,
            size: AppIconSizes.sm,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Seus dados estão protegidos com segurança.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
