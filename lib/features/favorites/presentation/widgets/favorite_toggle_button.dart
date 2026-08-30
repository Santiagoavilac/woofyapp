import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/favorites/data/favorites_providers.dart';
import 'package:woofy/shared/widgets/woofy_heart_burst.dart';

class FavoriteToggleButton extends ConsumerWidget {
  const FavoriteToggleButton({required this.dogId, super.key});

  final String dogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(dogId));

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        key: ValueKey('favorite-toggle-$dogId'),
        tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
        // Sin spinner ni botón apagado: el corazón ya muestra la decisión, así
        // que no hay espera que comunicar.
        onPressed: () async {
          if (ref.read(currentUserProvider) == null) {
            context.go(RoutePaths.auth);
            return;
          }
          try {
            await ref.read(favoriteMutationProvider.notifier).toggle(dogId);
          } catch (error) {
            if (!context.mounted) return;
            final message = error is AppException
                ? error.message
                : 'No pudimos actualizar el favorito.';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        icon: WoofyHeartBurst(
          isActive: isFavorite,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : null,
          ),
        ),
      ),
    );
  }
}
