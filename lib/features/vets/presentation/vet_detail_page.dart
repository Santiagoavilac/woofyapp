import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/vets/data/cart_provider.dart';
import 'package:woofy/features/vets/data/vet_models.dart';
import 'package:woofy/features/vets/data/vet_repository_provider.dart';
import 'package:woofy/features/vets/data/whatsapp_message.dart';
import 'package:woofy/features/vets/presentation/widgets/vet_card.dart';
import 'package:woofy/features/vets/presentation/widgets/vet_cart_summary_bar.dart';
import 'package:woofy/features/vets/presentation/widgets/vet_product_card.dart';
import 'package:woofy/features/vets/presentation/widgets/vet_service_tile.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_section_header.dart';

/// Perfil de una veterinaria: portada, datos de contacto, productos y
/// servicios reservables.
class VetDetailPage extends ConsumerWidget {
  const VetDetailPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(vetDetailProvider(slug));

    return Scaffold(
      appBar: WoofyAppBar(
        title: detail.value?.vet.name ?? 'Veterinaria',
        backFallbackLocation: RoutePaths.vets,
        actions: [
          IconButton(
            key: const ValueKey('vet-detail-cart-button'),
            tooltip: 'Mi carrito',
            onPressed: () => context.push(RoutePaths.vetCart),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const WoofyLoading(message: 'Cargando veterinaria…'),
          error: (error, stackTrace) => WoofyError(
            message: 'No pudimos cargar esta veterinaria.',
            onRetry: () => ref.invalidate(vetDetailProvider(slug)),
          ),
          data: (data) {
            if (data == null) {
              return WoofyEmptyState(
                icon: Icons.local_hospital_outlined,
                title: 'Veterinaria no disponible',
                message: 'Puede que ya no esté activa en Woofy.',
                actionLabel: 'Ver todas',
                onAction: () => context.go(RoutePaths.vets),
              );
            }
            return _VetDetailBody(detail: data);
          },
        ),
      ),
      bottomNavigationBar: const VetCartSummaryBar(),
    );
  }
}

class _VetDetailBody extends ConsumerWidget {
  const _VetDetailBody({required this.detail});

  final VetDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vet = detail.vet;
    final cartLines = ref.watch(cartProvider)[vet.id]?.lines ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WoofySpacing.lg,
        WoofySpacing.lg,
        WoofySpacing.lg,
        WoofySpacing.huge,
      ),
      children: [
        ClipRRect(
          borderRadius: WoofyRadius.cardLargeAll,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: WoofyColors.primarySoft,
              child: VetImage(url: vet.coverImageUrl ?? vet.profileImageUrl),
            ),
          ),
        ),
        const SizedBox(height: WoofySpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(vet.name, style: theme.textTheme.headlineSmall),
            ),
            if (vet.verified)
              const Icon(Icons.verified_rounded, color: WoofyColors.primary),
          ],
        ),
        if ([vet.address, vet.city].whereType<String>().isNotEmpty) ...[
          const SizedBox(height: WoofySpacing.xs),
          Text(
            [vet.address, vet.city].whereType<String>().join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (vet.locationNotes case final notes?) ...[
          const SizedBox(height: WoofySpacing.xs),
          Text(notes, style: theme.textTheme.bodySmall),
        ],
        if (vet.description case final description?) ...[
          const SizedBox(height: WoofySpacing.md),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: WoofySpacing.lg),
        Row(
          children: [
            if (vet.whatsappPhone != null)
              Expanded(
                child: WoofyButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  onPressed: () => _openWhatsapp(context, vet),
                ),
              ),
            if (vet.whatsappPhone != null)
              const SizedBox(width: WoofySpacing.sm),
            Expanded(
              child: WoofyButton(
                label: 'Cómo llegar',
                icon: Icons.map_outlined,
                variant: WoofyButtonVariant.secondary,
                onPressed: () => _open(context, WhatsappMessage.mapsUri(vet)),
              ),
            ),
          ],
        ),
        if (detail.products.isNotEmpty) ...[
          const SizedBox(height: WoofySpacing.xxl),
          const WoofySectionHeader(
            title: 'Productos',
            subtitle: 'Agregá al carrito y coordinás la entrega por WhatsApp.',
          ),
          const SizedBox(height: WoofySpacing.md),
          for (final product in detail.products) ...[
            VetProductCard(
              product: product,
              inCart: cartLines
                  .where((line) => line.productId == product.id)
                  .fold(0, (total, line) => total + line.quantity),
              onOpen: () =>
                  context.push(RoutePaths.vetProduct(vet.slug, product.id)),
              onAdd: () {
                ref.read(cartProvider.notifier).add(vet, product);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${product.name} va al carrito'),
                      action: SnackBarAction(
                        label: 'Ver carrito',
                        onPressed: () => context.push(RoutePaths.vetCart),
                      ),
                    ),
                  );
              },
            ),
            const SizedBox(height: WoofySpacing.sm),
          ],
        ],
        if (detail.services.isNotEmpty) ...[
          const SizedBox(height: WoofySpacing.xxl),
          const WoofySectionHeader(
            title: 'Servicios',
            subtitle: 'Elegí un servicio y reservá el turno.',
          ),
          const SizedBox(height: WoofySpacing.md),
          for (final service in detail.services) ...[
            VetServiceTile(
              service: service,
              onReserve: () => context.push(
                RoutePaths.vetReservation(vet.slug),
                extra: service.id,
              ),
            ),
            const SizedBox(height: WoofySpacing.sm),
          ],
        ],
        if (detail.products.isEmpty && detail.services.isEmpty) ...[
          const SizedBox(height: WoofySpacing.xxl),
          const WoofyEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Catálogo en camino',
            message:
                'Esta veterinaria todavía no cargó productos ni servicios.',
          ),
        ],
      ],
    );
  }

  Future<void> _openWhatsapp(BuildContext context, Vet vet) async {
    final uri = WhatsappMessage.buildUri(
      phone: vet.whatsappPhone,
      message: '¡Hola ${vet.name}! Te escribo desde Woofy.',
    );
    if (uri == null) {
      _warn(context, 'El número de WhatsApp no es válido.');
      return;
    }
    await _open(context, uri);
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _warn(context, 'No pudimos abrir el enlace.');
    }
  }

  void _warn(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
