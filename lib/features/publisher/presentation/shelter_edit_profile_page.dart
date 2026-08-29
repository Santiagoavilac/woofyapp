import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

class ShelterEditProfilePage extends ConsumerWidget {
  const ShelterEditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(shelterPortalSessionProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.profile,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Editar refugio'),
        body: SafeArea(
          child: sessionState.when(
            loading: () => const WoofyLoading(message: 'Cargando…'),
            error: (_, _) =>
                const WoofyError(message: 'No pudimos cargar la sesión.'),
            data: (session) {
              if (session == null) {
                return const WoofyError(
                  message: 'Sesión de refugio no activa.',
                );
              }
              return _ShelterEditForm(session: session);
            },
          ),
        ),
      ),
    );
  }
}

class _ShelterEditForm extends ConsumerStatefulWidget {
  const _ShelterEditForm({required this.session});

  final ShelterPortalSession session;

  @override
  ConsumerState<_ShelterEditForm> createState() => _ShelterEditFormState();
}

class _ShelterEditFormState extends ConsumerState<_ShelterEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _facebookCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _publicContactCtrl;
  late final TextEditingController _locationNotesCtrl;
  late final TextEditingController _addressCtrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _descriptionCtrl = TextEditingController(text: s.description ?? '');
    _phoneCtrl = TextEditingController(text: s.phone ?? '');
    _emailCtrl = TextEditingController(text: s.email ?? '');
    _instagramCtrl = TextEditingController(text: s.instagram ?? '');
    _facebookCtrl = TextEditingController(text: s.facebook ?? '');
    _websiteCtrl = TextEditingController(text: s.website ?? '');
    _publicContactCtrl = TextEditingController(text: s.publicContactName ?? '');
    _locationNotesCtrl = TextEditingController(text: s.locationNotes ?? '');
    _addressCtrl = TextEditingController(text: s.address ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _descriptionCtrl,
      _phoneCtrl,
      _emailCtrl,
      _instagramCtrl,
      _facebookCtrl,
      _websiteCtrl,
      _publicContactCtrl,
      _locationNotesCtrl,
      _addressCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() => _isUploadingPhoto = true);
      await ref
          .read(shelterPortalSessionProvider.notifier)
          .updateProfileImage(
            file.path,
            file.mimeType ?? _guessMime(file.path),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto actualizada.')));
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'No pudimos actualizar la foto.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final data = ShelterProfileFormData(
      description: _descriptionCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      instagram: _instagramCtrl.text,
      facebook: _facebookCtrl.text,
      website: _websiteCtrl.text,
      publicContactName: _publicContactCtrl.text,
      locationNotes: _locationNotesCtrl.text,
      address: _addressCtrl.text,
    );
    try {
      await ref.read(shelterPortalSessionProvider.notifier).updateProfile(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil del refugio actualizado.')),
      );
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

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseClientProvider);
    final storage = client.storage.from('dog-images');
    final path = widget.session.profileImagePath;
    final photoUrl = (path == null || path.isEmpty)
        ? null
        : storage.getPublicUrl(path);
    final disabled = _isSaving || _isUploadingPhoto;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PhotoRow(
                  photoUrl: photoUrl,
                  isUploading: _isUploadingPhoto,
                  onPick: disabled ? null : _pickPhoto,
                ),
                const SizedBox(height: 20),
                WoofyCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descriptionCtrl,
                        enabled: !disabled,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del refugio',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _publicContactCtrl,
                        enabled: !disabled,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de contacto público',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        enabled: !disabled,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !disabled,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        enabled: !disabled,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationNotesCtrl,
                        enabled: !disabled,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Notas de ubicación',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instagramCtrl,
                        enabled: !disabled,
                        decoration: const InputDecoration(
                          labelText: 'Instagram',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _facebookCtrl,
                        enabled: !disabled,
                        decoration: const InputDecoration(
                          labelText: 'Facebook',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _websiteCtrl,
                        enabled: !disabled,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Sitio web',
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
                  onPressed: disabled ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photoUrl,
    required this.isUploading,
    required this.onPick,
  });

  final String? photoUrl;
  final bool isUploading;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipOval(
                child: Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Icon(
                            Icons.home_work_rounded,
                            color: theme.colorScheme.primary,
                            size: 40,
                          ),
                          errorWidget: (_, _, _) => Icon(
                            Icons.home_work_rounded,
                            color: theme.colorScheme.primary,
                            size: 40,
                          ),
                        )
                      : Icon(
                          Icons.home_work_rounded,
                          color: theme.colorScheme.primary,
                          size: 40,
                        ),
                ),
              ),
              if (isUploading)
                const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Foto de perfil',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              WoofyButton(
                label: photoUrl != null ? 'Cambiar foto' : 'Subir foto',
                icon: Icons.image_outlined,
                variant: WoofyButtonVariant.secondary,
                isExpanded: true,
                onPressed: onPick,
              ),
              const SizedBox(height: 6),
              Text(
                'JPG, PNG o WEBP. Máximo 5 MB.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
