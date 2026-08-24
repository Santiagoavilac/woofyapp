import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

class AdopterEditProfilePage extends ConsumerStatefulWidget {
  const AdopterEditProfilePage({super.key});

  @override
  ConsumerState<AdopterEditProfilePage> createState() =>
      _AdopterEditProfilePageState();
}

class _AdopterEditProfilePageState
    extends ConsumerState<AdopterEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            fullName: _fullNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cuenta actualizada.')));
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'No pudimos guardar los cambios.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentProfileProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.profile,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Editar mi cuenta'),
        body: SafeArea(
          child: profileState.when(
            loading: () => const WoofyLoading(message: 'Cargando…'),
            error: (_, _) =>
                const WoofyError(message: 'No pudimos cargar tu perfil.'),
            data: (profile) {
              if (profile == null) {
                return const WoofyError(
                  message: 'Todavía no tenés perfil creado.',
                );
              }
              if (!_initialized) {
                _fullNameCtrl.text = profile.fullName ?? '';
                _phoneCtrl.text = profile.phone ?? '';
                _initialized = true;
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WoofyCard(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _fullNameCtrl,
                                  enabled: !_isSaving,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre completo',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Ingresá tu nombre'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  enabled: !_isSaving,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: profile.email ?? '',
                                  enabled: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo',
                                    helperText:
                                        'El correo se administra desde tu cuenta.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          WoofyCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Próximamente vas a poder cambiar tu foto '
                                    'de perfil de adoptante.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          WoofyButton(
                            label: 'Guardar cambios',
                            isLoading: _isSaving,
                            isExpanded: true,
                            onPressed: _isSaving ? null : _save,
                          ),
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
    );
  }
}
