import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/application/providers/remember_me_providers.dart';
import 'package:lacos_app/features/auth/presentation/navigation/auth_workspace_navigation.dart';
import 'package:lacos_app/features/auth/presentation/validators/email_validator.dart';
import 'package:lacos_app/features/auth/presentation/validators/password_validator.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login/login_divider.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login/login_form_actions.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login/login_google_button.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  static const _emailValidator = EmailValidator();
  static const _passwordValidator = PasswordValidator();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  Future<void> _loadRememberMePreference() async {
    final rememberMe = await ref
        .read(rememberMePreferenceRepositoryProvider)
        .read();
    _setStateIfMounted(() => _rememberMe = rememberMe);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setStateIfMounted(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  Future<void> _signIn() async {
    if (_isSubmitting || ref.read(authControllerProvider) is AuthLoading) {
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    final emailError = _emailValidator(email);
    final passwordError = _passwordValidator(password);

    _setStateIfMounted(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null) return;

    _isSubmitting = true;
    _setStateIfMounted(() {});

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: email.trim(), password: password);

      if (!mounted) return;

      if (ref.read(authControllerProvider) is AuthAuthenticated) {
        try {
          await ref
              .read(rememberMePreferenceRepositoryProvider)
              .write(_rememberMe);
        } on Object {
          // Preferência não pode falhar o login já autenticado.
        }

        if (!mounted) return;
        await navigateFromAuthenticatedWorkspace(ref, context);
      }
    } finally {
      _isSubmitting = false;
      _setStateIfMounted(() {});
    }
  }

  void _showAuthError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = _isSubmitting || authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next case AuthError(:final message)) {
        _showAuthError(message);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'E-mail',
          hint: 'Informe seu email',
          controller: _emailController,
          enabled: !isLoading,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          prefixIcon: const Icon(Icons.mail_outline),
          onChanged: (_) {
            if (_emailError != null) {
              _setStateIfMounted(() => _emailError = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Senha',
          hint: 'Informe sua senha',
          controller: _passwordController,
          enabled: !isLoading,
          errorText: _passwordError,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _signIn(),
          prefixIcon: const Icon(Icons.lock_outline),
          onChanged: (_) {
            if (_passwordError != null) {
              _setStateIfMounted(() => _passwordError = null);
            }
          },
          suffixIcon: IconButton(
            onPressed: isLoading
                ? null
                : () => _setStateIfMounted(
                    () => _obscurePassword = !_obscurePassword,
                  ),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LoginFormActions(
          rememberMe: _rememberMe,
          enabled: !isLoading,
          onRememberMeChanged: (value) =>
              _setStateIfMounted(() => _rememberMe = value),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Entrar',
          isLoading: isLoading,
          onPressed: isLoading ? null : _signIn,
        ),
        const SizedBox(height: AppSpacing.md),
        const LoginDivider(),
        const SizedBox(height: AppSpacing.md),
        const LoginGoogleButton(),
      ],
    );
  }
}
