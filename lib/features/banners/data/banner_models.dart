/// Banners de publicidad que el admin carga desde la web. Antes el banner de
/// Inicio era un PNG dentro del bundle: cambiarlo pedía una release nueva.
library;

/// Pantalla en la que se muestra un banner. Coincide con el enum
/// `public.promo_banner_slot` de Postgres.
enum BannerSlot {
  home('home'),

  /// Segunda tanda de Inicio, más abajo: entre Servicios y Veterinarias.
  /// Va separada de `home` y no como un banner más del mismo slot para que el
  /// admin pueda decidir qué se ve arriba y qué se ve abajo.
  homeSecondary('home_secondary'),
  explore('explore'),
  vets('vets'),
  services('services');

  const BannerSlot(this.id);

  final String id;
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.linkUrl,
    this.aspectRatio,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json, String imageUrl) {
    return PromoBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: _stringOrNull(json['subtitle']),
      imageUrl: imageUrl,
      linkUrl: _stringOrNull(json['link_url']),
      aspectRatio: _positiveOrNull(json['aspect_ratio']),
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;

  /// Ancho dividido alto de la imagen que subió el admin.
  ///
  /// Nulo en los banners cargados antes de que el panel lo midiera. Con esto la
  /// app arma la caja a medida en vez de recortar todo contra una única
  /// proporción, que era lo que le comía los bordes a cualquier imagen que no
  /// viniera exactamente apaisada 2.5:1.
  final double? aspectRatio;

  /// Ruta interna de la app (`/veterinarias`) o URL externa (`https://…`).
  /// Nulo si el banner no lleva a ningún lado.
  final String? linkUrl;

  bool get isExternalLink =>
      linkUrl != null && Uri.tryParse(linkUrl!)?.hasScheme == true;

  static String? _stringOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  /// Una proporción de cero o negativa no existe; tratarla como "no vino" deja
  /// que la caja caiga en su valor por defecto en vez de romper el layout.
  static double? _positiveOrNull(Object? value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return number == null || number <= 0 ? null : number;
  }
}
