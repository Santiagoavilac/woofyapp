import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/auth/presentation/widgets/auth_toggle_header.dart';
import 'package:mi_app/features/auth/presentation/widgets/login_form.dart';
import 'package:mi_app/features/auth/presentation/widgets/register_form.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

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
      if (mounted) context.go(RoutePaths.profile);
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

    return Scaffold(
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
                        : 'Accedé a tu cuenta de adoptante.',
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
