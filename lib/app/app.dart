import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/app/router.dart';
import 'package:mi_app/core/theme/woofy_theme.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';

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
    if (path == RoutePaths.profile || path == RoutePaths.favorites) {
      return RoutePaths.dogs;
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
