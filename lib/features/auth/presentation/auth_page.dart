import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/features/legal/data/legal_links.dart';
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
  String? _pendingConfirmationEmail;
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Supabase limita el reenvío a ~1 correo por minuto. Sin este contador el
  /// botón devolvería un error de rate limit y parecería roto.
  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown -= 1);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resendConfirmation() async {
    final email = _pendingConfirmationEmail;
    if (email == null) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email);
      if (!mounted) return;
      setState(
        () => _confirmationMessage =
            'Te reenviamos el correo. Revisá tu bandeja y el correo no deseado.',
      );
      _startResendCooldown();
    } catch (_) {}
  }

  Future<void> _login(String email, String password) async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: email, password: password);
      if (!mounted) return;
      context.go(RoutePaths.profile);
    } catch (_) {}
  }

  Future<void> _loginWithApple() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithApple();
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
        setState(() {
          _confirmationMessage =
              'Te enviamos un correo de confirmación. Abrilo y luego iniciá sesión.';
          _pendingConfirmationEmail = input.email;
        });
        _startResendCooldown();
      } else {
        context.go(RoutePaths.profile);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.error;
    final googleStatus = ref.watch(googleSignInStatusProvider);
    final isAwaitingGoogle =
        googleStatus == GoogleSignInStatus.awaitingCallback;

    return BackFallbackScope(
      fallbackLocation: RoutePaths.landing,
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Cuenta Woofy',
          backFallbackLocation: RoutePaths.landing,
        ),
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
                        _pendingConfirmationEmail = null;
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
                              onForgotPassword: () =>
                                  context.push(RoutePaths.forgotPassword),
                            ),
                        ],
                      ),
                    ),
                    ...[
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
                      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                        // Widget oficial del paquete: respeta las pautas de
                        // Apple, que el review verifica.
                        SignInWithAppleButton(
                          key: const ValueKey('apple-signin'),
                          text: 'Continuar con Apple',
                          height: 52,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(26),
                          ),
                          onPressed: _loginWithApple,
                        ),
                        const SizedBox(height: 12),
                      ],
                      WoofyButton(
                        key: const ValueKey('google-signin'),
                        label: 'Continuar con Google',
                        leading: const _GoogleMark(),
                        variant: WoofyButtonVariant.secondary,
                        // The official mark ships on an opaque white tile, and
                        // Google's guidelines ask for a white button anyway.
                        backgroundColor: WoofyColors.white,
                        isLoading: state.isLoading || isAwaitingGoogle,
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
                      if (_pendingConfirmationEmail != null)
                        TextButton(
                          key: const ValueKey('resend-confirmation'),
                          onPressed: _resendCooldown > 0
                              ? null
                              : _resendConfirmation,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Reenviar en ${_resendCooldown}s'
                                : 'Reenviar correo',
                          ),
                        ),
                    ],
                    if (googleStatus == GoogleSignInStatus.cancelled) ...[
                      const SizedBox(height: 16),
                      const _StatusMessage(
                        icon: Icons.info_outline_rounded,
                        message:
                            'Cancelaste el ingreso con Google. Probá de nuevo.',
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('auth-support-link'),
                      onPressed: () => openSupportEmail(
                        subject: 'Ayuda con mi cuenta de Woofy',
                      ),
                      child: const Text(
                        '¿Problemas o algo que denunciar? Escribinos',
                      ),
                    ),
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

/// Official Google "G", as Google's branding guidelines require: the mark
/// cannot be redrawn or replaced by a generic icon.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_g_logo.png',
      width: 20,
      height: 20,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.account_circle_outlined, size: 20),
    );
  }
}
