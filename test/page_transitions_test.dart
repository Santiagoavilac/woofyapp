import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/page_transitions.dart';

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  required WoofyTransition kind,
  bool reduceMotion = false,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => woofyPage(
          state,
          const Scaffold(body: Text('inicio')),
          kind: WoofyTransition.branch,
        ),
      ),
      GoRoute(
        path: '/destino',
        pageBuilder: (context, state) =>
            woofyPage(state, const Scaffold(body: Text('destino')), kind: kind),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('the shell branches carry no transition at all', (tester) async {
    final router = await _pumpRouter(tester, kind: WoofyTransition.branch);
    router.push('/destino');
    await tester.pump();

    // Es obligatorio que sea nula: la barra de abajo ya anima su pastilla y
    // dos animaciones a la vez hacen que cambiar de pestaña se sienta roto.
    expect(tester.getTopLeft(find.text('destino')), Offset.zero);
    await tester.pumpAndSettle();
  });

  testWidgets('a detail slides in from the side and settles in place', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, kind: WoofyTransition.detail);
    router.push('/destino');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final offset = tester.getTopLeft(find.text('destino'));
    expect(offset.dx, greaterThan(0));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('destino')).dx, 0);
  });

  testWidgets('the commit screen rises from below instead of the side', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, kind: WoofyTransition.commit);
    router.push('/destino');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // Postular sube como una hoja que se apoya: es el momento de decidir, no
    // uno más de navegar de costado.
    final offset = tester.getTopLeft(find.text('destino'));
    expect(offset.dx, 0);
    expect(offset.dy, greaterThan(0));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('destino')).dy, 0);
  });

  testWidgets('reduced motion lands the page already in place', (tester) async {
    final router = await _pumpRouter(
      tester,
      kind: WoofyTransition.commit,
      reduceMotion: true,
    );
    router.push('/destino');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.getTopLeft(find.text('destino')), Offset.zero);
    await tester.pumpAndSettle();
  });
}
