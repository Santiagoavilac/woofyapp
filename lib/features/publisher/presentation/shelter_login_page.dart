import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/publisher/data/publisher_providers.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class ShelterLoginPage extends ConsumerStatefulWidget {
  const ShelterLoginPage({super.key});

  @override
  ConsumerState<ShelterLoginPage> createState() => _ShelterLoginPageState();
}

class _ShelterLoginPageState extends ConsumerState<ShelterLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginCodeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _loginCodeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(shelterPortalSessionProvider.notifier)
          .login(_loginCodeCtrl.text, _passwordCtrl.text);
      if (mounted) context.go(RoutePaths.publisher);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AppException
            ? error.message
            : 'No pudimos iniciar sesión. Revisá el ID y la contraseña.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(shelterPortalSessionProvider, (_, next) {
      if (next.value != null && mounted) {
        context.go(RoutePaths.publisher);
      }
    });
    return BackFallbackScope(
      fallbackLocation: RoutePaths.landing,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Acceso refugios'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ingresar refugio',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresá con las credenciales que te dio Woofy.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    WoofyCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              key: const ValueKey('shelter-login-code'),
                              controller: _loginCodeCtrl,
                              enabled: !_loading,
                              decoration: const InputDecoration(
                                labelText: 'ID de refugio',
                                helperText:
                                    'Usá el nombre de usuario que te dio Woofy.',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              autocorrect: false,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresá el ID de tu refugio'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const ValueKey('shelter-login-password'),
                              controller: _passwordCtrl,
                              enabled: !_loading,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Ingresá la contraseña'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            WoofyButton(
                              label: 'Ingresar',
                              isLoading: _loading,
                              isExpanded: true,
                              onPressed: _loading ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
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
