import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/auth/presentation/auth_page.dart';
import 'package:woofy/features/auth/presentation/profile_page.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/applications/presentation/application_form_page.dart';
import 'package:woofy/features/dogs/presentation/dog_detail_page.dart';
import 'package:woofy/features/dogs/presentation/dogs_page.dart';
import 'package:woofy/features/landing/presentation/landing_page.dart';
import 'package:woofy/features/favorites/presentation/favorites_page.dart';
import 'package:woofy/features/messages/presentation/conversation_page.dart';
import 'package:woofy/features/messages/presentation/messages_page.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/features/auth/presentation/adopter_edit_profile_page.dart';
import 'package:woofy/features/legal/presentation/delete_account_page.dart';
import 'package:woofy/features/publisher/presentation/publisher_dog_form_page.dart';
import 'package:woofy/features/publisher/presentation/publisher_page.dart';
import 'package:woofy/features/publisher/presentation/shelter_edit_profile_page.dart';
import 'package:woofy/features/publisher/presentation/shelter_login_page.dart';
import 'package:woofy/shared/widgets/woofy_bottom_navigation.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.landing,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.landing,
                path: RoutePaths.landing,
                builder: (context, state) => const LandingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.dogs,
                path: RoutePaths.dogs,
                builder: (context, state) => const DogsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.profile,
                path: RoutePaths.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
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
        name: RouteNames.favorites,
        path: RoutePaths.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        name: RouteNames.messages,
        path: RoutePaths.messages,
        builder: (context, state) => const MessagesPage(),
      ),
      GoRoute(
        name: RouteNames.conversation,
        path: RoutePaths.conversationPattern,
        builder: (context, state) =>
            ConversationPage(threadId: state.pathParameters['threadId'] ?? ''),
      ),
      GoRoute(
        name: RouteNames.publisher,
        path: RoutePaths.publisher,
        builder: (context, state) => const PublisherPage(),
      ),
      GoRoute(
        name: RouteNames.publisherNewDog,
        path: RoutePaths.publisherNewDog,
        builder: (context, state) => const PublisherDogFormPage(),
      ),
      GoRoute(
        name: RouteNames.publisherEditDog,
        path: RoutePaths.publisherEditDogPattern,
        builder: (context, state) =>
            PublisherDogFormPage(dogId: state.pathParameters['dogId']),
      ),
      GoRoute(
        name: RouteNames.shelterLogin,
        path: RoutePaths.shelterLogin,
        builder: (context, state) => const ShelterLoginPage(),
      ),
      GoRoute(
        name: RouteNames.shelterEditProfile,
        path: RoutePaths.shelterEditProfile,
        builder: (context, state) => const ShelterEditProfilePage(),
      ),
      GoRoute(
        name: RouteNames.adopterEditProfile,
        path: RoutePaths.adopterEditProfile,
        builder: (context, state) => const AdopterEditProfilePage(),
      ),
      GoRoute(
        name: RouteNames.deleteAccount,
        path: RoutePaths.deleteAccount,
        builder: (context, state) => const DeleteAccountPage(),
      ),
    ],
    redirect: (context, state) {
      final hasSession = ref.read(authRepositoryProvider).currentUser != null;
      final hasShelter = ref.read(shelterPortalSessionProvider).value != null;
      final location = state.matchedLocation;
      final protected =
          location == RoutePaths.favorites ||
          location == RoutePaths.messages ||
          location.startsWith('/mensajes/') ||
          location.endsWith('/postular');
      if (!hasSession && protected) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.profile && !hasSession && !hasShelter) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.adopterEditProfile && !hasSession) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.deleteAccount && !hasSession) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.shelterEditProfile && !hasShelter) {
        return RoutePaths.shelterLogin;
      }
      if (hasSession && location == RoutePaths.auth) {
        return RoutePaths.profile;
      }
      if (location == RoutePaths.shelterLogin && hasShelter) {
        return RoutePaths.publisher;
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
  ref.listen(shelterPortalSessionProvider, (_, _) => router.refresh());

  ref.onDispose(router.dispose);
  return router;
});

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Back-to-Home for the tabs is handled inside each non-Home branch page
    // (DogsPage / ProfilePage) via PopScope: the branch navigator wins the
    // popRoute() traversal first, so its onPopInvoked runs and routes to Home.
    //
    // This shell-level PopScope is a *guard*, not the handler: after a
    // top-level route is pushed and popped (e.g. Explorar -> dog detail ->
    // back), the root navigator re-dispatches its NavigationNotification based
    // on the shell route's popDisposition. Without this guard it would report
    // canHandlePop=false and Android would exit the app on the next back.
    // Marking the shell route as doNotPop while off Home keeps the framework
    // in control so the branch PopScope can send us back to Home.
    // On Home (index 0) canPop is true, so back exits the app as expected.
    return PopScope<Object?>(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: WoofyBottomNavigation(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
