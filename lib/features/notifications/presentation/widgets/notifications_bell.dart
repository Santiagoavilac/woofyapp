import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/notifications/data/notification_models.dart';
import 'package:woofy/features/notifications/data/notifications_providers.dart';
import 'package:woofy/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:woofy/shared/widgets/woofy_circle_icon_button.dart';
import 'package:woofy/shared/widgets/woofy_count_badge.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';

/// La campana de Inicio y su panel de novedades.
///
/// El panel es un [OverlayPortal] y no una ruta a propósito: así no entra al
/// historial de back, no obliga a tocar los respaldos de navegación y puede
/// crecer desde la campana, que es lo que hace que se lea como "esto salió de
/// acá" y no como una pantalla nueva.
class NotificationsBell extends ConsumerStatefulWidget {
  const NotificationsBell({super.key});

  @override
  ConsumerState<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends ConsumerState<NotificationsBell>
    with SingleTickerProviderStateMixin {
  final _portalController = OverlayPortalController();
  final _link = LayerLink();
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String userId) {
    _portalController.show();
    _controller.forward(from: 0);
    // Abrir el panel deja de contar como novedad los cambios de postulación,
    // que no tienen dónde anotarse en la base. Los mensajes NO se tocan acá:
    // esos se marcan leídos al abrir la conversación, porque abrir el panel no
    // es leer lo que dice adentro.
    ref
        .read(notificationsSeenControllerProvider(userId).notifier)
        .markAllSeen();
  }

  Future<void> _close() async {
    if (!_portalController.isShowing) return;
    await _controller.reverse();
    if (mounted && _portalController.isShowing) _portalController.hide();
  }

  void _openNotification(WoofyNotification notification) {
    final router = GoRouter.of(context);
    _close();
    router.push(notification.route);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    // Sin sesión la campana lleva a iniciar sesión: no hay novedades de nadie.
    if (userId == null) {
      return WoofyCircleIconButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'Notificaciones',
        onPressed: () => context.push(RoutePaths.auth),
      );
    }

    final count = ref.watch(unreadNotificationsCountProvider(userId));

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (overlayContext) => _NotificationsOverlay(
        userId: userId,
        link: _link,
        animation: _controller,
        onClose: _close,
        onOpenNotification: _openNotification,
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: WoofyCountBadge(
          count: count,
          child: WoofyCircleIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notificaciones',
            onPressed: () =>
                _portalController.isShowing ? _close() : _open(userId),
          ),
        ),
      ),
    );
  }
}

class _NotificationsOverlay extends ConsumerWidget {
  const _NotificationsOverlay({
    required this.userId,
    required this.link,
    required this.animation,
    required this.onClose,
    required this.onOpenNotification,
  });

  final String userId;
  final LayerLink link;
  final Animation<double> animation;
  final VoidCallback onClose;
  final ValueChanged<WoofyNotification> onOpenNotification;

  static const _maxWidth = 380.0;
  static const _maxHeight = 460.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final width = math.min(size.width - WoofySpacing.xxxl, _maxWidth);
    final height = math.min(size.height * 0.6, _maxHeight);

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Con movimiento reducido el panel aparece entero: nunca a medio pintar.
    final progress = reduceMotion ? kAlwaysCompleteAnimation : curved;

    return PopScope(
      canPop: false,
      // Se come el back de Android antes que cualquier respaldo de navegación:
      // el back de un panel abierto cierra el panel, no cambia de pantalla.
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onClose();
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                onClose();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: FadeTransition(
                      opacity: progress,
                      child: const ColoredBox(color: Color(0x47000000)),
                    ),
                  ),
                ),
                // Sin `Align` adentro: el seguidor ancla el borde derecho de su
                // hijo, y un `Align` se estira a toda la pantalla, así que
                // anclaba el borde derecho de la pantalla y el panel terminaba
                // corrido hacia la izquierda.
                CompositedTransformFollower(
                  link: link,
                  targetAnchor: Alignment.bottomRight,
                  followerAnchor: Alignment.topRight,
                  offset: const Offset(0, WoofySpacing.sm),
                  child: FadeTransition(
                    opacity: progress,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.94,
                        end: 1,
                      ).animate(progress),
                      // Crece desde la esquina de la campana, no desde el
                      // centro: así se lee como que salió de ahí.
                      alignment: Alignment.topRight,
                      child: _PanelCard(
                        userId: userId,
                        width: width,
                        maxHeight: height,
                        onOpenNotification: onOpenNotification,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends ConsumerWidget {
  const _PanelCard({
    required this.userId,
    required this.width,
    required this.maxHeight,
    required this.onOpenNotification,
  });

  final String userId;
  final double width;
  final double maxHeight;
  final ValueChanged<WoofyNotification> onOpenNotification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider(userId));
    return Material(
      color: WoofyColors.white,
      elevation: 10,
      shadowColor: const Color(0x1F1B2A33),
      borderRadius: WoofyRadius.cardAll,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        key: const ValueKey('notifications-panel'),
        // Alto al contenido, con techo: con una sola novedad el panel medía
        // media pantalla de blanco vacío. Se estira solo cuando hay de qué.
        constraints: BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: 120,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WoofySpacing.lg,
                WoofySpacing.lg,
                WoofySpacing.lg,
                WoofySpacing.sm,
              ),
              child: Text(
                'Novedades',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            // `Flexible` y no `Expanded`: la columna mide al contenido, así que
            // el cuerpo toma lo que necesita hasta el techo, no todo el alto.
            Flexible(
              child: notifications.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, _) => const _PanelMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'No pudimos traer tus novedades',
                  message: 'Probá de nuevo en un momento.',
                ),
                data: (items) => items.isEmpty
                    ? const _PanelMessage(
                        icon: Icons.notifications_none_rounded,
                        title: 'Todo al día',
                        message:
                            'Acá te vamos a avisar cuando un refugio te '
                            'escriba o tu postulación avance.',
                      )
                    : WoofyRevealGroup(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: WoofySpacing.sm,
                            horizontal: WoofySpacing.sm,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) => WoofyReveal.indexed(
                            index: index,
                            child: NotificationTile(
                              notification: items[index],
                              onTap: () => onOpenNotification(items[index]),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    // El panel es angosto: el estado vacío entra con el texto más chico que el
    // de pantalla completa, si no desborda a 320 px de ancho.
    return SingleChildScrollView(
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        child: WoofyEmptyState(icon: icon, title: title, message: message),
      ),
    );
  }
}
