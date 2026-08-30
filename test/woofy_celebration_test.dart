import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/shared/widgets/woofy_celebration.dart';

Widget _celebration({
  required bool reduceMotion,
  Size size = const Size(320, 568),
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion, size: size),
  child: const Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: SingleChildScrollView(
        child: WoofyCelebration(
          title: '¡Milo ya sabe de vos!',
          body: 'Tu postulación fue enviada correctamente.',
        ),
      ),
    ),
  ),
);

double _opacityOf(WidgetTester tester, String text) {
  final fade = tester.widget<FadeTransition>(
    find
        .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
        .first,
  );
  return fade.opacity.value;
}

void main() {
  testWidgets('the title arrives after the check and ends fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(_celebration(reduceMotion: false));

    // El título entra sobre el final: primero se dibuja el check.
    expect(_opacityOf(tester, '¡Milo ya sabe de vos!'), 0);

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, '¡Milo ya sabe de vos!'), 1);
    expect(_opacityOf(tester, 'Tu postulación fue enviada correctamente.'), 1);
  });

  testWidgets('reduced motion paints the whole message on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(_celebration(reduceMotion: true));

    // Es el cierre del recorrido más importante de la app: si la animación no
    // corre, el mensaje tiene que estar igual de completo.
    expect(_opacityOf(tester, '¡Milo ya sabe de vos!'), 1);
    expect(_opacityOf(tester, 'Tu postulación fue enviada correctamente.'), 1);
  });

  testWidgets('it fits a 320x568 screen without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_celebration(reduceMotion: false));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
