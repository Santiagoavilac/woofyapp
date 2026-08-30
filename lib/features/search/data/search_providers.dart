import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/search/woofy_search.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';

/// De qué es un resultado. El orden es el de las secciones en pantalla.
///
/// Los animales van primero porque son el corazón de la app; la tienda va
/// después porque "poleras" era justamente lo que antes no se podía encontrar
/// desde Inicio.
enum SearchHitKind {
  animal('Animales', Icons.pets_rounded),
  producto('Productos', Icons.shopping_bag_outlined),
  veterinaria('Veterinarias', Icons.local_hospital_outlined),
  servicio('Servicios', Icons.content_cut_rounded);

  const SearchHitKind(this.plural, this.icon);

  final String plural;
  final IconData icon;
}

/// Un resultado ya aplanado: lo que se dibuja y adónde lleva.
///
/// Las cuatro fuentes tienen modelos distintos, pero la lista de resultados
/// tiene que leerse como una sola cosa. Aplanar acá evita que la pantalla
/// conozca cuatro modelos y cuatro formas de sacar la foto.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.route,
    required this.score,
    this.subtitle,
    this.imageUrl,
  });

  final SearchHitKind kind;
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String route;

  /// Qué tan bien le pega a lo tecleado. Ordena dentro de cada sección.
  final int score;
}

/// Resultados de una búsqueda global, con el aviso de si todavía falta cargar.
class SearchResults {
  const SearchResults({required this.hits, required this.loading});

  final List<SearchHit> hits;

  /// Alguna de las cuatro fuentes sigue en camino. Sin esto, una búsqueda
  /// hecha apenas se abre la pantalla diría "no encontramos nada" cuando en
  /// realidad todavía no había con qué buscar.
  final bool loading;

  List<SearchHit> of(SearchHitKind kind) =>
      hits.where((hit) => hit.kind == kind).toList();

  bool get isEmpty => hits.isEmpty;
}

/// Busca en todo Woofy a la vez: animales, tienda, veterinarias y servicios.
///
/// Es un `Provider` y no un `FutureProvider` porque no pide nada nuevo: cruza
/// listas que las otras pantallas ya traen. Mirarlas también las precarga, así
/// que buscar "polera" funciona aunque nunca se haya entrado a la tienda.
final searchResultsProvider = Provider.autoDispose
    .family<SearchResults, String>((ref, query) {
      final dogs = ref.watch(publishedDogsProvider);
      final partners = ref.watch(activePartnersProvider);
      final services = ref.watch(servicesProvider);
      final store = ref.watch(officialStoreProvider);
      final loading =
          dogs.isLoading ||
          partners.isLoading ||
          services.isLoading ||
          store.isLoading;

      if (query.trim().isEmpty) {
        return SearchResults(hits: const [], loading: loading);
      }

      final hits = <SearchHit>[];

      for (final dog in dogs.value ?? const []) {
        final score = woofySearchScore(query, [
          dog.name,
          dog.species.label,
          dog.story,
          dog.size,
          dog.sex,
          dog.temperament,
          dog.ageGroup?.label,
          dog.shelter?.name,
          dog.shelter?.city,
        ]);
        if (score == 0) continue;
        hits.add(
          SearchHit(
            kind: SearchHitKind.animal,
            id: dog.id,
            title: dog.name,
            // Nunca un precio: adoptar es gratis y esta lista mezcla animales
            // con productos, que sí lo llevan.
            subtitle: [dog.species.label, ?dog.shelter?.city].join(' · '),
            imageUrl: dog.coverPhoto?.publicUrl,
            route: RoutePaths.dogDetail(dog.slug),
            score: score,
          ),
        );
      }

      for (final product in store.value?.products ?? const []) {
        final score = woofySearchScore(query, [
          product.name,
          product.description,
          'polera tienda woofy',
        ]);
        if (score == 0) continue;
        hits.add(
          SearchHit(
            kind: SearchHitKind.producto,
            id: product.id,
            title: product.name,
            subtitle: Money.fromCents(product.priceCents),
            imageUrl: product.imageUrl,
            route: RoutePaths.storeProduct(product.id),
            score: score,
          ),
        );
      }

      for (final partner in partners.value ?? const []) {
        final score = woofySearchScore(query, [
          partner.name,
          partner.description,
          partner.city,
          'veterinaria',
          for (final category in partner.categories) category.label,
        ]);
        if (score == 0) continue;
        hits.add(
          SearchHit(
            kind: SearchHitKind.veterinaria,
            id: partner.id,
            title: partner.name,
            subtitle: partner.city,
            imageUrl: partner.coverImageUrl ?? partner.profileImageUrl,
            route: RoutePaths.partnerDetail(partner.slug),
            score: score,
          ),
        );
      }

      for (final service in services.value ?? const []) {
        final slug = service.partnerSlug;
        if (slug == null) continue;
        final score = woofySearchScore(query, [
          service.name,
          service.description,
          service.partnerName,
          service.partnerCity,
          for (final kind in service.kinds) kind.label,
        ]);
        if (score == 0) continue;
        hits.add(
          SearchHit(
            kind: SearchHitKind.servicio,
            id: service.id,
            title: service.name,
            subtitle: [
              ?service.partnerName,
              Money.fromCents(service.priceCents),
            ].join(' · '),
            imageUrl: service.imageUrl,
            route: RoutePaths.partnerDetail(slug),
            score: score,
          ),
        );
      }

      // Primero lo que mejor le pega a lo tecleado y, a igual puntaje, por
      // nombre: dos búsquedas iguales tienen que devolver el mismo orden.
      hits.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return SearchResults(hits: hits, loading: loading);
    });
