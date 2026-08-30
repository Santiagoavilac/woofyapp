import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/page_transitions.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/presentation/auth_page.dart';
import 'package:woofy/features/blocks/presentation/blocked_accounts_page.dart';
import 'package:woofy/features/auth/presentation/forgot_password_page.dart';
import 'package:woofy/features/auth/presentation/new_password_page.dart';
import 'package:woofy/features/auth/presentation/profile_page.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/applications/presentation/application_form_page.dart';
import 'package:woofy/features/dogs/presentation/dog_detail_page.dart';
import 'package:woofy/features/dogs/presentation/dogs_page.dart';
import 'package:woofy/features/landing/presentation/landing_page.dart';
import 'package:woofy/features/favorites/presentation/favorites_page.dart';
import 'package:woofy/features/messages/presentation/conversation_page.dart';
import 'package:woofy/features/messages/presentation/messages_page.dart';
import 'package:woofy/features/merch/presentation/merch_product_page.dart';
import 'package:woofy/features/merch/presentation/merch_store_page.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/features/auth/presentation/adopter_edit_profile_page.dart';
import 'package:woofy/features/legal/presentation/delete_account_page.dart';
import 'package:woofy/features/publisher/presentation/publisher_dog_form_page.dart';
import 'package:woofy/features/publisher/presentation/publisher_page.dart';
import 'package:woofy/features/publisher/presentation/shelter_edit_profile_page.dart';
import 'package:woofy/features/publisher/presentation/shelter_login_page.dart';
import 'package:woofy/features/partners/presentation/cart_page.dart';
import 'package:woofy/features/partners/presentation/my_orders_page.dart';
import 'package:woofy/features/partners/presentation/partner_detail_page.dart';
import 'package:woofy/features/partners/presentation/partner_product_page.dart';
import 'package:woofy/features/partners/presentation/partner_reservation_page.dart';
import 'package:woofy/features/partners/presentation/services_page.dart';
import 'package:woofy/features/partners/presentation/vets_page.dart';
import 'package:woofy/features/search/presentation/search_page.dart';
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
                pageBuilder: (context, state) => woofyPage(
                  state,
                  const LandingPage(),
                  kind: WoofyTransition.branch,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.dogs,
                path: RoutePaths.dogs,
                pageBuilder: (context, state) => woofyPage(
                  state,
                  const DogsPage(),
                  kind: WoofyTransition.branch,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.vets,
                path: RoutePaths.vets,
                pageBuilder: (context, state) => woofyPage(
                  state,
                  const VetsPage(),
                  kind: WoofyTransition.branch,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.profile,
                path: RoutePaths.profile,
                pageBuilder: (context, state) => woofyPage(
                  state,
                  const ProfilePage(),
                  kind: WoofyTransition.branch,
                ),
              ),
            ],
          ),
        ],
      ),
      // Fuera del shell: se entra desde Inicio y no tiene pestaña propia, así
      // que tampoco lleva la barra de abajo.
      GoRoute(
        name: RouteNames.services,
        path: RoutePaths.services,
        pageBuilder: (context, state) => woofyPage(
          state,
          const ServicesPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.cart,
        path: RoutePaths.cart,
        pageBuilder: (context, state) =>
            woofyPage(state, const CartPage(), kind: WoofyTransition.detail),
      ),
      GoRoute(
        name: RouteNames.store,
        path: RoutePaths.store,
        pageBuilder: (context, state) => woofyPage(
          state,
          const MerchStorePage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.orders,
        path: RoutePaths.orders,
        pageBuilder: (context, state) => woofyPage(
          state,
          const MyOrdersPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      // El buscador general. Es una ruta empujada y no una pestaña: se entra
      // desde Inicio, se busca y se vuelve.
      GoRoute(
        name: RouteNames.search,
        path: RoutePaths.search,
        pageBuilder: (context, state) => woofyPage(
          state,
          SearchPage(initialQuery: state.uri.queryParameters['q'] ?? ''),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.storeProduct,
        path: RoutePaths.storeProductPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          MerchProductPage(productId: state.pathParameters['productId'] ?? ''),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.partnerReservation,
        path: RoutePaths.partnerReservationPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          PartnerReservationPage(
            slug: state.pathParameters['slug'] ?? '',
            serviceId: state.extra as String?,
          ),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.partnerProduct,
        path: RoutePaths.partnerProductPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          PartnerProductPage(
            slug: state.pathParameters['slug'] ?? '',
            productId: state.pathParameters['productId'] ?? '',
          ),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.partnerDetail,
        path: RoutePaths.partnerDetailPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          PartnerDetailPage(slug: state.pathParameters['slug'] ?? ''),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.dogDetail,
        path: RoutePaths.dogDetailPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          DogDetailPage(slug: state.pathParameters['slug'] ?? ''),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.applicationForm,
        path: RoutePaths.applicationFormPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          ApplicationFormPage(slug: state.pathParameters['slug'] ?? ''),
          kind: WoofyTransition.commit,
        ),
      ),
      GoRoute(
        name: RouteNames.auth,
        path: RoutePaths.auth,
        pageBuilder: (context, state) =>
            woofyPage(state, const AuthPage(), kind: WoofyTransition.fade),
      ),
      GoRoute(
        name: RouteNames.forgotPassword,
        path: RoutePaths.forgotPassword,
        pageBuilder: (context, state) => woofyPage(
          state,
          const ForgotPasswordPage(),
          kind: WoofyTransition.fade,
        ),
      ),
      GoRoute(
        name: RouteNames.newPassword,
        path: RoutePaths.newPassword,
        pageBuilder: (context, state) => woofyPage(
          state,
          const NewPasswordPage(),
          kind: WoofyTransition.fade,
        ),
      ),
      GoRoute(
        name: RouteNames.favorites,
        path: RoutePaths.favorites,
        pageBuilder: (context, state) => woofyPage(
          state,
          const FavoritesPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.messages,
        path: RoutePaths.messages,
        pageBuilder: (context, state) => woofyPage(
          state,
          const MessagesPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.conversation,
        path: RoutePaths.conversationPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          ConversationPage(threadId: state.pathParameters['threadId'] ?? ''),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.publisher,
        path: RoutePaths.publisher,
        pageBuilder: (context, state) => woofyPage(
          state,
          const PublisherPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.publisherNewDog,
        path: RoutePaths.publisherNewDog,
        pageBuilder: (context, state) => woofyPage(
          state,
          const PublisherDogFormPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.publisherEditDog,
        path: RoutePaths.publisherEditDogPattern,
        pageBuilder: (context, state) => woofyPage(
          state,
          PublisherDogFormPage(dogId: state.pathParameters['dogId']),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.shelterLogin,
        path: RoutePaths.shelterLogin,
        pageBuilder: (context, state) => woofyPage(
          state,
          const ShelterLoginPage(),
          kind: WoofyTransition.fade,
        ),
      ),
      GoRoute(
        name: RouteNames.shelterEditProfile,
        path: RoutePaths.shelterEditProfile,
        pageBuilder: (context, state) => woofyPage(
          state,
          const ShelterEditProfilePage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.adopterEditProfile,
        path: RoutePaths.adopterEditProfile,
        pageBuilder: (context, state) => woofyPage(
          state,
          const AdopterEditProfilePage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.blockedAccounts,
        path: RoutePaths.blockedAccounts,
        pageBuilder: (context, state) => woofyPage(
          state,
          const BlockedAccountsPage(),
          kind: WoofyTransition.detail,
        ),
      ),
      GoRoute(
        name: RouteNames.deleteAccount,
        path: RoutePaths.deleteAccount,
        pageBuilder: (context, state) => woofyPage(
          state,
          const DeleteAccountPage(),
          kind: WoofyTransition.fade,
        ),
      ),
    ],
    redirect: (context, state) {
      final hasSession = ref.read(authRepositoryProvider).currentUser != null;
      final hasShelter = ref.read(shelterPortalSessionProvider).value != null;
      final location = state.matchedLocation;

      // Va primero: el enlace de recuperación crea una sesión válida, así que
      // cualquier regla posterior (sobre todo /auth -> /perfil) se llevaría al
      // usuario puertas afuera de la pantalla de contraseña nueva.
      if (ref.read(passwordRecoveryPendingProvider) &&
          location != RoutePaths.newPassword) {
        return RoutePaths.newPassword;
      }

      // Reservar guarda una fila con `user_id`, así que exige sesión igual que
      // favoritos y mensajes. El carrito queda afuera a propósito: se puede
      // armar sin cuenta y el login se pide recién al mandar el pedido, que es
      // lo único que escribe en la base.
      final protected =
          location == RoutePaths.favorites ||
          location == RoutePaths.messages ||
          location.startsWith('/mensajes/') ||
          location.endsWith('/postular') ||
          location.endsWith('/reservar');
      if (!hasSession && protected) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.profile && !hasSession && !hasShelter) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.adopterEditProfile && !hasSession) {
        return RoutePaths.auth;
      }
      if (location == RoutePaths.blockedAccounts && !hasSession) {
        return RoutePaths.auth;
      }
      // El historial se lee con RLS por `auth.uid()`: sin sesión no hay nada
      // que mostrar, así que se pide el login antes de entrar.
      if (location == RoutePaths.orders && !hasSession) {
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
  ref.listen(authEventsProvider, (_, next) {
    if (next.value == AuthLifecycleEvent.passwordRecovery) {
      ref.read(passwordRecoveryPendingProvider.notifier).start();
    }
    router.refresh();
  });
  ref.listen(passwordRecoveryPendingProvider, (_, _) => router.refresh());

  ref.onDispose(router.dispose);
  return router;
});

class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold>
    with SingleTickerProviderStateMixin {
  static final _lastIndex = (WoofyTab.values.length - 1).toDouble();

  /// Posición de la pastilla del nav, en unidades de slot. Es un controller y
  /// no un `int` porque el arrastre la mueve en fracciones: sin esto el
  /// selector solo podría saltar de un ítem a otro al soltar.
  late final AnimationController _indicator = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    lowerBound: 0,
    upperBound: _lastIndex,
    value: widget.navigationShell.currentIndex.toDouble(),
  );

  bool _dragging = false;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void didUpdateWidget(covariant _ShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El índice también cambia desde afuera (tocar un ítem, un `go` de otra
    // pantalla), así que la pastilla se sincroniza acá y no en el gesto.
    final index = navigationShell.currentIndex.toDouble();
    if (!_dragging && _indicator.value != index) {
      _indicator.animateTo(index, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _indicator.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) => _dragging = true;

  void _onDragUpdate(DragUpdateDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    if (width == 0) return;
    // Arrastrar un ancho de pantalla equivale a moverse una pestaña, igual que
    // el paginado de Instagram.
    _indicator.value = (_indicator.value - details.primaryDelta! / width).clamp(
      0.0,
      _lastIndex,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final current = navigationShell.currentIndex;
    final velocity = details.primaryVelocity ?? 0;
    // Un flick corto también cambia de pestaña aunque no se haya cruzado la
    // mitad del recorrido.
    final target = velocity.abs() > 400
        ? (velocity < 0 ? current + 1 : current - 1)
        : _indicator.value.round();
    final clamped = target.clamp(0, _lastIndex.toInt());

    if (clamped == current) {
      _indicator.animateTo(current.toDouble(), curve: Curves.easeOutCubic);
      return;
    }
    navigationShell.goBranch(clamped);
  }

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
        // El gesto va afuera de las páginas: un scroll horizontal de adentro
        // (un carrusel) gana la arena por ser más profundo, así que no le
        // robamos el arrastre a nadie.
        body: GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: navigationShell,
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _indicator,
          builder: (context, child) => WoofyBottomNavigation(
            currentIndex: navigationShell.currentIndex,
            indicatorPosition: _indicator.value,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}
