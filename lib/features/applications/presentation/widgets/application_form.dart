import 'package:flutter/material.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_text_field.dart';

class ApplicationForm extends StatefulWidget {
  const ApplicationForm({
    required this.onSubmit,
    this.initialPhone,
    this.isLoading = false,
    super.key,
  });

  final String? initialPhone;
  final bool isLoading;
  final Future<void> Function(ApplicationFormData data) onSubmit;

  @override
  State<ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<ApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  final _city = TextEditingController();
  final _experience = TextEditingController();
  final _motivation = TextEditingController();
  HousingType _housing = HousingType.houseWithYard;
  bool _hasChildren = false;
  bool _hasPets = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _city.dispose();
    _experience.dispose();
    _motivation.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  String? _bounded(String? value, int minimum) {
    final required = _required(value);
    if (required != null) return required;
    final length = value!.trim().length;
    if (length < minimum) return 'Ingresá al menos $minimum caracteres.';
    if (length > 1000) return 'Ingresá como máximo 1000 caracteres.';
    return null;
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WoofyTextField(
          controller: _phone,
          label: 'Teléfono',
          keyboardType: TextInputType.phone,
          validator: _required,
          enabled: !widget.isLoading,
        ),
        const SizedBox(height: 14),
        WoofyTextField(
          controller: _city,
          label: 'Ciudad',
          validator: _required,
          enabled: !widget.isLoading,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<HousingType>(
          initialValue: _housing,
          decoration: const InputDecoration(labelText: 'Tipo de vivienda'),
          items: HousingType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: widget.isLoading
              ? null
              : (value) => setState(() => _housing = value!),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hay niños en casa'),
          value: _hasChildren,
          onChanged: widget.isLoading
              ? null
              : (value) => setState(() => _hasChildren = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hay otros animales'),
          value: _hasPets,
          onChanged: widget.isLoading
              ? null
              : (value) => setState(() => _hasPets = value),
        ),
        const SizedBox(height: 8),
        WoofyTextField(
          controller: _experience,
          label: 'Experiencia previa',
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          validator: (value) => _bounded(value, 10),
          enabled: !widget.isLoading,
        ),
        const SizedBox(height: 14),
        WoofyTextField(
          controller: _motivation,
          label: 'Motivación para adoptar',
          minLines: 4,
          maxLines: 7,
          maxLength: 1000,
          validator: (value) => _bounded(value, 20),
          enabled: !widget.isLoading,
        ),
        const SizedBox(height: 20),
        WoofyButton(
          label: 'Enviar postulación',
          icon: Icons.send_outlined,
          isExpanded: true,
          isLoading: widget.isLoading,
          onPressed: widget.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  await widget.onSubmit(
                    ApplicationFormData(
                      phone: _phone.text.trim(),
                      city: _city.text.trim(),
                      housingType: _housing,
                      hasChildren: _hasChildren,
                      hasPets: _hasPets,
                      experience: _experience.text.trim(),
                      motivation: _motivation.text.trim(),
                    ),
                  );
                },
        ),
      ],
    ),
  );
}
