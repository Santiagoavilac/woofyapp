import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_info_chip.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_medical_events_section.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_photo_carousel.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_shelter_section.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/presentation/widgets/report_sheet.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/applications/presentation/widgets/application_status_card.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';

class DogDetailPage extends ConsumerWidget {
  const DogDetailPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dogDetailProvider(slug));
    return BackFallbackScope(
      fallbackLocation: RoutePaths.dogs,
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Perfil del perrito',
          actions: [
            if (detail.value case final value?)
              PopupMenuButton<String>(
                key: const ValueKey('dog-detail-menu'),
                onSelected: (choice) => showReportSheet(
                  context,
                  targetType: choice == 'dog'
                      ? ReportTargetType.dog
                      : ReportTargetType.shelter,
                  targetId: choice == 'dog'
                      ? value.dog.id
                      : value.dog.shelterId,
                  title: choice == 'dog'
                      ? 'Denunciar publicación'
                      : 'Denunciar refugio',
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'dog',
                    child: Text('Denunciar publicación'),
                  ),
                  PopupMenuItem(
                    value: 'shelter',
                    child: Text('Denunciar refugio'),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: detail.when(
            loading: () => const WoofyLoading(
              message: 'Cargando información del perrito…',
            ),
            error: (error, stackTrace) => WoofyError(
              message: 'No pudimos cargar este perrito.',
              onRetry: () => ref.invalidate(dogDetailProvider(slug)),
            ),
            data: (value) => value == null
                ? const WoofyEmptyState(
                    title: 'Perrito no disponible',
                    message: 'Este perrito no está disponible.',
                  )
                : _DogDetailContent(detail: value),
          ),
        ),
      ),
    );
  }
}

class _DogDetailContent extends ConsumerWidget {
  const _DogDetailContent({required this.detail});

  final DogDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dog = detail.dog;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DogPhotoCarousel(photos: dog.photos),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dog.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  FavoriteToggleButton(dogId: dog.id),
                ],
              ),
              const SizedBox(height: 12),
              _DogChips(dog: dog, breed: detail.breed),
              if (dog.story.isNotEmpty) ...[
                const SizedBox(height: 24),
                _TextSection(title: 'Su historia', body: dog.story),
              ],
              if (_compatibilityItems(dog).isNotEmpty) ...[
                const SizedBox(height: 16),
                _CompatibilityCard(items: _compatibilityItems(dog)),
              ],
              if (_detailItems(detail).isNotEmpty) ...[
                const SizedBox(height: 16),
                _DetailsCard(items: _detailItems(detail)),
              ],
              if (dog.shelter case final shelter?) ...[
                const SizedBox(height: 16),
                DogShelterSection(shelter: shelter),
              ],
              if (detail.medicalEvents.isNotEmpty) ...[
                const SizedBox(height: 16),
                DogMedicalEventsSection(events: detail.medicalEvents),
              ],
              const SizedBox(height: 24),
              _ApplicationAction(dog: dog),
              const SizedBox(height: 12),
              _InquiryButton(dog: dog),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationAction extends ConsumerWidget {
  const _ApplicationAction({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProvider) == null) {
      return WoofyButton(
        label: 'Iniciar sesión para postular',
        onPressed: () => context.go(RoutePaths.auth),
        icon: Icons.login_rounded,
        isExpanded: true,
      );
    }
    return ref
        .watch(currentDogApplicationProvider(dog.id))
        .when(
          loading: () => const WoofyButton(
            label: 'Revisando postulación…',
            onPressed: null,
            isLoading: true,
            isExpanded: true,
          ),
          error: (_, _) => WoofyButton(
            label: 'Reintentar estado de postulación',
            onPressed: () =>
                ref.invalidate(currentDogApplicationProvider(dog.id)),
            variant: WoofyButtonVariant.secondary,
            isExpanded: true,
          ),
          data: (application) => application == null
              ? WoofyButton(
                  label: 'Postular a ${dog.name}',
                  onPressed: () =>
                      context.push(RoutePaths.applicationForm(dog.slug)),
                  icon: Icons.favorite_outline,
                  isExpanded: true,
                )
              : ApplicationStatusCard(
                  application: application,
                  action: _WriteToShelterButton(dogId: dog.id),
                ),
        );
  }
}

