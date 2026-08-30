import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/data/whatsapp_message.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';

/// Carrito agrupado por veterinaria: un bloque y un botón "Comprar" por cada
/// una, porque cada pedido va a un WhatsApp distinto.
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  /// Veterinaria cuyo pedido se está confirmando, para bloquear solo ese botón.
  String? _submittingVetId;

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(cartProvider).values.toList();

    return Scaffold(
      appBar: WoofyAppBar(
        title: 'Mi carrito',
        backFallbackLocation: RoutePaths.vets,
        actions: [
          if (groups.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Vaciar'),
            ),
        ],
      ),
      body: SafeArea(
        child: groups.isEmpty
            ? WoofyEmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Tu carrito está vacío',
                message:
                    'Agregá productos desde una veterinaria o desde la tienda '
                    'de Woofy.',
                actionLabel: 'Ver veterinarias',
                onAction: () => context.go(RoutePaths.vets),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(WoofySpacing.lg),
                itemCount: groups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: WoofySpacing.lg),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _CartGroupCard(
                    group: group,
                    isSubmitting: _submittingVetId == group.partnerId,
                    // Mientras se confirma un pedido los demás botones quedan
                    // apagados: dos RPC en paralelo sobre el mismo carrito son
                    // pedido duplicado asegurado.
                    isBlocked:
                        _submittingVetId != null &&
                        _submittingVetId != group.partnerId,
                    onCheckout: () => _checkout(group),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _checkout(CartGroup group) async {
    if (_submittingVetId != null) return;

    // El carrito se arma sin cuenta, pero el pedido guarda una fila con
    // `user_id`: el login se pide recién acá.
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push(RoutePaths.auth);
      return;
    }

    setState(() => _submittingVetId = group.partnerId);
    try {
      // Primero el registro, después WhatsApp. Al revés se perderían pedidos
      // cuando el RPC falla y el usuario ya mandó el mensaje.
      final order = await ref
          .read(partnerRepositoryProvider)
          .createOrder(
            partnerId: group.partnerId,
            items: [
              for (final line in group.lines)
                (
                  productId: line.productId,
                  variantId: line.variantId,
                  quantity: line.quantity,
                ),
            ],
          );

      if (!mounted) return;

      final uri = WhatsappMessage.buildUri(
        phone: group.whatsappPhone,
        message: WhatsappMessage.orderText(
          partnerName: group.partnerName,
          lines: [
            for (final item in order.items)
              (
                name: item.nameSnapshot,
                sizeLabel: item.sizeSnapshot,
                quantity: item.quantity,
                unitPriceCents: item.unitPriceCents,
              ),
          ],
          totalCents: order.totalCents,
        ),
      );

      ref.read(cartProvider.notifier).clearVet(group.partnerId);
      ref.invalidate(myPartnerOrdersProvider);

      if (uri == null) {
        _notify(
          'Pedido registrado. La veterinaria no tiene WhatsApp cargado, '
          'te va a contactar por otro medio.',
        );
        return;
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) {
        _notify('Pedido registrado, pero no pudimos abrir WhatsApp.');
      }
    } on AppException catch (error) {
      if (mounted) _notify(error.message);
    } catch (_) {
      if (mounted) _notify('No pudimos registrar el pedido.');
    } finally {
      if (mounted) setState(() => _submittingVetId = null);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CartGroupCard extends ConsumerWidget {
  const _CartGroupCard({
    required this.group,
    required this.isSubmitting,
    required this.isBlocked,
    required this.onCheckout,
  });

  final CartGroup group;
  final bool isSubmitting;
  final bool isBlocked;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.read(cartProvider.notifier);

    return WoofyCard(
      key: ValueKey('cart-group-${group.partnerId}'),
      padding: const EdgeInsets.all(WoofySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.partnerName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push(RoutePaths.partnerDetail(group.vetSlug)),
                child: const Text('Ver perfil'),
              ),
            ],
          ),
          const SizedBox(height: WoofySpacing.sm),
          for (final line in group.lines) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: WoofyRadius.controlAll,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: ColoredBox(
                      color: WoofyColors.surfaceMuted,
                      child: PartnerImage(
                        url: line.imageUrl,
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: WoofySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (line.sizeLabel case final size?)
                        Text(
                          'Talle $size',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        Money.fromCents(line.lineTotalCents),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: WoofyColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('cart-decrement-${line.lineKey}'),
                  tooltip: 'Quitar uno',
                  onPressed: () =>
                      cart.decrement(group.partnerId, line.lineKey),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${line.quantity}', style: theme.textTheme.titleSmall),
                IconButton(
                  key: ValueKey('cart-increment-${line.lineKey}'),
                  tooltip: 'Agregar uno',
                  onPressed: () =>
                      cart.increment(group.partnerId, line.lineKey),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: WoofySpacing.sm),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleSmall),
              Text(
                Money.fromCents(group.totalCents),
                key: ValueKey('cart-total-${group.partnerId}'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: WoofyColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: WoofySpacing.md),
          WoofyButton(
            key: ValueKey('cart-checkout-${group.partnerId}'),
            label: 'Comprar',
            icon: Icons.shopping_bag_rounded,
            isExpanded: true,
            isLoading: isSubmitting,
            onPressed: isBlocked ? null : onCheckout,
          ),
        ],
      ),
    );
  }
}
