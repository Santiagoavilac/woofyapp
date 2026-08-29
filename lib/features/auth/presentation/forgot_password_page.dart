import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/utils/validators.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_text_field.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(_identifierController.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.error;

    return BackFallbackScope(
      fallbackLocation: RoutePaths.auth,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Recuperar contraseña'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Text(
                      'Creá una contraseña nueva',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Te enviamos un enlace por correo para que puedas '
                      'elegir una contraseña nueva.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    WoofyCard(
                      child: _sent
                          ? const _SentMessage()
                          : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  WoofyTextField(
                                    key: const ValueKey(
                                      'forgot-password-email',
                                    ),
                                    controller: _identifierController,
                                    label: 'Email o nombre de usuario',
                                    validator: Validators.required,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  WoofyButton(
                                    label: 'Enviar enlace',
                                    onPressed: _submit,
                                    isLoading: state.isLoading,
                                    isExpanded: true,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (error is AppException) ...[
                      const SizedBox(height: 16),
                      Text(
                        error.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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

class _SentMessage extends StatelessWidget {
  const _SentMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        const Text(
          'Si existe una cuenta con esos datos, te enviamos un enlace para '
          'crear una contraseña nueva. Revisá también el correo no deseado.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
