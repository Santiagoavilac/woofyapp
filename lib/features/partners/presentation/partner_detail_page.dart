import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/data/whatsapp_message.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/features/partners/presentation/widgets/cart_summary_bar.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_product_card.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_service_tile.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_brand_button.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_section_header.dart';

/// Perfil de una veterinaria: portada, datos de contacto, productos y
/// servicios reservables.
class PartnerDetailPage extends ConsumerWidget {
  const PartnerDetailPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(partnerDetailProvider(slug));

    return Scaffold(
      appBar: WoofyAppBar(
        title: detail.value?.partner.name ?? 'Veterinaria',
        backFallbackLocation: RoutePaths.vets,
        actions: [
          IconButton(
            key: const ValueKey('vet-detail-cart-button'),
            tooltip: 'Mi carrito',
            onPressed: () => context.push(RoutePaths.cart),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const WoofyLoading(message: 'Cargando veterinaria…'),
          error: (error, stackTrace) => WoofyError(
            message: 'No pudimos cargar esta veterinaria.',
            onRetry: () => ref.invalidate(partnerDetailProvider(slug)),
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
            return _PartnerDetailBody(detail: data);
          },
        ),
      ),
      bottomNavigationBar: const CartSummaryBar(),
    );
  }
}

class _PartnerDetailBody extends ConsumerStatefulWidget {
  const _PartnerDetailBody({required this.detail});

  final PartnerDetail detail;

  @override
  ConsumerState<_PartnerDetailBody> createState() => _PartnerDetailBodyState();
}

class _PartnerDetailBodyState extends ConsumerState<_PartnerDetailBody>
    with WoofyRefreshMixin {
  @override
  Future<void> onWoofyRefresh() async {
    final slug = widget.detail.partner.slug;
    ref.invalidate(partnerDetailProvider(slug));
    await ref.read(partnerDetailProvider(slug).future);
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final theme = Theme.of(context);
    final partner = detail.partner;
    final cartLines = ref.watch(cartProvider)[partner.id]?.lines ?? const [];

    return CustomScrollView(
      slivers: [
        WoofyRefreshControl(onRefresh: refreshData),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            WoofySpacing.lg,
            WoofySpacing.lg,
            WoofySpacing.lg,
            WoofySpacing.huge,
          ),
          sliver: SliverList.list(
            children: [
              ClipRRect(
                borderRadius: WoofyRadius.cardLargeAll,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ColoredBox(
                    color: WoofyColors.primarySoft,
                    child: PartnerImage(
                      url: partner.coverImageUrl ?? partner.profileImageUrl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: WoofySpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partner.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (partner.verified)
                    const Icon(
                      Icons.verified_rounded,
                      color: WoofyColors.primary,
                    ),
                ],
              ),
              if ([
                partner.address,
                partner.city,
              ].whereType<String>().isNotEmpty) ...[
                const SizedBox(height: WoofySpacing.xs),
                Text(
                  [
                    partner.address,
                    partner.city,
                  ].whereType<String>().join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (partner.locationNotes case final notes?) ...[
                const SizedBox(height: WoofySpacing.xs),
                Text(notes, style: theme.textTheme.bodySmall),
              ],
              if (partner.description case final description?) ...[
                const SizedBox(height: WoofySpacing.md),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: WoofySpacing.lg),
              Row(
                children: [
                  if (partner.whatsappPhone != null)
                    Expanded(
                      child: WoofyBrandButton(
                        brand: WoofyBrand.whatsapp,
                        label: 'WhatsApp',
                        onPressed: () => _openWhatsapp(context, partner),
                      ),
                    ),
                  if (partner.whatsappPhone != null)
                    const SizedBox(width: WoofySpacing.sm),
                  Expanded(
                    child: WoofyButton(
                      label: 'Cómo llegar',
                      icon: Icons.map_outlined,
                      variant: WoofyButtonVariant.secondary,
                      onPressed: () =>
                          _open(context, WhatsappMessage.mapsUri(partner)),
                    ),
                  ),
                ],
              ),
              if (detail.products.isNotEmpty) ...[
                const SizedBox(height: WoofySpacing.xxl),
                const WoofySectionHeader(
                  title: 'Productos',
                  subtitle:
                      'Agregá al carrito y coordinás la entrega por WhatsApp.',
                ),
                const SizedBox(height: WoofySpacing.md),
                for (final product in detail.products) ...[
                  PartnerProductCard(
                    product: product,
                    inCart: cartLines
                        .where((line) => line.productId == product.id)
                        .fold(0, (total, line) => total + line.quantity),
                    onOpen: () => context.push(
                      RoutePaths.partnerProduct(partner.slug, product.id),
                    ),
                    onAdd: () {
                      ref.read(cartProvider.notifier).add(partner, product);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('${product.name} va al carrito'),
                            action: SnackBarAction(
                              label: 'Ver carrito',
                              onPressed: () => context.push(RoutePaths.cart),
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
                  PartnerServiceTile(
                    service: service,
                    onReserve: () => context.push(
                      RoutePaths.partnerReservation(partner.slug),
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
          ),
        ),
      ],
    );
  }

  Future<void> _openWhatsapp(BuildContext context, Partner partner) async {
    final uri = WhatsappMessage.buildUri(
      phone: partner.whatsappPhone,
      message: '¡Hola ${partner.name}! Te escribo desde Woofy.',
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
