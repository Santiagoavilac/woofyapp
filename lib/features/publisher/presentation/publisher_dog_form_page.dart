import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/dogs/data/dog_repository_provider.dart';
import 'package:mi_app/features/publisher/data/publisher_models.dart';
import 'package:mi_app/features/publisher/data/publisher_providers.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';
import 'package:mi_app/shared/widgets/woofy_loading.dart';

class PublisherDogFormPage extends ConsumerWidget {
  const PublisherDogFormPage({this.dogId, super.key});

  final String? dogId;

  bool get _isEdit => dogId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(shelterPortalSessionProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.publisher,
      child: Scaffold(
        appBar: WoofyAppBar(title: _isEdit ? 'Editar perro' : 'Nuevo perro'),
        body: SafeArea(
          child: sessionState.when(
            loading: () => const WoofyLoading(message: 'Cargando…'),
            error: (_, _) =>
                const WoofyError(message: 'No pudimos cargar el panel.'),
            data: (session) {
              if (session == null) {
                return const WoofyError(
                  message: 'Sesión de refugio no activa.',
                );
              }
              if (_isEdit) {
                return ref
                    .watch(shelterPortalDogByIdProvider(dogId!))
                    .when(
                      loading: () =>
                          const WoofyLoading(message: 'Cargando perro…'),
                      error: (error, _) => WoofyError(
                        message: error is AppException
                            ? error.message
                            : 'No pudimos cargar el perro.',
                        onRetry: () => ref.invalidate(
                          shelterPortalDogByIdProvider(dogId!),
                        ),
                      ),
                      data: (detail) => _DogForm(
                        session: session,
                        initialDetail: detail,
                        dogId: dogId,
                      ),
                    );
              }
              return _DogForm(session: session);
            },
          ),
        ),
      ),
    );
  }
}

class _DogForm extends ConsumerStatefulWidget {
  const _DogForm({required this.session, this.initialDetail, this.dogId});

  final ShelterPortalSession session;
  final DogDetail? initialDetail;
  final String? dogId;

  @override
  ConsumerState<_DogForm> createState() => _DogFormState();
}

class _DogFormState extends ConsumerState<_DogForm> {
  final _formKey = GlobalKey<FormState>();

  // Basic
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _storyCtrl;
  late final TextEditingController _ageCtrl;
  String? _sex;
  String? _size;
  String _status = 'draft';

  // Public profile
  late final TextEditingController _breedCtrl;
  late final TextEditingController _temperamentCtrl;
  String? _energyLevel;

  // Care & home
  late final TextEditingController _idealHomeCtrl;
  late final TextEditingController _specialCareCtrl;
  late final TextEditingController _feedingCtrl;
  late final TextEditingController _behaviorCtrl;
  late final TextEditingController _extraNotesCtrl;

  // Health
  bool _sterilized = false;
  bool _vaccinated = false;
  late final TextEditingController _medicalNotesCtrl;
  late final TextEditingController _knownConditionsCtrl;
  late final TextEditingController _currentTreatmentCtrl;

  // Compatibility
  bool? _goodWithChildren;
  bool? _goodWithDogs;
  bool? _goodWithCats;

  // Medical events
  late List<_MedicalEventEntry> _medicalEvents;

  bool _slugManuallyEdited = false;
  bool _isSaving = false;
  XFile? _pickedPhoto;

  bool get _isEdit => widget.dogId != null;

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    final dog = detail?.dog;
    _nameCtrl = TextEditingController(text: dog?.name ?? '');
    _slugCtrl = TextEditingController(text: dog?.slug ?? '');
    _storyCtrl = TextEditingController(text: dog?.story ?? '');
    _ageCtrl = TextEditingController(
      text: dog?.ageMonths != null ? '${dog!.ageMonths}' : '',
    );
    _sex = dog?.sex;
    _size = dog?.size;
    _status = dog?.status ?? 'draft';
    _energyLevel = dog?.energyLevel;
    _temperamentCtrl = TextEditingController(text: dog?.temperament ?? '');
    _medicalNotesCtrl = TextEditingController(text: dog?.medicalNotes ?? '');
    _sterilized = dog?.sterilized ?? false;
    _vaccinated = dog?.vaccinated ?? false;
    _goodWithChildren = dog?.goodWithChildren;
    _goodWithDogs = dog?.goodWithDogs;
    _goodWithCats = dog?.goodWithCats;

    _breedCtrl = TextEditingController(text: detail?.breed ?? '');
    _idealHomeCtrl = TextEditingController(text: detail?.idealHome ?? '');
    _specialCareCtrl = TextEditingController(text: detail?.specialCare ?? '');
    _feedingCtrl = TextEditingController(text: detail?.feedingNotes ?? '');
    _behaviorCtrl = TextEditingController(text: detail?.behaviorNotes ?? '');
    _extraNotesCtrl = TextEditingController(text: detail?.extraNotes ?? '');
    _knownConditionsCtrl = TextEditingController(
      text: detail?.knownConditions ?? '',
    );
    _currentTreatmentCtrl = TextEditingController(
      text: detail?.currentTreatment ?? '',
    );

