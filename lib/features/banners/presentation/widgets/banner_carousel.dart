import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/data/banner_repository_provider.dart';

/// Carrusel de banners de publicidad de una pantalla.
///
/// Se dibuja solo si el admin cargó banners para ese slot: mientras carga, si
/// falla o si no hay ninguno, no ocupa espacio. Un hueco reservado "por si
/// acaso" deja un agujero en pantallas que muchas veces no van a tener aviso.
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({
    required this.slot,
    this.fallback,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// La forma que tenían todos los banners cuando el panel pedía una medida
  /// exacta. Sirve de red para los que se cargaron antes de que se midiera la
  /// imagen y no traen proporción propia.
  static const defaultAspectRatio = 1200 / 480;

  /// Hasta dónde se estira la caja. Son los mismos extremos que valida el panel
  /// y que impone el check de la base: un banner más alto que 1.5:1 se come la
  /// pantalla y empuja el contenido real fuera de vista; uno más ancho que 4:1
  /// deja una tira donde el título no entra.
  ///
  /// Acá se vuelve a acotar igual, porque una fila vieja o cargada por fuera
  /// del panel podría traer cualquier cosa y el layout no puede depender de eso.
  static const minAspectRatio = 1.5;
  static const maxAspectRatio = 4.0;

  /// La proporción de la caja para un conjunto de banners.
  ///
  /// Es una sola para todas las páginas: si cada banner impusiera la suya, el
  /// carrusel cambiaría de alto en pleno arrastre y todo lo que está abajo
  /// saltaría de lugar.
  ///
  /// Se promedia en vez de tomar el más alto o el más ancho porque es lo que
  /// reparte el recorte. Con el más alto, un banner bien apaisado perdería
  /// medio ancho a los costados. Y en el caso normal —todos los banners de una
  /// pantalla los hace la misma persona, con la misma forma— el promedio *es*
  /// esa forma, así que no se recorta nada.
  static double aspectRatioOf(Iterable<PromoBanner> banners) {
    final ratios = [
      for (final banner in banners)
        (banner.aspectRatio ?? defaultAspectRatio).clamp(
          minAspectRatio,
          maxAspectRatio,
        ),
    ];
    if (ratios.isEmpty) return defaultAspectRatio;
    return ratios.reduce((a, b) => a + b) / ratios.length;
  }

  final BannerSlot slot;

  /// Qué mostrar cuando todavía no hay ningún banner cargado. Inicio lo usa
  /// para no quedarse sin su mensaje de adopción.
  final Widget? fallback;

  /// Se aplica solo si hay algo que mostrar. Si el espacio lo pusiera la
  /// pantalla, quedaría un hueco vacío cuando no hay publicidad cargada.
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  /// Cuánto se queda quieto cada banner.
  ///
  /// Cinco segundos alcanzan para leer un título y un subtítulo sin que el
  /// siguiente se sienta apurado. Menos que eso y el banner se va justo cuando
  /// la persona terminó de entender qué decía.
  static const _interval = Duration(seconds: 5);

  final _controller = PageController();
  int _page = 0;
  int _count = 0;
  bool _autoPlay = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Enciende o apaga el paso solo, según lo que haya para mostrar.
  ///
  /// Con movimiento reducido no se mueve nunca: un carrusel que avanza solo es
  /// exactamente la clase de movimiento que nadie pidió, y ahí las páginas
  /// quedan a mano — se pasan arrastrando, como siempre.
  void _syncAutoPlay({required int count, required bool reduceMotion}) {
    _count = count;
    final shouldPlay = count > 1 && !reduceMotion;
    if (shouldPlay == _autoPlay) return;
    _autoPlay = shouldPlay;
    if (shouldPlay) {
      _schedule();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Un temporizador de una sola vez, reprogramado en cada cambio de página.
  ///
  /// Con `Timer.periodic` el reloj sigue corriendo mientras la persona arrastra:
  /// pasabas una página a mano y medio segundo después el carrusel te la
  /// cambiaba de nuevo. Así el conteo arranca de cero cada vez.
  void _schedule() {
    _timer?.cancel();
    if (!_autoPlay) return;
    _timer = Timer(_interval, _advance);
  }

  void _advance() {
    if (!mounted || _count < 2 || !_controller.hasClients) return;
    _controller.animateToPage(
      (_page + 1) % _count,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _open(PromoBanner banner) async {
    final link = banner.linkUrl;
    if (link == null) return;
    if (banner.isExternalLink) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    context.push(link);
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider(widget.slot)).value ?? const [];
    _syncAutoPlay(
      count: banners.length,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    if (banners.isEmpty) {
      final fallback = widget.fallback;
      if (fallback == null) return const SizedBox.shrink();
      return Padding(padding: widget.padding, child: fallback);
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: BannerCarousel.aspectRatioOf(banners),
            child: PageView.builder(
              key: ValueKey('banner-carousel-${widget.slot.id}'),
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (page) {
                setState(() => _page = page);
                _schedule();
              },
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  // Sin separación entre páginas la siguiente aparece pegada al
                  // borde de la anterior mientras se arrastra.
                  padding: EdgeInsets.only(
                    right: index == banners.length - 1 ? 0 : WoofySpacing.sm,
                  ),
                  child: _BannerTile(
                    banner: banner,
                    onTap: banner.linkUrl == null ? null : () => _open(banner),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: WoofySpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < banners.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: index == _page ? 18 : 6,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? WoofyColors.primary
                          : WoofyColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.banner, required this.onTap});

  final PromoBanner banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: WoofyRadius.cardLargeAll,
      child: Material(
        color: WoofyColors.surfaceMuted,
        child: InkWell(
          key: ValueKey('promo-banner-${banner.id}'),
          onTap: onTap,
          child: Semantics(
            image: true,
            // Con el velo puesto el título ya está en pantalla y anunciarlo dos
            // veces sobra. Sin velo no hay ningún texto que leer: el titular
            // vive dentro del PNG, así que el label es lo único que queda.
            label: banner.showCaption ? null : banner.title,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const ColoredBox(color: WoofyColors.surfaceMuted),
                  errorWidget: (context, url, error) =>
                      const ColoredBox(color: WoofyColors.surfaceMuted),
                ),
                if (banner.showCaption) ...[
                  // Velo en el borde inferior: el título tiene que leerse sobre
                  // cualquier imagen que suba el admin, incluida una clara.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Color(0xB3000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(WoofySpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: WoofyColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (banner.subtitle case final subtitle?) ...[
                            const SizedBox(height: WoofySpacing.xs),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: WoofyColors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
