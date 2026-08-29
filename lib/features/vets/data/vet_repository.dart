import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/vets/data/vet_models.dart';

abstract interface class VetRepository {
  Future<List<Vet>> fetchActiveVets();

  Future<VetDetail?> fetchVetBySlug(String slug);

  /// Crea el pedido del lado del servidor. El cliente manda solo ids y
  /// cantidades: los precios los recalcula el RPC contra `vet_products`.
  Future<VetOrder> createOrder({
    required String vetId,
    required List<({String productId, int quantity})> items,
    String? contactPhone,
    String? notes,
  });

  Future<VetReservation> createReservation({
    required String vetId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  });

  Future<List<VetOrder>> fetchMyOrders();

  Future<List<VetReservation>> fetchMyReservations();
}

class SupabaseVetRepository implements VetRepository {
  SupabaseVetRepository(this._client);

  static const _bucket = 'vet-images';

  static const _vetFields = '''
    id, name, slug, description, city, address, location_notes, lat, lng,
    whatsapp_phone, phone, email, instagram, facebook, website,
    profile_image_path, cover_image_path, verified, status
  ''';

  final SupabaseClient _client;

  @override
  Future<List<Vet>> fetchActiveVets() async {
    try {
      final response = await _client
          .from('vets')
          .select(_vetFields)
          .eq('status', 'active')
          .order('name')
          .limit(200);

      return response.map((json) => _withUrls(Vet.fromJson(json))).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<VetDetail?> fetchVetBySlug(String slug) async {
    try {
      final response = await _client
          .from('vets')
          .select(_vetFields)
          .eq('slug', slug)
          .eq('status', 'active')
          .maybeSingle();
      if (response == null) return null;

      final vet = _withUrls(Vet.fromJson(response));
      // El RLS ya filtra por publicado y no borrado, pero se repite acá para
      // que el orden y el límite no dependan solo de la política.
      final catalog = await Future.wait<List<Map<String, dynamic>>>([
        _client
            .from('vet_products')
            .select(
              'id, vet_id, name, description, price_cents, image_path, stock, position',
            )
            .eq('vet_id', vet.id)
            .order('position')
            .order('name'),
        _client
            .from('vet_services')
            .select(
              'id, vet_id, name, description, price_cents, image_path, position',
            )
            .eq('vet_id', vet.id)
            .order('position')
            .order('name'),
      ]);

      return VetDetail(
        vet: vet,
        products: catalog[0]
            .map((json) => _withProductUrl(VetProduct.fromJson(json)))
            .toList(),
        services: catalog[1]
            .map((json) => _withServiceUrl(VetService.fromJson(json)))
            .toList(),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<VetOrder> createOrder({
    required String vetId,
    required List<({String productId, int quantity})> items,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'create_vet_order',
        params: {
          'p_vet_id': vetId,
          'p_items': [
            for (final item in items)
              {'product_id': item.productId, 'quantity': item.quantity},
          ],
          'p_contact_phone': contactPhone,
          'p_notes': notes,
        },
      );
      return VetOrder.fromJson(response);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<VetReservation> createReservation({
    required String vetId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'create_vet_reservation',
        params: {
          'p_vet_id': vetId,
          'p_service_id': serviceId,
          // UTC: el servidor guarda timestamptz y el turno no puede correrse
          // de hora según el huso del teléfono.
          'p_scheduled_for': scheduledFor.toUtc().toIso8601String(),
          'p_pet_name': petName,
          'p_contact_phone': contactPhone,
          'p_notes': notes,
        },
      );
      return VetReservation.fromJson(response);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<VetOrder>> fetchMyOrders() async {
    try {
      final response = await _client
          .from('vet_orders')
          .select('''
            id, vet_id, status, total_cents, contact_phone, notes, created_at,
            vets(name),
            items:vet_order_items(
              id, name_snapshot, unit_price_cents, quantity, line_total_cents
            )
          ''')
          .order('created_at', ascending: false)
          .limit(50);
      return response.map(VetOrder.fromJson).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<VetReservation>> fetchMyReservations() async {
    try {
      final response = await _client
          .from('vet_reservations')
          .select('''
            id, vet_id, status, service_name_snapshot, price_cents_snapshot,
            scheduled_for, pet_name, notes, contact_phone, vets(name)
          ''')
          .order('scheduled_for', ascending: false)
          .limit(50);
      return response.map(VetReservation.fromJson).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  String? _publicUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Vet _withUrls(Vet vet) => vet.copyWith(
    profileImageUrl: _publicUrl(vet.profileImagePath),
    coverImageUrl: _publicUrl(vet.coverImagePath),
  );

  VetProduct _withProductUrl(VetProduct product) =>
      product.copyWith(imageUrl: _publicUrl(product.imagePath));

  VetService _withServiceUrl(VetService service) =>
      service.copyWith(imageUrl: _publicUrl(service.imagePath));
}
