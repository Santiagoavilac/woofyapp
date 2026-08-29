import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/partners/data/partner_models.dart';

abstract interface class PartnerRepository {
  /// Aliados activos. Con [category] devuelve solo los que declaran ese rubro,
  /// que es como la pestaña Veterinarias se queda con los suyos.
  Future<List<Partner>> fetchActivePartners({PartnerCategory? category});

  /// Servicios de todos los aliados, cada uno con el negocio que lo ofrece.
  /// La pantalla de Servicios lista servicios y no negocios: quien busca un
  /// paseo quiere ver paseos, no fichas de empresas que quizás pasean.
  Future<List<PartnerService>> fetchServices();

  Future<PartnerDetail?> fetchPartnerBySlug(String slug);

  /// Crea el pedido del lado del servidor. El cliente manda solo ids y
  /// cantidades: los precios los recalcula el RPC contra `partner_products`.
  Future<PartnerOrder> createOrder({
    required String partnerId,
    required List<({String productId, int quantity})> items,
    String? contactPhone,
    String? notes,
  });

  Future<PartnerReservation> createReservation({
    required String partnerId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  });

  Future<List<PartnerOrder>> fetchMyOrders();

  Future<List<PartnerReservation>> fetchMyReservations();
}

class SupabasePartnerRepository implements PartnerRepository {
  SupabasePartnerRepository(this._client);

  // El bucket sigue llamándose `vet-images` aunque las tablas ya no. Renombrarlo
  // habría dejado huérfanas las imágenes ya subidas, y la ruta de storage no la
  // ve nadie: es interna, a diferencia de las URLs del panel.
  static const _bucket = 'vet-images';

  static const _partnerFields = '''
    id, name, slug, description, city, address, location_notes,
    whatsapp_phone, phone, email, instagram, facebook, website,
    profile_image_path, cover_image_path, verified, status, categories
  ''';

  final SupabaseClient _client;

  @override
  Future<List<Partner>> fetchActivePartners({PartnerCategory? category}) async {
    try {
      var query = _client
          .from('partners')
          .select(_partnerFields)
          .eq('status', 'active');
      if (category != null) {
        // `overlaps` sobre el array: se apoya en el índice GIN de
        // `partners.categories`.
        query = query.overlaps('categories', [category.id]);
      }
      final response = await query.order('name').limit(200);

      return response.map((json) => _withUrls(Partner.fromJson(json))).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<PartnerService>> fetchServices() async {
    try {
      // El RLS ya deja fuera lo despublicado y a los aliados que no están
      // activos; el `inner` está para que el join no devuelva servicios con el
      // negocio en null.
      final response = await _client
          .from('partner_services')
          .select('''
            id, partner_id, name, description, price_cents, image_path,
            duration_minutes, kinds, position,
            partners!inner(name, slug, city)
          ''')
          .order('position')
          .order('name')
          .limit(200);

      return response
          .map((json) => _withServiceUrl(PartnerService.fromJson(json)))
          .toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<PartnerDetail?> fetchPartnerBySlug(String slug) async {
    try {
      final response = await _client
          .from('partners')
          .select(_partnerFields)
          .eq('slug', slug)
          .eq('status', 'active')
          .maybeSingle();
      if (response == null) return null;

      final partner = _withUrls(Partner.fromJson(response));
      // El RLS ya filtra por publicado y no borrado, pero se repite acá para
      // que el orden y el límite no dependan solo de la política.
      final catalog = await Future.wait<List<Map<String, dynamic>>>([
        _client
            .from('partner_products')
            .select(
              'id, partner_id, name, description, price_cents, image_path, stock, position',
            )
            .eq('partner_id', partner.id)
            .order('position')
            .order('name'),
        _client
            .from('partner_services')
            .select(
              'id, partner_id, name, description, price_cents, image_path, '
              'duration_minutes, kinds, position',
            )
            .eq('partner_id', partner.id)
            .order('position')
            .order('name'),
      ]);

      return PartnerDetail(
        partner: partner,
        products: catalog[0]
            .map((json) => _withProductUrl(PartnerProduct.fromJson(json)))
            .toList(),
        services: catalog[1]
            .map((json) => _withServiceUrl(PartnerService.fromJson(json)))
            .toList(),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<PartnerOrder> createOrder({
    required String partnerId,
    required List<({String productId, int quantity})> items,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'create_partner_order',
        params: {
          'p_partner_id': partnerId,
          'p_items': [
            for (final item in items)
              {'product_id': item.productId, 'quantity': item.quantity},
          ],
          'p_contact_phone': contactPhone,
          'p_notes': notes,
        },
      );
      return PartnerOrder.fromJson(response);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<PartnerReservation> createReservation({
    required String partnerId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'create_partner_reservation',
        params: {
          'p_partner_id': partnerId,
          'p_service_id': serviceId,
          // UTC: el servidor guarda timestamptz y el turno no puede correrse
          // de hora según el huso del teléfono.
          'p_scheduled_for': scheduledFor.toUtc().toIso8601String(),
          'p_pet_name': petName,
          'p_contact_phone': contactPhone,
          'p_notes': notes,
        },
      );
      return PartnerReservation.fromJson(response);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<PartnerOrder>> fetchMyOrders() async {
    try {
      final response = await _client
          .from('partner_orders')
          .select('''
            id, partner_id, status, total_cents, contact_phone, notes, created_at,
            partners(name),
            items:partner_order_items(
              id, name_snapshot, unit_price_cents, quantity, line_total_cents
            )
          ''')
          .order('created_at', ascending: false)
          .limit(50);
      return response.map(PartnerOrder.fromJson).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<PartnerReservation>> fetchMyReservations() async {
    try {
      final response = await _client
          .from('partner_reservations')
          .select('''
            id, partner_id, status, service_name_snapshot, price_cents_snapshot,
            scheduled_for, pet_name, notes, contact_phone, partners(name)
          ''')
          .order('scheduled_for', ascending: false)
          .limit(50);
      return response.map(PartnerReservation.fromJson).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  String? _publicUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Partner _withUrls(Partner partner) => partner.copyWith(
    profileImageUrl: _publicUrl(partner.profileImagePath),
    coverImageUrl: _publicUrl(partner.coverImagePath),
  );

  PartnerProduct _withProductUrl(PartnerProduct product) =>
      product.copyWith(imageUrl: _publicUrl(product.imagePath));

  PartnerService _withServiceUrl(PartnerService service) =>
      service.copyWith(imageUrl: _publicUrl(service.imagePath));
}
