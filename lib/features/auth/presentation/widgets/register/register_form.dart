import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/presentation/validators/email_validator.dart';
import 'package:lacos_app/features/auth/presentation/validators/password_validator.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  static const _emailValidator = EmailValidator();
  static const _passwordValidator = PasswordValidator();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setStateIfMounted(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  Future<void> _createAccount() async {
    if (ref.read(authControllerProvider) is AuthLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final nameError = name.isEmpty ? 'Informe seu nome.' : null;
    final emailError = _emailValidator(email);
    final passwordError = _passwordValidator(password);
    final confirmPasswordError = _validateConfirmPassword(
      confirmPassword: confirmPassword,
      password: password,
    );

    _setStateIfMounted(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .createAccount(email: email.trim(), password: password);

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      _handleAccountCreated(authState);
    }
  }

  String? _validateConfirmPassword({
    required String confirmPassword,
    required String password,
  }) {
    if (confirmPassword.isEmpty) {
      return 'Confirme sua senha.';
    }

    if (confirmPassword != password) {
      return 'As senhas não coincidem.';
    }

    return null;
  }

  void _showAuthError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleAccountCreated(AuthAuthenticated state) {
    context.go(AppRouteResolver.resolveAfterAuth(state.user));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next case AuthError(:final message)) {
        _showAuthError(message);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nome',
          hint: 'Informe seu nome',
          controller: _nameController,
          enabled: !isLoading,
          errorText: _nameError,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          prefixIcon: const Icon(Icons.person_outline),
          onChanged: (_) {
            if (_nameError != null) {
              _setStateIfMounted(() => _nameError = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
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
          hint: 'Crie uma senha',
          controller: _passwordController,
          enabled: !isLoading,
          errorText: _passwordError,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          prefixIcon: const Icon(Icons.lock_outline),
          onChanged: (_) {
            if (_passwordError != null || _confirmPasswordError != null) {
              _setStateIfMounted(() {
                _passwordError = null;
                _confirmPasswordError = null;
              });
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
        AppTextField(
          label: 'Confirmar senha',
          hint: 'Repita sua senha',
          controller: _confirmPasswordController,
          enabled: !isLoading,
          errorText: _confirmPasswordError,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) => _createAccount(),
          prefixIcon: const Icon(Icons.lock_outline),
          onChanged: (_) {
            if (_confirmPasswordError != null) {
              _setStateIfMounted(() => _confirmPasswordError = null);
            }
          },
          suffixIcon: IconButton(
            onPressed: isLoading
                ? null
                : () => _setStateIfMounted(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Criar conta',
          isLoading: isLoading,
          onPressed: isLoading ? null : _createAccount,
        ),
      ],
    );
  }
}
