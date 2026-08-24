import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/auth/presentation/widgets/auth_toggle_header.dart';
import 'package:woofy/features/auth/presentation/widgets/login_form.dart';
import 'package:woofy/features/auth/presentation/widgets/register_form.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isRegistering = false;
  String? _confirmationMessage;

  Future<void> _login(String email, String password) async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: email, password: password);
      if (!mounted) return;
      context.go(RoutePaths.profile);
    } catch (_) {}
  }

  Future<void> _loginWithGoogle() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (_) {}
  }

  Future<void> _register(RegistrationInput input) async {
    setState(() => _confirmationMessage = null);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .register(
            fullName: input.fullName,
            phone: input.phone,
            email: input.email,
            password: input.password,
          );
      if (!mounted) return;
      if (result.requiresEmailConfirmation) {
        setState(
          () => _confirmationMessage =
              'Te enviamos un correo de confirmación. Abrilo y luego iniciá sesión.',
        );
      } else {
        context.go(RoutePaths.profile);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.error;

    return BackFallbackScope(
      fallbackLocation: RoutePaths.landing,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Cuenta Woofy'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Text(
                      _isRegistering ? 'Creá tu cuenta' : 'Ingresar a Woofy',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegistering
                          ? 'Prepará tu perfil para adoptar responsablemente.'
                          : 'Accedé a tu cuenta de Woofy.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AuthToggleHeader(
                      isRegistering: _isRegistering,
                      onChanged: (value) => setState(() {
                        _isRegistering = value;
                        _confirmationMessage = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    WoofyCard(
                      child: Column(
                        children: [
                          if (_isRegistering)
                            RegisterForm(
                              isLoading: state.isLoading,
                              onSubmit: _register,
                            )
                          else
                            LoginForm(
                              isLoading: state.isLoading,
                              onSubmit: _login,
                            ),
                        ],
                      ),
                    ),
                    if (defaultTargetPlatform == TargetPlatform.android) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      WoofyButton(
                        key: const ValueKey('google-signin'),
                        label: 'Continuar con Google',
                        icon: Icons.login,
                        variant: WoofyButtonVariant.secondary,
                        isLoading: state.isLoading,
                        isExpanded: true,
                        onPressed: _loginWithGoogle,
                      ),
                    ],
                    if (_confirmationMessage != null) ...[
                      const SizedBox(height: 16),
                      _StatusMessage(
                        icon: Icons.mark_email_read_outlined,
                        message: _confirmationMessage!,
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      _StatusMessage(
                        icon: Icons.error_outline_rounded,
                        message: error is AppException
                            ? error.message
                            : 'No pudimos completar la autenticación.',
                        isError: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
