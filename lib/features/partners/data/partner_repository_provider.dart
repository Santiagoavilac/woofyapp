import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => SupabasePartnerRepository(ref.watch(supabaseClientProvider)),
);

/// Los aliados de la pestaña Veterinarias. Es el mismo padrón que el de
/// Servicios, acotado al rubro.
final activePartnersProvider = FutureProvider<List<Partner>>(
  (ref) => ref
      .watch(partnerRepositoryProvider)
      .fetchActivePartners(category: PartnerCategory.vet),
);

final servicesProvider = FutureProvider<List<PartnerService>>(
  (ref) => ref.watch(partnerRepositoryProvider).fetchServices(),
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

/// Rubro por el que se filtra la pantalla de Servicios. `null` es todos.
final selectedServiceKindProvider =
    NotifierProvider<SelectedServiceKind, PartnerCategory?>(
      SelectedServiceKind.new,
    );

class SelectedServiceKind extends Notifier<PartnerCategory?> {
  @override
  PartnerCategory? build() => null;

  void select(PartnerCategory? kind) => state = kind;
}

/// Rubros que hoy tienen al menos un servicio cargado, en el orden en que están
/// declarados en [PartnerCategory].
///
/// Se calcula sobre lo que hay y no sobre el enum entero: una fila de diez
/// chips donde ocho no devuelven nada es peor que no tener filtros.
final availableServiceKindsProvider = Provider<List<PartnerCategory>>((ref) {
  final services = ref.watch(servicesProvider).value ?? const <PartnerService>[];
  final kinds = <PartnerCategory>{};
  for (final service in services) {
    kinds.addAll(service.kinds);
  }
  return PartnerCategory.values.where(kinds.contains).toList();
});
