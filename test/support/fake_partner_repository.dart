import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository.dart';

/// Repositorio de aliados en memoria.
///
/// Vive acá y no dentro de un test porque lo comparten el catálogo de
/// veterinarias y el listado de servicios: son dos pantallas sobre los mismos
/// datos y duplicar el doble sería duplicar también sus errores.
class FakePartnerRepository implements PartnerRepository {
  FakePartnerRepository({
    this.partners = const [],
    this.services = const [],
    this.detail,
    this.error,
    this.partnersFuture,
  });

  final List<Partner> partners;
  final List<PartnerService> services;
  final PartnerDetail? detail;
  final Object? error;
  final Future<List<Partner>>? partnersFuture;

  final List<({String partnerId, List<({String productId, int quantity})> items})>
  createdOrders = [];

  @override
  Future<List<Partner>> fetchActivePartners({PartnerCategory? category}) {
    if (error != null) return Future.error(error!);
    if (partnersFuture != null) return partnersFuture!;
    if (category == null) return Future.value(partners);
    return Future.value(
      partners.where((p) => p.categories.contains(category)).toList(),
    );
  }

  @override
  Future<List<PartnerService>> fetchServices() {
    if (error != null) return Future.error(error!);
    return Future.value(services);
  }

  @override
  Future<PartnerDetail?> fetchPartnerBySlug(String slug) {
    if (error != null) return Future.error(error!);
    return Future.value(detail);
  }

  @override
  Future<PartnerOrder> createOrder({
    required String partnerId,
    required List<({String productId, int quantity})> items,
    String? contactPhone,
    String? notes,
  }) async {
    createdOrders.add((partnerId: partnerId, items: items));
    return PartnerOrder(
      id: 'order-1',
      partnerId: partnerId,
      status: 'pending',
      totalCents: 0,
      items: const [],
    );
  }

  @override
  Future<PartnerReservation> createReservation({
    required String partnerId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  }) async => PartnerReservation(
    id: 'reservation-1',
    partnerId: partnerId,
    status: 'pending',
    serviceNameSnapshot: 'Baño para perro',
    priceCentsSnapshot: 7000,
    scheduledFor: scheduledFor,
    petName: petName,
  );

  @override
  Future<List<PartnerOrder>> fetchMyOrders() async => const [];

  @override
  Future<List<PartnerReservation>> fetchMyReservations() async => const [];
}
