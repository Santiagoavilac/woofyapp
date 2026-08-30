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
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/presentation/widgets/report_sheet.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/applications/presentation/widgets/application_status_card.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/favorites/presentation/widgets/double_tap_like.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/shared/widgets/woofy_circle_icon_button.dart';

class DogDetailPage extends ConsumerWidget {
  const DogDetailPage({required this.slug, super.key});

  static const _title = 'Perfil del perrito';

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dogDetailProvider(slug));
    return BackFallbackScope(
      fallbackLocation: RoutePaths.dogs,
      child: detail.when(
        loading: () => const _PlainDetailScaffold(
          title: _title,
          child: WoofyLoading(message: 'Cargando información del perrito…'),
        ),
        error: (error, stackTrace) => _PlainDetailScaffold(
          title: _title,
          child: WoofyError(
            message: 'No pudimos cargar este perrito.',
            onRetry: () => ref.invalidate(dogDetailProvider(slug)),
          ),
        ),
        data: (value) => value == null
            ? const _PlainDetailScaffold(
                title: _title,
                child: WoofyEmptyState(
                  title: 'Perrito no disponible',
                  message: 'Este perrito no está disponible.',
                ),
              )
            : _DogDetailContent(detail: value),
      ),
    );
  }
}

/// Loading / error / missing states keep the ordinary app bar: there is no
/// photo yet to build the immersive hero on.
class _PlainDetailScaffold extends StatelessWidget {
  const _PlainDetailScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WoofyAppBar(title: title),
      body: SafeArea(child: child),
    );
  }
}

class _DogDetailContent extends ConsumerStatefulWidget {
  const _DogDetailContent({required this.detail});

  /// Radius of the curve where the hero photo meets the content panel.
  static const _panelOverlap = 28.0;

  final DogDetail detail;

  @override
  ConsumerState<_DogDetailContent> createState() => _DogDetailContentState();
}

class _DogDetailContentState extends ConsumerState<_DogDetailContent>
    with WoofyRefreshMixin {
  @override
  Future<void> onWoofyRefresh() async {
    final slug = widget.detail.dog.slug;
    ref.invalidate(dogDetailProvider(slug));
    await ref.read(dogDetailProvider(slug).future);
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final dog = detail.dog;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          WoofyRefreshControl(onRefresh: refreshData),
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            expandedHeight: 380 + topInset,
            backgroundColor: WoofyColors.primarySoft,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(DogDetailPage._title),
            leadingWidth: 56 + WoofySpacing.sm,
            leading: Padding(
              padding: const EdgeInsets.only(left: WoofySpacing.sm),
              child: Center(
                child: WoofyCircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Volver',
                  onPressed: () => Navigator.canPop(context)
                      ? Navigator.pop(context)
                      : context.go(RoutePaths.dogs),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: WoofySpacing.sm),
                child: Center(
                  child: Material(
                    color: WoofyColors.white,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: PopupMenuButton<String>(
                      key: const ValueKey('dog-detail-menu'),
                      tooltip: 'Más opciones',
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: WoofyColors.textPrimary,
                      ),
                      onSelected: (choice) => showReportSheet(
                        context,
                        targetType: choice == 'dog'
                            ? ReportTargetType.dog
                            : ReportTargetType.shelter,
                        targetId: choice == 'dog' ? dog.id : dog.shelterId,
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
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              // No parallax: the photo must stay below the toolbar band, or
              // it slides under the title and swallows it while collapsing.
              collapseMode: CollapseMode.none,
              background: _DogHero(dog: dog, topInset: topInset),
            ),
          ),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: WoofyColors.background,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WoofySpacing.lg,
                  WoofySpacing.xxl,
                  WoofySpacing.lg,
                  WoofySpacing.xxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: _DogDetailBody(detail: detail),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DetailActionBar(dog: dog),
    );
  }
}

/// Hero band: the photo sits below the floating controls so the title and the
/// circular buttons always land on flat colour, never on the picture.
class _DogHero extends StatelessWidget {
  const _DogHero({required this.dog, required this.topInset});

  final Dog dog;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WoofyColors.primarySoft,
      child: Padding(
        padding: EdgeInsets.only(top: topInset + kToolbarHeight),
        // Panel colour behind the photo, so its rounded bottom reads as the
        // content panel rising over the hero.
        child: ColoredBox(
          color: WoofyColors.background,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(_DogDetailContent._panelOverlap),
            ),
            child: DoubleTapLike(
              dogId: dog.id,
              child: DogPhotoCarousel(photos: dog.photos, heroSlug: dog.slug),
            ),
          ),
        ),
      ),
    );
  }
}

