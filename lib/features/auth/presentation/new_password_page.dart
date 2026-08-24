import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/utils/validators.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_text_field.dart';

class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updatePassword(_passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu contraseña se actualizó.')),
      );
      context.go(RoutePaths.profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.error;
    final hasSession = ref.watch(currentUserProvider) != null;

    // Sin sesión no hay token de recuperación válido: el enlace expiró, ya
    // se usó, o alguien entró a la ruta a mano.
    if (!hasSession) {
      return Scaffold(
        appBar: const WoofyAppBar(title: 'Contraseña nueva'),
        body: SafeArea(
          child: WoofyError(
            title: 'El enlace ya no sirve',
            message:
                'Expiró o ya fue usado. Pedí uno nuevo para volver a '
                'intentarlo.',
            actionLabel: 'Pedir otro enlace',
            onRetry: () => context.go(RoutePaths.forgotPassword),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const WoofyAppBar(title: 'Contraseña nueva'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Text(
                    'Elegí tu contraseña nueva',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  WoofyCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WoofyTextField(
                            key: const ValueKey('new-password'),
                            controller: _passwordController,
                            label: 'Contraseña nueva',
                            validator: Validators.minLength(6),
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          WoofyTextField(
                            key: const ValueKey('new-password-confirm'),
                            controller: _confirmController,
                            label: 'Repetir contraseña',
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            validator: (value) => value == _passwordController.text
                                ? null
                                : 'Las contraseñas no coinciden.',
                          ),
                          const SizedBox(height: 24),
                          WoofyButton(
                            label: 'Guardar contraseña',
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
    );
  }
}