    _medicalEvents = (detail?.medicalEvents ?? const [])
        .map(_MedicalEventEntry.fromModel)
        .toList();

    if (_isEdit) _slugManuallyEdited = true;
    _nameCtrl.addListener(_autoSlug);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_autoSlug);
    for (final ctrl in [
      _nameCtrl,
      _slugCtrl,
      _storyCtrl,
      _ageCtrl,
      _breedCtrl,
      _temperamentCtrl,
      _idealHomeCtrl,
      _specialCareCtrl,
      _feedingCtrl,
      _behaviorCtrl,
      _extraNotesCtrl,
      _medicalNotesCtrl,
      _knownConditionsCtrl,
      _currentTreatmentCtrl,
    ]) {
      ctrl.dispose();
    }
    for (final entry in _medicalEvents) {
      entry.dispose();
    }
    super.dispose();
  }

  void _autoSlug() {
    if (!_slugManuallyEdited) {
      _slugCtrl.text = _slugify(_nameCtrl.text);
    }
  }

  String _slugify(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-');

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _pickedPhoto = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la galería.')),
      );
    }
  }

  DogFormData _buildFormData() {
    return DogFormData(
      name: _nameCtrl.text.trim(),
      slug: _slugCtrl.text.trim(),
      story: _storyCtrl.text.trim(),
      status: _status,
      sex: _sex,
      ageMonths: int.tryParse(_ageCtrl.text.trim()),
      size: _size,
      energyLevel: _energyLevel,
      temperament: _temperamentCtrl.text.trim(),
      medicalNotes: _medicalNotesCtrl.text.trim(),
      sterilized: _sterilized,
      vaccinated: _vaccinated,
      goodWithChildren: _goodWithChildren,
      goodWithDogs: _goodWithDogs,
      goodWithCats: _goodWithCats,
      breed: _breedCtrl.text.trim(),
      idealHome: _idealHomeCtrl.text.trim(),
      specialCare: _specialCareCtrl.text.trim(),
      feedingNotes: _feedingCtrl.text.trim(),
      behaviorNotes: _behaviorCtrl.text.trim(),
      currentTreatment: _currentTreatmentCtrl.text.trim(),
      knownConditions: _knownConditionsCtrl.text.trim(),
      extraNotes: _extraNotesCtrl.text.trim(),
      medicalEvents: _medicalEvents.map((e) => e.toFormData()).toList(),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final formData = _buildFormData();
    final repo = ref.read(shelterPortalRepositoryProvider);
    final String savedDogId;
    try {
      savedDogId = await repo.saveDog(
        widget.session,
        formData,
        dogId: widget.dogId,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'No pudimos guardar el perro.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isSaving = false);
      return;
    }

    final pending = _pickedPhoto;
    if (pending != null) {
      try {
        await repo.uploadDogPhoto(
          widget.session,
          savedDogId,
          pending.path,
          pending.mimeType ?? _guessMime(pending.path),
        );
        if (mounted) setState(() => _pickedPhoto = null);
      } catch (error) {
        ref.invalidate(shelterPortalDogsProvider);
        ref.invalidate(shelterPortalDogByIdProvider(savedDogId));
        if (!mounted) return;
        final message = error is AppException
            ? error.message
            : 'El perro se guardó pero no pudimos subir la foto.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        setState(() => _isSaving = false);
        return;
      }
    }

    ref.invalidate(shelterPortalDogsProvider);
    ref.invalidate(shelterPortalDogByIdProvider(savedDogId));
    ref.invalidate(publishedDogsProvider);
    if (mounted) context.pop();
    if (mounted) setState(() => _isSaving = false);
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FormSection(
                  title: 'Información básica',
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresá el nombre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _slugCtrl,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Slug (URL)',
                        hintText: 'firulais-mendoza',
                      ),
                      onChanged: (_) => _slugManuallyEdited = true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresá el slug'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ageCtrl,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Edad (meses)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      items: const [
                        DropdownMenuItem(value: 'macho', child: Text('Macho')),
                        DropdownMenuItem(
                          value: 'hembra',
                          child: Text('Hembra'),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _sex = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _size,
                      decoration: const InputDecoration(labelText: 'Tamaño'),
                      items: const [
                        DropdownMenuItem(
                          value: 'pequeño',
                          child: Text('Pequeño'),
                        ),
                        DropdownMenuItem(
                          value: 'mediano',
                          child: Text('Mediano'),
                        ),
                        DropdownMenuItem(
                          value: 'grande',
                          child: Text('Grande'),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _size = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      validator: (v) => v == null ? 'Elegí un estado' : null,
                      items: const [
                        DropdownMenuItem(
                          value: 'draft',
                          child: Text('Borrador'),
                        ),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Publicado'),
                        ),
                        DropdownMenuItem(
                          value: 'in_process',
                          child: Text('En proceso'),
                        ),
                        DropdownMenuItem(
                          value: 'adopted',
                          child: Text('Adoptado'),
                        ),
                        DropdownMenuItem(
                          value: 'hidden',
                          child: Text('Oculto'),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _status = v ?? 'draft'),
                    ),
                    const SizedBox(height: 16),
                    _PhotoField(
                      pickedPhoto: _pickedPhoto,
                      currentUrl:
                          widget.initialDetail?.dog.coverPhoto?.publicUrl,
                      onPick: _isSaving ? null : _pickPhoto,
                      onClear: _isSaving || _pickedPhoto == null
                          ? null
                          : () => setState(() => _pickedPhoto = null),
                    ),
                  ],
                ),
                _FormSection(
                  title: 'Perfil público',
                  children: [
                    TextFormField(
                      controller: _breedCtrl,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Raza o mezcla',
                        hintText: 'Mestizo mediano',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _energyLevel,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de energía',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'baja', child: Text('Baja')),
                        DropdownMenuItem(value: 'media', child: Text('Media')),
                        DropdownMenuItem(value: 'alta', child: Text('Alta')),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _energyLevel = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _temperamentCtrl,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Temperamento',
                        hintText: 'sociable, curioso, tranquilo…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _storyCtrl,
                      enabled: !_isSaving,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(labelText: 'Historia'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Contá la historia del perro'
                          : null,
                    ),
                  ],
                ),
                _FormSection(
                  title: 'Compatibilidad',
                  children: [
                    _TriStateRow(
                      label: 'Convive con niños',
                      value: _goodWithChildren,
                      enabled: !_isSaving,
                      onChanged: (v) => setState(() => _goodWithChildren = v),
                    ),
                    const SizedBox(height: 8),
                    _TriStateRow(
                      label: 'Convive con perros',
                      value: _goodWithDogs,
                      enabled: !_isSaving,
                      onChanged: (v) => setState(() => _goodWithDogs = v),
                    ),
                    const SizedBox(height: 8),
                    _TriStateRow(
                      label: 'Convive con gatos',
                      value: _goodWithCats,
                      enabled: !_isSaving,
                      onChanged: (v) => setState(() => _goodWithCats = v),
                    ),
                  ],
                ),
                _FormSection(
                  title: 'Cuidados y hogar',
                  children: [
                    _MultilineField(
                      controller: _idealHomeCtrl,
                      enabled: !_isSaving,
                      label: 'Hogar ideal',
                    ),
                    _MultilineField(
                      controller: _specialCareCtrl,
                      enabled: !_isSaving,
                      label: 'Cuidados especiales',
                    ),
                    _MultilineField(
                      controller: _feedingCtrl,
                      enabled: !_isSaving,
                      label: 'Alimentación',
                    ),
                    _MultilineField(
                      controller: _behaviorCtrl,
                      enabled: !_isSaving,
                      label: 'Comportamiento',
                    ),
                    _MultilineField(
                      controller: _extraNotesCtrl,
                      enabled: !_isSaving,
                      label: 'Información adicional',
                    ),
                  ],
                ),
                _FormSection(
                  title: 'Salud',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Esterilizado / castrado'),
                      value: _sterilized,
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _sterilized = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vacunas al día'),
                      value: _vaccinated,
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _vaccinated = v),
                    ),
                    const SizedBox(height: 4),
                    _MultilineField(
                      controller: _medicalNotesCtrl,
                      enabled: !_isSaving,
                      label: 'Notas médicas',
                    ),
                    _MultilineField(
                      controller: _knownConditionsCtrl,
                      enabled: !_isSaving,
                      label: 'Condiciones conocidas',
                    ),
                    _MultilineField(
                      controller: _currentTreatmentCtrl,
                      enabled: !_isSaving,
                      label: 'Tratamiento actual',
                    ),
                  ],
                ),
                _FormSection(
                  title: 'Historial médico',
                  children: [
                    if (_medicalEvents.isEmpty)
                      Text(
                        'Todavía no cargaste eventos médicos.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    for (var i = 0; i < _medicalEvents.length; i++) ...[
                      _MedicalEventCard(
                        key: ValueKey(_medicalEvents[i].id),
                        entry: _medicalEvents[i],
                        enabled: !_isSaving,
                        onRemove: () => setState(() {
                          final removed = _medicalEvents.removeAt(i);
                          removed.dispose();
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => setState(() {
                                _medicalEvents.add(_MedicalEventEntry.empty());
                              }),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Agregar evento'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                WoofyButton(
                  label: _isEdit ? 'Guardar cambios' : 'Crear perro',
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
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          WoofyCard(child: Column(children: children)),
        ],
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  const _MultilineField({
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _TriStateRow extends StatelessWidget {
  const _TriStateRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SegmentedButton<bool?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Sin dato')),
            ButtonSegment(value: true, label: Text('Sí')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: {value},
          onSelectionChanged: enabled
              ? (selection) => onChanged(selection.first)
              : null,
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }
}

class _MedicalEventEntry {
  _MedicalEventEntry({
    required this.id,
    required this.titleCtrl,
    required this.descriptionCtrl,
    this.eventType,
    this.eventDate,
  });

  factory _MedicalEventEntry.empty() => _MedicalEventEntry(
    id: DateTime.now().microsecondsSinceEpoch,
    titleCtrl: TextEditingController(),
    descriptionCtrl: TextEditingController(),
  );

  factory _MedicalEventEntry.fromModel(DogMedicalEvent event) =>
      _MedicalEventEntry(
        id: event.id.hashCode,
        titleCtrl: TextEditingController(text: event.title),
        descriptionCtrl: TextEditingController(text: event.description ?? ''),
        eventType: event.eventType,
        eventDate: event.eventDate,
      );

  final int id;
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  String? eventType;
  DateTime? eventDate;

  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
  }

  MedicalEventFormData toFormData() => MedicalEventFormData(
    title: titleCtrl.text.trim(),
    eventType: eventType,
    eventDate: eventDate,
    description: descriptionCtrl.text.trim(),
  );
}

class _MedicalEventCard extends StatefulWidget {
  const _MedicalEventCard({
    required this.entry,
    required this.enabled,
    required this.onRemove,
    super.key,
  });

  final _MedicalEventEntry entry;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  State<_MedicalEventCard> createState() => _MedicalEventCardState();
}

class _MedicalEventCardState extends State<_MedicalEventCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = widget.entry.eventDate == null
        ? 'Elegir fecha'
        : '${widget.entry.eventDate!.day.toString().padLeft(2, '0')}/'
              '${widget.entry.eventDate!.month.toString().padLeft(2, '0')}/'
              '${widget.entry.eventDate!.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: widget.entry.titleCtrl,
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'Título del evento'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: widget.entry.eventType,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(value: 'vacuna', child: Text('Vacuna')),
              DropdownMenuItem(value: 'cirugía', child: Text('Cirugía')),
              DropdownMenuItem(value: 'consulta', child: Text('Consulta')),
              DropdownMenuItem(
                value: 'tratamiento',
                child: Text('Tratamiento'),
              ),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: widget.enabled
                ? (v) => setState(() => widget.entry.eventType = v)
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.enabled ? _pickDate : null,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(dateLabel),
                ),
              ),
              if (widget.entry.eventDate != null)
                IconButton(
                  tooltip: 'Quitar fecha',
                  onPressed: widget.enabled
                      ? () => setState(() => widget.entry.eventDate = null)
                      : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.entry.descriptionCtrl,
            enabled: widget.enabled,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.enabled ? widget.onRemove : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Eliminar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.entry.eventDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => widget.entry.eventDate = picked);
  }
}

class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.pickedPhoto,
    required this.currentUrl,
    required this.onPick,
    required this.onClear,
  });

  final XFile? pickedPhoto;
  final String? currentUrl;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPicked = pickedPhoto != null;
    final hasCurrent = currentUrl != null && currentUrl!.isNotEmpty;
    final hasAny = hasPicked || hasCurrent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto principal',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoPreview(
              pickedPath: hasPicked ? pickedPhoto!.path : null,
              currentUrl: hasCurrent ? currentUrl : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WoofyButton(
                    label: hasAny ? 'Cambiar foto' : 'Elegir foto',
                    icon: Icons.image_outlined,
                    variant: WoofyButtonVariant.secondary,
                    isExpanded: true,
                    onPressed: onPick,
                  ),
                  if (hasPicked) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancelar foto nueva'),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'JPG, PNG o WEBP. Máximo 5 MB.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.pickedPath, required this.currentUrl});

  final String? pickedPath;
  final String? currentUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surfaceContainerHighest,
    );
    Widget child;
    if (pickedPath != null) {
      child = Image.file(File(pickedPath!), fit: BoxFit.cover);
    } else if (currentUrl != null) {
      child = CachedNetworkImage(imageUrl: currentUrl!, fit: BoxFit.cover);
    } else {
      child = Icon(
        Icons.pets_rounded,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return Container(
      width: 120,
      height: 120,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}
