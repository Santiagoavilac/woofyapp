import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';

Widget _wrap({required bool reduceMotion, required Widget child}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

Widget _row({required bool reduceMotion, int itemCount = 3}) => _wrap(
  reduceMotion: reduceMotion,
  child: SizedBox(
    height: 100,
    child: WoofyStaggeredRow(
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) =>
          SizedBox(width: 80, child: Text('card-$index')),
    ),
  ),
);

Widget _column({required bool reduceMotion, int itemCount = 3}) => _wrap(
  reduceMotion: reduceMotion,
  child: SingleChildScrollView(
    child: WoofyStaggeredColumn(
      children: [
        for (var index = 0; index < itemCount; index++) Text('card-$index'),
      ],
    ),
  ),
);

Widget _sliver({required bool reduceMotion, int itemCount = 3}) => _wrap(
  reduceMotion: reduceMotion,
  child: CustomScrollView(
    slivers: [
      WoofySliverStagger(
        sliver: SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) =>
              WoofyReveal.indexed(index: index, child: Text('card-$index')),
        ),
      ),
    ],
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
  testWidgets('the row fades in and settles fully visible', (tester) async {
    await tester.pumpWidget(_row(reduceMotion: false));

    // En el primer cuadro las tarjetas todavía no terminaron de entrar.
    expect(_opacityOf(tester, 'card-0'), lessThan(1));

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'card-0'), 1);
    expect(_opacityOf(tester, 'card-1'), 1);
  });

  testWidgets('later cards start after the first one', (tester) async {
    await tester.pumpWidget(_row(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 120));

    // El escalonado es lo que hace que la fila se arme de izquierda a derecha.
    expect(
      _opacityOf(tester, 'card-1'),
      lessThan(_opacityOf(tester, 'card-0')),
    );
  });

  testWidgets('reduced motion paints the row complete on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(_row(reduceMotion: true));

    // Son tarjetas de contenido: con el movimiento apagado tienen que estar
    // enteras ya, no desvanecidas esperando una animación que no va a correr.
    expect(_opacityOf(tester, 'card-0'), 1);
    expect(_opacityOf(tester, 'card-2'), 1);
  });

  testWidgets('the column staggers top to bottom and settles visible', (
    tester,
  ) async {
    await tester.pumpWidget(_column(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      _opacityOf(tester, 'card-1'),
      lessThan(_opacityOf(tester, 'card-0')),
    );

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'card-2'), 1);
  });

  testWidgets('reduced motion paints the column complete on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(_column(reduceMotion: true));

    expect(_opacityOf(tester, 'card-0'), 1);
    expect(_opacityOf(tester, 'card-2'), 1);
  });

  testWidgets('the sliver staggers its items and settles visible', (
    tester,
  ) async {
    await tester.pumpWidget(_sliver(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      _opacityOf(tester, 'card-1'),
      lessThan(_opacityOf(tester, 'card-0')),
    );

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'card-2'), 1);
  });

  testWidgets('reduced motion paints the sliver complete on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(_sliver(reduceMotion: true));

    expect(_opacityOf(tester, 'card-0'), 1);
    expect(_opacityOf(tester, 'card-2'), 1);
  });

  testWidgets('a reveal without a group is painted whole', (tester) async {
    await tester.pumpWidget(
      _wrap(
        reduceMotion: false,
        child: const WoofyReveal.indexed(index: 3, child: Text('card-0')),
      ),
    );

    // Sin grupo ancestro no hay quién dispare la animación: el contenido no
    // puede quedarse invisible esperándola.
    expect(_opacityOf(tester, 'card-0'), 1);
  });
}