class _WriteToShelterButton extends ConsumerWidget {
  const _WriteToShelterButton({required this.dogId});

  final String dogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpening = ref.watch(dogConversationControllerProvider(dogId));

    return WoofyButton(
      label: isOpening ? 'Abriendo conversación…' : 'Escribir al refugio',
      onPressed: isOpening
          ? null
          : () async {
              try {
                final thread = await ref
                    .read(dogConversationControllerProvider(dogId).notifier)
                    .open();
                if (!context.mounted || thread == null) return;
                context.push(RoutePaths.conversation(thread.id));
              } catch (error) {
                if (!context.mounted) return;
                final message = error is AppException
                    ? error.message
                    : 'No pudimos abrir esta conversación.';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
      icon: Icons.chat_bubble_outline,
      variant: WoofyButtonVariant.secondary,
    );
  }
}

class _InquiryButton extends ConsumerWidget {
  const _InquiryButton({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isOpening = ref.watch(dogInquiryControllerProvider(dog.id));

    return WoofyButton(
      label: isOpening ? 'Abriendo conversación…' : 'Consultar',
      isLoading: isOpening,
      isExpanded: true,
      variant: WoofyButtonVariant.secondary,
      icon: Icons.chat_bubble_outline,
      onPressed: isOpening
          ? null
          : () async {
              if (user == null) {
                context.go(RoutePaths.auth);
                return;
              }
              final router = GoRouter.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final thread = await ref
                    .read(dogInquiryControllerProvider(dog.id).notifier)
                    .open();
                if (thread == null) return;
                router.push(RoutePaths.conversation(thread.id));
              } catch (error) {
                final message = error is AppException
                    ? error.message
                    : 'No pudimos abrir esta conversación.';
                messenger.showSnackBar(SnackBar(content: Text(message)));
              }
            },
    );
  }
}

class _DogChips extends StatelessWidget {
  const _DogChips({required this.dog, required this.breed});

  final Dog dog;
  final String? breed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (dog.ageLabel case final age?)
          DogInfoChip(label: age, icon: Icons.cake_outlined),
        if (dog.size case final size?)
          DogInfoChip(label: size, icon: Icons.straighten),
        if (dog.sex case final sex?)
          DogInfoChip(label: sex, icon: Icons.pets_outlined),
        if (breed case final breedName?)
          DogInfoChip(label: breedName, icon: Icons.badge_outlined),
        if (dog.energyLevel case final energy?)
          DogInfoChip(label: energy, icon: Icons.bolt_outlined),
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(body),
        ],
      ),
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compatibilidad', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuidados y hogar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          for (final (label, value) in items) ...[
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 3),
            Text(value),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

List<String> _compatibilityItems(Dog dog) => [
  if (dog.goodWithChildren == true) 'Convive con niños',
  if (dog.goodWithDogs == true) 'Convive con perros',
  if (dog.goodWithCats == true) 'Convive con gatos',
];

List<(String, String)> _detailItems(DogDetail detail) => [
  if (detail.idealHome case final value?) ('Hogar ideal', value),
  if (detail.specialCare case final value?) ('Cuidados especiales', value),
  if (detail.feedingNotes case final value?) ('Alimentación', value),
  if (detail.behaviorNotes case final value?) ('Comportamiento', value),
  if (detail.currentTreatment case final value?) ('Tratamiento actual', value),
  if (detail.knownConditions case final value?)
    ('Condiciones conocidas', value),
  if (detail.extraNotes case final value?) ('Información adicional', value),
];
