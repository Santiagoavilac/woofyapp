import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => SupabasePartnerRepository(ref.watch(supabaseClientProvider)),
);

final activePartnersProvider = FutureProvider<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).fetchActivePartners(category: PartnerCategory.vet),
);

final partnerDetailProvider = FutureProvider.family<PartnerDetail?, String>(
  (ref, slug) => ref.watch(partnerRepositoryProvider).fetchPartnerBySlug(slug),
);

final myPartnerOrdersProvider = FutureProvider<List<PartnerOrder>>(
  (ref) => ref.watch(partnerRepositoryProvider).fetchMyOrders(),
);

final myPartnerReservationsProvider = FutureProvider<List<PartnerReservation>>(
  (ref) => ref.watch(partnerRepositoryProvider).fetchMyReservations(),
);

/// Ciudad a la que se acota el listado de veterinarias. `null` es todas.
///
/// Separado de `selectedCityProvider` (adopción) a propósito: filtrar
/// veterinarias no debería mover el catálogo de perros ni al revés.
final selectedPartnerCityProvider = NotifierProvider<SelectedPartnerCity, String?>(
  SelectedPartnerCity.new,
);

class SelectedPartnerCity extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? city) => state = city;
}

/// Ciudades con al menos una veterinaria activa, alfabéticas.
final availablePartnerCitiesProvider = Provider<List<String>>((ref) {
  final partners = ref.watch(activePartnersProvider).value ?? const <Partner>[];
  final cities = <String>{};
  for (final partner in partners) {
    final city = partner.city;
    if (city != null && city.isNotEmpty) cities.add(city);
  }
  return cities.toList()..sort();
});
