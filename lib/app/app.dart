import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/core/theme/woofy_theme.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';

class WoofyApp extends ConsumerStatefulWidget {
  const WoofyApp({super.key});

  @override
  ConsumerState<WoofyApp> createState() => _WoofyAppState();
}

class _WoofyAppState extends ConsumerState<WoofyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed) return;
    if (ref.read(googleSignInStatusProvider) !=
        GoogleSignInStatus.awaitingCallback) {
      return;
    }
    // El deep link puede resolver unos instantes después del resume, así que
    // damos margen antes de asumir que el usuario cerró el navegador.
    Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final notifier = ref.read(googleSignInStatusProvider.notifier);
      if (ref.read(googleSignInStatusProvider) !=
          GoogleSignInStatus.awaitingCallback) {
        return;
      }
      if (ref.read(currentUserProvider) != null) {
        notifier.reset();
      } else {
        notifier.markCancelled();
      }
    });
  }

  @override
  Future<bool> didPopRoute() async {
    final router = ref.read(routerProvider);
    if (await router.routerDelegate.popRoute()) {
      return true;
    }

    final fallback = _fallbackFor(
      router.routerDelegate.currentConfiguration.uri,
    );
    if (fallback == null) return false;

    router.go(fallback);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user == null) return;
        ref.read(googleSignInStatusProvider.notifier).reset();
        unawaited(
          ref
              .read(authControllerProvider.notifier)
              .ensureAuthenticatedProfile(user)
              .catchError((_) {}),
        );
      });
    });
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Woofy',
      debugShowCheckedModeBanner: false,
      theme: WoofyTheme.light,
      routerConfig: router,
    );
  }

  String? _fallbackFor(Uri uri) {
    final path = uri.path;
    if (path == RoutePaths.dogs) return RoutePaths.landing;
    if (path == RoutePaths.shelterLogin) return RoutePaths.dogs;
    if (path == RoutePaths.profile ||
        path == RoutePaths.favorites ||
        path == RoutePaths.messages) {
      return RoutePaths.dogs;
    }
    if (path == RoutePaths.adopterEditProfile ||
        path == RoutePaths.shelterEditProfile ||
        path == RoutePaths.deleteAccount) {
      return RoutePaths.profile;
    }
    if (RegExp(r'^/mensajes/[^/]+$').hasMatch(path)) {
      return RoutePaths.messages;
    }
    final applicationMatch = RegExp(
      r'^/perros/([^/]+)/postular$',
    ).firstMatch(path);
    if (applicationMatch != null) {
      return RoutePaths.dogDetail(
        Uri.decodeComponent(applicationMatch.group(1)!),
      );
    }
    if (RegExp(r'^/perros/[^/]+$').hasMatch(path)) {
      return RoutePaths.dogs;
    }
    return null;
  }
}
