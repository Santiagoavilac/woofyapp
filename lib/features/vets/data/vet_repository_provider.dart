import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/vets/data/vet_models.dart';
import 'package:woofy/features/vets/data/vet_repository.dart';

final vetRepositoryProvider = Provider<VetRepository>(
  (ref) => SupabaseVetRepository(ref.watch(supabaseClientProvider)),
);

final activeVetsProvider = FutureProvider<List<Vet>>(
  (ref) => ref.watch(vetRepositoryProvider).fetchActiveVets(),
);

final vetDetailProvider = FutureProvider.family<VetDetail?, String>(
  (ref, slug) => ref.watch(vetRepositoryProvider).fetchVetBySlug(slug),
);

final myVetOrdersProvider = FutureProvider<List<VetOrder>>(
  (ref) => ref.watch(vetRepositoryProvider).fetchMyOrders(),
);

final myVetReservationsProvider = FutureProvider<List<VetReservation>>(
  (ref) => ref.watch(vetRepositoryProvider).fetchMyReservations(),
);

/// Ciudad a la que se acota el listado de veterinarias. `null` es todas.
///
/// Separado de `selectedCityProvider` (adopción) a propósito: filtrar
/// veterinarias no debería mover el catálogo de perros ni al revés.
final selectedVetCityProvider = NotifierProvider<SelectedVetCity, String?>(
  SelectedVetCity.new,
);

class SelectedVetCity extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? city) => state = city;
}

/// Ciudades con al menos una veterinaria activa, alfabéticas.
final availableVetCitiesProvider = Provider<List<String>>((ref) {
  final vets = ref.watch(activeVetsProvider).value ?? const <Vet>[];
  final cities = <String>{};
  for (final vet in vets) {
    final city = vet.city;
    if (city != null && city.isNotEmpty) cities.add(city);
  }
  return cities.toList()..sort();
});
