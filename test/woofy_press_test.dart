import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/shared/widgets/woofy_press.dart';

Widget _pressable({required bool reduceMotion, VoidCallback? onTap}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: WoofyPressable(
              child: InkWell(
                key: const ValueKey('inner-tap'),
                onTap: onTap,
                child: const SizedBox(width: 120, height: 60, child: Text('x')),
              ),
            ),
          ),
        ),
      ),
    );

double _scaleOf(WidgetTester tester) {
  final transition = tester.widget<ScaleTransition>(
    find.byType(ScaleTransition),
  );
  return transition.scale.value;
}

void main() {
  testWidgets('shrinks while pressed and settles back at one', (tester) async {
    await tester.pumpWidget(_pressable(reduceMotion: false));
    expect(_scaleOf(tester), 1);

    final gesture = await tester.startGesture(tester.getCenter(find.text('x')));
    // El primer cuadro solo arranca el ticker; el segundo ya corre el tiempo.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(_scaleOf(tester), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1);
  });

  testWidgets('the rebound overshoots past its resting size', (tester) async {
    await tester.pumpWidget(_pressable(reduceMotion: false));
    final gesture = await tester.startGesture(tester.getCenter(find.text('x')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await gesture.up();

    // El rebote al soltar es lo que se lee como "vivo": si la escala volviera
    // derecho a 1 el gesto se sentiría muerto.
    var biggest = 1.0;
    for (var frame = 0; frame < 24; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
      biggest = math.max(biggest, _scaleOf(tester));
    }
    expect(biggest, greaterThan(1));
    await tester.pumpAndSettle();
  });

  testWidgets('it does not steal the tap from the child', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _pressable(reduceMotion: false, onTap: () => taps += 1),
    );

    await tester.tap(find.byKey(const ValueKey('inner-tap')));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('reduced motion leaves the child untouched', (tester) async {
    await tester.pumpWidget(_pressable(reduceMotion: true));

    expect(find.byType(ScaleTransition), findsNothing);
    expect(find.text('x'), findsOneWidget);
  });
}
