import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

/// Historial de pedidos del usuario, de la tienda de Woofy y de las
/// veterinarias por igual.
///
/// El pedido se guarda antes de abrir WhatsApp, así que esta pantalla es el
/// registro real: si el chat se pierde, la compra sigue estando acá.
class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myPartnerOrdersProvider);

    return Scaffold(
      appBar: WoofyAppBar(
        title: 'Mis pedidos',
        backFallbackLocation: RoutePaths.profile,
      ),
      body: SafeArea(
        child: orders.when(
          loading: () => const WoofyLoading(message: 'Cargando tus pedidos…'),
          error: (error, stackTrace) => WoofyError(
            message: 'No pudimos cargar tus pedidos.',
            onRetry: () => ref.invalidate(myPartnerOrdersProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return WoofyEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Todavía no hiciste pedidos',
                message:
                    'Cuando compres en la tienda de Woofy o en una veterinaria, '
                    'lo vas a ver acá.',
                actionLabel: 'Ver la tienda',
                onAction: () => context.push(RoutePaths.store),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(WoofySpacing.lg),
              itemCount: list.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: WoofySpacing.lg),
              itemBuilder: (context, index) => _OrderCard(order: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final PartnerOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = order.createdAt;

    return WoofyCard(
      key: ValueKey('order-${order.id}'),
      padding: const EdgeInsets.all(WoofySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.partnerName ?? 'Pedido',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          if (createdAt != null) ...[
            const SizedBox(height: WoofySpacing.xs),
            Text(
              DateFormat("d 'de' MMMM 'de' y", 'es').format(createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: WoofySpacing.md),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: WoofySpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.sizeSnapshot == null
                          ? '${item.quantity}x ${item.nameSnapshot}'
                          : '${item.quantity}x ${item.nameSnapshot} · '
                                'Talle ${item.sizeSnapshot}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    Money.fromCents(item.lineTotalCents),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleSmall),
              Text(
                Money.fromCents(order.totalCents),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: WoofyColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  static const _labels = {
    'pending': 'Pendiente',
    'confirmed': 'Confirmado',
    'completed': 'Entregado',
    'cancelled': 'Cancelado',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = status == 'cancelled';
    return Chip(
      label: Text(_labels[status] ?? status),
      labelStyle: theme.textTheme.labelSmall,
      backgroundColor: isCancelled
          ? theme.colorScheme.errorContainer
          : WoofyColors.primarySoft,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
