import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/search/woofy_search.dart';

void main() {
  group('normalización', () {
    test('saca tildes y mayúsculas', () {
      expect(woofyNormalize('Bogotá'), 'bogota');
      expect(woofyNormalize('PEQUEÑO'), 'pequeno');
    });

    test('parte en palabras y descarta las de relleno', () {
      expect(woofyTokens('Refugio de los Andes'), ['refugio', 'andes']);
    });
  });

  group('coincidencias exactas', () {
    test('encuentra por nombre', () {
      expect(woofyMatches('milo', ['Milo', 'Refugio Sur']), isTrue);
    });

    test('encuentra por prefijo', () {
      expect(woofyMatches('lab', ['Labrador']), isTrue);
    });

    test('encuentra sin tilde lo que está con tilde', () {
      expect(woofyMatches('bogota', ['Bogotá']), isTrue);
    });
  });

  group('perdona errores de tipeo', () {
    test('una letra de más en una palabra larga', () {
      expect(woofyMatches('labrdor', ['Labrador retriever']), isTrue);
    });

    test('dos letras vecinas cambiadas de lugar', () {
      // El error más común de todos: los dedos llegan en el orden equivocado.
      expect(woofyMatches('Mlio', ['Milo']), isTrue);
      expect(woofyMatches('gaot', ['gato']), isTrue);
    });

    test('la última letra cambiada', () {
      expect(woofyMatches('perritp', ['perro', 'Milo']), isTrue);
    });

    test('no perdona errores en palabras de tres letras', () {
      // Con tres letras, un error la convierte en otra palabra distinta.
      expect(woofyMatches('gat', ['pat']), isFalse);
    });

    test('no perdona el error en la primera letra', () {
      // Los dedos erran en el medio de la palabra, no en el arranque. Sin esta
      // regla, buscar "pato" devolvería todos los gatos.
      expect(woofyMatches('pato', ['gato']), isFalse);
    });

    test('no junta palabras lejanas', () {
      expect(
        woofyMatches('elefante', ['perro', 'Milo', 'Refugio Sur']),
        isFalse,
      );
    });
  });

  group('entiende qué quiere el usuario', () {
    test('gatito encuentra un gato', () {
      expect(woofyMatches('gatito', ['gato', 'Nube']), isTrue);
    });

    test('michi encuentra un gato', () {
      expect(woofyMatches('michi', ['gato', 'Nube']), isTrue);
    });

    test('remera encuentra una polera', () {
      expect(woofyMatches('remera', ['Polera Woofy']), isTrue);
    });

    test('vet encuentra una veterinaria', () {
      expect(woofyMatches('vet', ['Veterinaria Central']), isTrue);
    });

    test('chico encuentra un pequeño', () {
      expect(woofyMatches('chico', ['pequeño', 'Milo']), isTrue);
    });
  });

  group('varias palabras', () {
    test('todas las palabras tienen que aparecer', () {
      // Agregar una palabra tiene que achicar la lista, nunca agrandarla.
      expect(woofyMatches('milo grande', ['Milo', 'pequeño']), isFalse);
      expect(woofyMatches('milo grande', ['Milo', 'grande']), isTrue);
    });

    test('las palabras no necesitan estar pegadas', () {
      expect(
        woofyMatches('milo sur', ['Milo', 'macho', 'Refugio Sur']),
        isTrue,
      );
    });
  });

  group('puntaje', () {
    test('lo exacto puntea más que lo perdonado', () {
      final exact = woofySearchScore('milo', ['Milo']);
      final prefix = woofySearchScore('mil', ['Milo']);
      final fuzzy = woofySearchScore('milp', ['Milo']);
      expect(exact, greaterThan(prefix));
      expect(prefix, greaterThan(fuzzy));
      expect(fuzzy, greaterThan(0));
    });

    test('una búsqueda vacía no devuelve nada', () {
      expect(woofySearchScore('', ['Milo']), 0);
      expect(woofySearchScore('   ', ['Milo']), 0);
    });

    test('un resultado sin texto no coincide con nada', () {
      expect(woofySearchScore('milo', [null, '']), 0);
    });
  });
}
