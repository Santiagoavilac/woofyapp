import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/features/auth/presentation/auth_page.dart';
import 'package:mi_app/features/auth/presentation/profile_page.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/applications/presentation/application_form_page.dart';
import 'package:mi_app/features/dogs/presentation/dog_detail_page.dart';
import 'package:mi_app/features/dogs/presentation/dogs_page.dart';
import 'package:mi_app/features/landing/presentation/landing_page.dart';
import 'package:mi_app/features/favorites/presentation/favorites_page.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.landing,
    routes: [
      GoRoute(
        name: RouteNames.landing,
        path: RoutePaths.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        name: RouteNames.dogs,
        path: RoutePaths.dogs,
        builder: (context, state) => const DogsPage(),
      ),
      GoRoute(
        name: RouteNames.dogDetail,
        path: RoutePaths.dogDetailPattern,
        builder: (context, state) =>
            DogDetailPage(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        name: RouteNames.applicationForm,
        path: RoutePaths.applicationFormPattern,
        builder: (context, state) =>
            ApplicationFormPage(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        name: RouteNames.auth,
        path: RoutePaths.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        name: RouteNames.profile,
        path: RoutePaths.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        name: RouteNames.favorites,
        path: RoutePaths.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
    ],
    redirect: (context, state) {
      final hasSession = ref.read(authRepositoryProvider).currentUser != null;
      final location = state.matchedLocation;
      final protected =
          location == RoutePaths.profile ||
          location == RoutePaths.favorites ||
          location.endsWith('/postular');
      if (!hasSession && protected) {
        return RoutePaths.auth;
      }
      if (hasSession && location == RoutePaths.auth) {
        return RoutePaths.profile;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: WoofyError(
          title: 'Página no encontrada',
          message: 'La ruta solicitada no está disponible.',
          actionLabel: 'Volver al inicio',
          onRetry: () => context.go(RoutePaths.landing),
        ),
      ),
    ),
  );

  ref.listen(authStateProvider, (_, next) => router.refresh());

  ref.onDispose(router.dispose);
  return router;
});
