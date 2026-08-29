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

  /// Proporción de las imágenes: apaisadas, como las pide el panel.
  static const aspectRatio = 1200 / 480;

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
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            aspectRatio: BannerCarousel.aspectRatio,
            child: PageView.builder(
              key: ValueKey('banner-carousel-${widget.slot.id}'),
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (page) => setState(() => _page = page),
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
          ),
        ),
      ),
    );
  }
}
