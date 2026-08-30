import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_text_field.dart';

/// La postulación, partida en tres tramos.
///
/// Siete campos de una sola vez se leen como un trámite y la gente abandona.
/// De a tres, cada pantalla se contesta en segundos y la barra de arriba
/// muestra que falta poco.
///
/// Es **un solo `Form` con una sola key**, y los pasos que no se ven quedan
/// montados bajo `Offstage`: si se desmontaran se perderían los
/// `TextEditingController` y la validación final dejaría de cubrirlos.
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

class _ApplicationFormState extends State<ApplicationForm>
    with SingleTickerProviderStateMixin {
  static const _steps = ['Tu contacto', 'Tu hogar', 'Tu historia'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  final _city = TextEditingController();
  final _experience = TextEditingController();
  final _motivation = TextEditingController();

  final _phoneField = GlobalKey<FormFieldState<String>>();
  final _cityField = GlobalKey<FormFieldState<String>>();
  final _experienceField = GlobalKey<FormFieldState<String>>();
  final _motivationField = GlobalKey<FormFieldState<String>>();

  HousingType _housing = HousingType.houseWithYard;
  bool _hasChildren = false;
  bool _hasPets = false;

  int _step = 0;

  /// Hacia dónde fue el último salto: define de qué lado entra el paso nuevo.
  double _direction = 1;

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _slide.dispose();
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

  /// Valida solo los campos del paso que se está viendo.
  ///
  /// No sirve `_formKey.currentState!.validate()`: eso valida también los
  /// pasos ocultos y frenaría el avance del paso 1 por algo del paso 3, sin
  /// mostrar dónde está el problema.
  bool _validateStep(int step) {
    final fields = switch (step) {
      0 => [_phoneField, _cityField],
      2 => [_experienceField, _motivationField],
      // El paso del hogar son un desplegable y dos interruptores: siempre
      // tienen un valor válido.
      _ => const <GlobalKey<FormFieldState<String>>>[],
    };
    // Sin cortocircuito a propósito: los dos campos tienen que marcar su error.
    var valid = true;
    for (final field in fields) {
      if (field.currentState?.validate() == false) valid = false;
    }
    return valid;
  }

  void _goTo(int step) {
    setState(() {
      _direction = step > _step ? 1 : -1;
      _step = step;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _slide.value = 1;
      return;
    }
    _slide.forward(from: 0);
  }

  void _next() {
    if (!_validateStep(_step)) return;
    _goTo(_step + 1);
  }

  Future<void> _submit() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _steps.length - 1;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepProgress(
            step: _step,
            total: _steps.length,
            title: _steps[_step],
          ),
          const SizedBox(height: WoofySpacing.lg),
          AnimatedBuilder(
            animation: _slide,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_slide.value);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(_direction * 36 * (1 - t), 0),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Offstage(offstage: _step != 0, child: _contactStep()),
                Offstage(offstage: _step != 1, child: _homeStep()),
                Offstage(offstage: _step != 2, child: _storyStep()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: WoofyButton(
                    label: 'Atrás',
                    variant: WoofyButtonVariant.secondary,
                    isExpanded: true,
                    onPressed: widget.isLoading ? null : () => _goTo(_step - 1),
                  ),
                ),
                const SizedBox(width: WoofySpacing.md),
              ],
              Expanded(
                child: isLast
                    ? WoofyButton(
                        label: 'Enviar postulación',
                        icon: Icons.send_outlined,
                        isExpanded: true,
                        isLoading: widget.isLoading,
                        onPressed: widget.isLoading ? null : _submit,
                      )
                    : WoofyButton(
                        label: 'Continuar',
                        icon: Icons.arrow_forward_rounded,
                        isExpanded: true,
                        onPressed: widget.isLoading ? null : _next,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WoofyTextField(
        fieldKey: _phoneField,
        controller: _phone,
        label: 'Teléfono',
        keyboardType: TextInputType.phone,
        validator: _required,
        enabled: !widget.isLoading,
      ),
      const SizedBox(height: 14),
      WoofyTextField(
        fieldKey: _cityField,
        controller: _city,
        label: 'Ciudad',
        validator: _required,
        enabled: !widget.isLoading,
      ),
    ],
  );

  Widget _homeStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
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
    ],
  );

  Widget _storyStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WoofyTextField(
        fieldKey: _experienceField,
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
        fieldKey: _motivationField,
        controller: _motivation,
        label: 'Motivación para adoptar',
        minLines: 4,
        maxLines: 7,
        maxLength: 1000,
        validator: (value) => _bounded(value, 20),
        enabled: !widget.isLoading,
      ),
    ],
  );
}

/// Cuánto falta, contado en pasos.
///
/// Nunca en porcentaje: "66%" suena a trámite; "Paso 2 de 3" suena a que ya
/// casi está.
class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.step,
    required this.total,
    required this.title,
  });

  final int step;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instant = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            Text(
              'Paso ${step + 1} de $total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: WoofySpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (step + 1) / total),
            duration: instant
                ? Duration.zero
                : const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: WoofyColors.surfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}
