import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';

void main() {
  testWidgets('WoofyButton runs its action and exposes loading state', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WoofyButton(
            label: 'Continuar',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continuar'));
    expect(pressed, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WoofyButton(
            label: 'Continuar',
            onPressed: null,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('WoofyEmptyState presents and runs its optional action', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WoofyEmptyState(
            title: 'Sin resultados',
            message: 'Probá otra búsqueda.',
            actionLabel: 'Reintentar',
            onAction: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Sin resultados'), findsOneWidget);
    expect(find.text('Probá otra búsqueda.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(pressed, isTrue);
  });
}
