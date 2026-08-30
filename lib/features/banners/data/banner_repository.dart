import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/banners/data/banner_models.dart';

abstract interface class BannerRepository {
  /// Banners vigentes de una pantalla, en el orden que fijó el admin.
  Future<List<PromoBanner>> fetchBanners(BannerSlot slot);
}

class SupabaseBannerRepository implements BannerRepository {
  SupabaseBannerRepository(this._client);

  static const _bucket = 'promo-banners';

  final SupabaseClient _client;

  @override
  Future<List<PromoBanner>> fetchBanners(BannerSlot slot) async {
    try {
      // El RLS ya filtra despublicados y fuera de ventana: acá no se repite la
      // condición para que no queden dos definiciones de "vigente" que puedan
      // desincronizarse.
      final response = await _client
          .from('promo_banners')
          .select('id, title, subtitle, image_path, link_url, aspect_ratio')
          .eq('slot', slot.id)
          .order('position')
          .limit(20);

      return response
          .map(
            (json) => PromoBanner.fromJson(
              json,
              _client.storage
                  .from(_bucket)
                  .getPublicUrl(json['image_path'].toString()),
            ),
          )
          .toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }
}