class _DogDetailBody extends ConsumerWidget {
  const _DogDetailBody({required this.detail});

  final DogDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dog = detail.dog;
    // El orden es a propósito: primero quién es, después los datos. La historia
    // arriba de las características es lo que hace que la ficha se lea como la
    // presentación de un perro y no como una planilla.
    //
    // Sigue siendo una `Column` y no slivers: el cuerpo se construye entero, y
    // de eso dependen los tests que buscan texto que queda fuera de pantalla.
    return WoofyStaggeredColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (dog.story.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: WoofySpacing.lg),
            child: _TextSection(title: 'Su historia', body: dog.story),
          ),
        Padding(
          padding: const EdgeInsets.only(top: WoofySpacing.lg),
          child: _AttributesCard(dog: dog, breed: detail.breed),
        ),
        if (_compatibilityItems(dog).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: WoofySpacing.lg),
            child: _CompatibilityCard(items: _compatibilityItems(dog)),
          ),
        if (_detailItems(detail).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: WoofySpacing.lg),
            child: _DetailsCard(items: _detailItems(detail)),
          ),
        if (detail.medicalEvents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: WoofySpacing.lg),
            child: DogMedicalEventsSection(events: detail.medicalEvents),
          ),
        if (dog.shelter case final shelter?)
          Padding(
            padding: const EdgeInsets.only(top: WoofySpacing.lg),
            child: DogShelterSection(shelter: shelter),
          ),
        // The adoption CTA lives in the pinned bottom bar, but an existing
        // application shows a full status card that is far too tall to pin.
        if (ref.watch(currentUserProvider) != null)
          ref
              .watch(currentDogApplicationProvider(dog.id))
              .maybeWhen(
                data: (application) => application == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: WoofySpacing.lg),
                        child: ApplicationStatusCard(
                          application: application,
                          action: _WriteToShelterButton(dogId: dog.id),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
      ],
    );
  }
}

/// Quick facts, grouped in one muted panel instead of loose chips.
class _AttributesCard extends StatelessWidget {
  const _AttributesCard({required this.dog, required this.breed});

  final Dog dog;
  final String? breed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: WoofyColors.surfaceMuted,
        borderRadius: WoofyRadius.cardAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(WoofySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Características',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: WoofySpacing.md),
            _DogChips(dog: dog, breed: breed),
          ],
        ),
      ),
    );
  }
}

/// Pinned adoption actions. Sits on its own surface so it stays readable over
/// whatever scrolls behind it.
class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: WoofyColors.surface,
        border: Border(top: BorderSide(color: WoofyColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WoofySpacing.lg,
            WoofySpacing.md,
            WoofySpacing.lg,
            WoofySpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ApplicationAction(dog: dog),
              const SizedBox(height: WoofySpacing.sm),
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
    // La key es el estado, nunca el contenido. Si dependiera del texto, cada
    // vez que cambia una palabra el botón se funde consigo mismo y parpadea.
    final ({String state, Widget child}) action = _action(context, ref);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(action.state), child: action.child),
    );
  }

  ({String state, Widget child}) _action(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProvider) == null) {
      return (
        state: 'anon',
        child: WoofyButton(
          label: 'Iniciar sesión para postular',
          onPressed: () => context.go(RoutePaths.auth),
          icon: Icons.login_rounded,
          isExpanded: true,
        ),
      );
    }
    return ref
        .watch(currentDogApplicationProvider(dog.id))
        .when(
          loading: () => (
            state: 'loading',
            child: const WoofyButton(
              label: 'Revisando postulación…',
              onPressed: null,
              isLoading: true,
              isExpanded: true,
            ),
          ),
          error: (_, _) => (
            state: 'error',
            child: WoofyButton(
              label: 'Reintentar estado de postulación',
              onPressed: () =>
                  ref.invalidate(currentDogApplicationProvider(dog.id)),
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
            ),
          ),
          // Already applied: the status card renders inline in the scroll
          // body, so the pinned bar has nothing to show here.
          data: (application) => application == null
              ? (
                  state: 'apply',
                  child: WoofyButton(
                    label: 'Postular a ${dog.name}',
                    onPressed: () =>
                        context.push(RoutePaths.applicationForm(dog.slug)),
                    icon: Icons.favorite_outline,
                    isExpanded: true,
                  ),
                )
              : (state: 'applied', child: const SizedBox.shrink()),
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
    final chips = <Widget>[
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
    ];
    // Los datos duros entran de a uno: leídos en cascada se sienten pocos y
    // ordenados, todos juntos se sienten una planilla.
    return WoofyRevealGroup(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < chips.length; index++)
            WoofyReveal.indexed(index: index, child: chips[index]),
        ],
      ),
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
