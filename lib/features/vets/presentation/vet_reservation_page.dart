import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/vets/data/money.dart';
import 'package:woofy/features/vets/data/vet_models.dart';
import 'package:woofy/features/vets/data/vet_repository_provider.dart';
import 'package:woofy/features/vets/data/whatsapp_message.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_text_field.dart';

/// Reserva de un servicio: elegir servicio, fecha y hora, y datos de la
/// mascota. El turno se guarda en la base antes de abrir WhatsApp.
class VetReservationPage extends ConsumerStatefulWidget {
  const VetReservationPage({required this.slug, this.serviceId, super.key});

  final String slug;

  /// Servicio preseleccionado al venir desde el perfil.
  final String? serviceId;

  @override
  ConsumerState<VetReservationPage> createState() => _VetReservationPageState();
}

class _VetReservationPageState extends ConsumerState<VetReservationPage> {
  final _petController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedServiceId;
  DateTime? _scheduledFor;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.serviceId;
  }

  @override
  void dispose() {
    _petController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(vetDetailProvider(widget.slug));

    return Scaffold(
      appBar: WoofyAppBar(
        title: 'Reservar turno',
        backFallbackLocation: RoutePaths.vetDetail(widget.slug),
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const WoofyLoading(message: 'Cargando servicios…'),
          error: (error, stackTrace) => WoofyError(
            message: 'No pudimos cargar los servicios.',
            onRetry: () => ref.invalidate(vetDetailProvider(widget.slug)),
          ),
          data: (data) {
            if (data == null || data.services.isEmpty) {
              return WoofyEmptyState(
                icon: Icons.schedule_rounded,
                title: 'Sin servicios disponibles',
                message: 'Esta veterinaria todavía no cargó servicios.',
                actionLabel: 'Volver',
                onAction: () => context.go(RoutePaths.vetDetail(widget.slug)),
              );
            }
            return _buildForm(data);
          },
        ),
      ),
    );
  }

  Widget _buildForm(VetDetail detail) {
    final theme = Theme.of(context);
    // El id que viene por `extra` puede no existir más si el catálogo cambió
    // entre pantallas, así que se valida contra la lista real.
    final selected = detail.services
        .where((service) => service.id == _selectedServiceId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(WoofySpacing.lg),
      children: [
        Text(detail.vet.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: WoofySpacing.lg),
        Text('Servicio', style: theme.textTheme.titleSmall),
        const SizedBox(height: WoofySpacing.sm),
        // ListTile con ícono en vez de RadioListTile: la API de Radio quedó
        // deprecada a favor de RadioGroup y no vale arrastrar el warning por
        // una lista de tres opciones.
        for (final service in detail.services)
          ListTile(
            key: ValueKey('reservation-service-${service.id}'),
            onTap: () => setState(() => _selectedServiceId = service.id),
            leading: Icon(
              _selectedServiceId == service.id
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: _selectedServiceId == service.id
                  ? WoofyColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(service.name),
            subtitle: Text(Money.fromCents(service.priceCents)),
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: WoofySpacing.lg),
        WoofyCard(
          padding: const EdgeInsets.all(WoofySpacing.md),
          onTap: _pickDateTime,
          tapKey: const ValueKey('reservation-pick-datetime'),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: WoofyColors.primary),
              const SizedBox(width: WoofySpacing.md),
              Expanded(
                child: Text(
                  _scheduledFor == null
                      ? 'Elegí fecha y hora'
                      : DateFormat(
                          "EEEE d 'de' MMMM, HH:mm",
                          'es',
                        ).format(_scheduledFor!),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: WoofySpacing.lg),
        WoofyTextField(
          controller: _petController,
          label: 'Nombre de la mascota',
          hint: 'Kira',
          maxLength: 60,
        ),
        const SizedBox(height: WoofySpacing.md),
        WoofyTextField(
          controller: _phoneController,
          label: 'Tu teléfono',
          hint: '70123456',
          keyboardType: TextInputType.phone,
          maxLength: 20,
        ),
        const SizedBox(height: WoofySpacing.md),
        WoofyTextField(
          controller: _notesController,
          label: 'Notas para la veterinaria',
          hint: 'Es nerviosa con otros perros',
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
        ),
        const SizedBox(height: WoofySpacing.xl),
        if (selected != null)
          Text(
            'Total: ${Money.fromCents(selected.priceCents)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: WoofyColors.primary,
            ),
          ),
        const SizedBox(height: WoofySpacing.md),
        WoofyButton(
          key: const ValueKey('reservation-submit'),
          label: 'Confirmar reserva',
          icon: Icons.event_available_rounded,
          isExpanded: true,
          isLoading: _submitting,
          onPressed: selected == null || _scheduledFor == null
              ? null
              : () => _submit(detail, selected),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledFor ?? now.add(const Duration(days: 1)),
      // No se agenda para atrás: el RPC lo rechaza igual, pero es mejor no
      // dejar al usuario llenar todo el formulario para nada.
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledFor ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit(VetDetail detail, VetService service) async {
    final scheduledFor = _scheduledFor;
    if (scheduledFor == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      final reservation = await ref
          .read(vetRepositoryProvider)
          .createReservation(
            vetId: detail.vet.id,
            serviceId: service.id,
            scheduledFor: scheduledFor,
            petName: _petController.text.trim().isEmpty
                ? null
                : _petController.text.trim(),
            contactPhone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (!mounted) return;
      ref.invalidate(myVetReservationsProvider);

      final uri = WhatsappMessage.buildUri(
        phone: detail.vet.whatsappPhone,
        message: WhatsappMessage.reservationText(
          vetName: detail.vet.name,
          serviceName: reservation.serviceNameSnapshot,
          priceCents: reservation.priceCentsSnapshot,
          scheduledFor: reservation.scheduledFor?.toLocal() ?? scheduledFor,
          petName: reservation.petName,
          notes: reservation.notes,
        ),
      );

      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      _notify('Reserva registrada. La veterinaria te va a confirmar.');
      context.go(RoutePaths.vetDetail(widget.slug));
    } on AppException catch (error) {
      if (mounted) _notify(error.message);
    } catch (_) {
      if (mounted) _notify('No pudimos registrar la reserva.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
