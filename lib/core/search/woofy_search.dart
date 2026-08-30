/// Búsqueda que perdona.
///
/// Antes cada pantalla armaba un `haystack` y preguntaba `haystack.contains(
/// query)`. Eso obliga a la persona a escribir exactamente lo mismo que hay en
/// la base: "labrdor" no encontraba a ningún labrador, "gatito" no encontraba
/// ningún gato y "Milo grande" no encontraba nada porque las dos palabras no
/// aparecen pegadas en ningún lado.
///
/// Acá se resuelven las tres cosas: se compara palabra por palabra (no la
/// frase entera), se aguantan errores de tipeo proporcionales al largo de la
/// palabra, y se traduce lo que la gente escribe a lo que la base guarda.
library;

/// Cuántas letras puede errar una palabra de este largo y seguir contando.
///
/// Escalonado a propósito: en una palabra de tres letras un error la convierte
/// en otra palabra distinta, en una de ocho es un dedo que resbaló.
int _budget(int length) {
  if (length <= 3) return 0;
  if (length <= 6) return 1;
  return 2;
}

/// Palabras que la gente escribe y lo que la base realmente guarda.
///
/// Es la parte de "entender qué quiere el usuario": nadie busca "canino", pero
/// tampoco todos escriben "perro". La clave es lo que se teclea, el valor es el
/// término que existe en los datos.
const _aliases = <String, String>{
  // Especies
  'perros': 'perro',
  'perrito': 'perro',
  'perrita': 'perro',
  'perritos': 'perro',
  'perras': 'perro',
  'perra': 'perro',
  'can': 'perro',
  'canino': 'perro',
  'gatos': 'gato',
  'gatito': 'gato',
  'gatita': 'gato',
  'gatitos': 'gato',
  'gata': 'gato',
  'michi': 'gato',
  'minino': 'gato',
  'felino': 'gato',
  // Sexo
  'macho': 'macho',
  'machito': 'macho',
  'hembra': 'hembra',
  'hembrita': 'hembra',
  // Tamaño
  'chico': 'pequeno',
  'chica': 'pequeno',
  'pequenio': 'pequeno',
  'peque': 'pequeno',
  'mediana': 'mediano',
  'grandes': 'grande',
  'grandote': 'grande',
  // Merch: nadie busca "producto", busca la prenda.
  'polera': 'polera',
  'poleras': 'polera',
  'remera': 'polera',
  'remeras': 'polera',
  'camiseta': 'polera',
  'camisetas': 'polera',
  'playera': 'polera',
  'gorras': 'gorra',
  'tazas': 'taza',
  'buzos': 'buzo',
  // Servicios
  'veterinaria': 'veterinaria',
  'veterinarias': 'veterinaria',
  'veterinario': 'veterinaria',
  'vet': 'veterinaria',
  'vets': 'veterinaria',
  'peluqueria': 'peluqueria',
  'peluquero': 'peluqueria',
  'guarderia': 'guarderia',
  'paseador': 'paseo',
  'paseos': 'paseo',
  'adopcion': 'adopcion',
  'adoptar': 'adopcion',
  'refugios': 'refugio',
  'albergue': 'refugio',
};

/// Palabras que no aportan nada a la búsqueda y solo generan ruido.
const _stopWords = <String>{
  'de',
  'del',
  'la',
  'las',
  'el',
  'los',
  'un',
  'una',
  'unos',
  'unas',
  'y',
  'o',
  'en',
  'con',
  'para',
  'por',
  'que',
  'al',
};

const _accents = <String, String>{
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Minúsculas y sin tildes.
///
/// Sin esto "Bogotá" no se encuentra escribiendo "bogota", que es como lo
/// escribe casi todo el mundo en un teclado de teléfono apurado.
String woofyNormalize(String value) {
  final buffer = StringBuffer();
  for (final char in value.toLowerCase().split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Parte un texto en palabras buscables.
List<String> woofyTokens(String value) {
  return woofyNormalize(value)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty && !_stopWords.contains(token))
      .toList();
}

/// Lleva una palabra tecleada al término que existe en los datos.
///
/// Primero busca el alias exacto y, si no lo encuentra, lo busca perdonando
/// errores: "perritp" es un error de tipeo de "perrito", que a su vez quiere
/// decir "perro". Sin este segundo paso, un dedo resbalado rompe la traducción.
String _canonical(String token) {
  final direct = _aliases[token];
  if (direct != null) return direct;
  final budget = _budget(token.length);
  if (budget == 0) return token;
  for (final entry in _aliases.entries) {
    if (_within(token, entry.key, budget)) return entry.value;
  }
  return token;
}

/// Distancia de edición, cortada apenas se pasa del presupuesto.
///
/// Se corta temprano no por velocidad sino por claridad: lo único que importa
/// es si entra o no en el presupuesto, nunca cuánto se pasó.
///
/// Cuenta el cambio de dos letras vecinas como un solo error y no como dos.
/// Escribir "Mlio" en vez de "Milo" es el error de tipeo más común que hay —
/// los dedos llegan en el orden equivocado — y sin esto costaba lo mismo que
/// equivocarse dos veces, o sea que no se perdonaba nunca.
bool _within(String a, String b, int budget) {
  if ((a.length - b.length).abs() > budget) return false;
  // La primera letra tiene que coincidir. Los dedos erran en el medio de la
  // palabra, no en el arranque, y sin esta guarda "pato" encontraría "gato".
  if (a.isEmpty || b.isEmpty || a.codeUnitAt(0) != b.codeUnitAt(0)) {
    return false;
  }

  List<int>? beforePrevious;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    var best = current[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var value = [
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      final swapped =
          i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1);
      if (swapped) {
        final withSwap = beforePrevious![j - 2] + 1;
        if (withSwap < value) value = withSwap;
      }
      current[j] = value;
      if (value < best) best = value;
    }
    if (best > budget) return false;
    beforePrevious = previous;
    previous = current;
  }
  return previous[b.length] <= budget;
}

/// Qué tan bien una palabra tecleada le pega a las palabras de un resultado.
///
/// Devuelve 0 si no le pega. Los puntos ordenan: quien coincide exacto tiene
/// que aparecer antes que quien coincide por un prefijo, y ese antes que quien
/// coincide sólo porque se le perdonó un error.
int _tokenScore(String queryToken, List<String> haystack) {
  final canonical = _canonical(queryToken);
  final variants = canonical == queryToken
      ? <String>[queryToken]
      : <String>[queryToken, canonical];

  var best = 0;
  for (final variant in variants) {
    for (final word in haystack) {
      if (word == variant) return 4;
      if (word.startsWith(variant)) {
        best = best > 3 ? best : 3;
        continue;
      }
      if (best < 2 && _within(variant, word, _budget(variant.length))) {
        best = 2;
      }
    }
  }
  return best;
}

/// Puntaje de un resultado frente a una búsqueda. 0 quiere decir "no aparece".
///
/// Todas las palabras tecleadas tienen que encontrar algo. "Milo grande" no
/// puede devolver a todos los Milo ni a todos los grandes: agregar una palabra
/// tiene que achicar la lista, nunca agrandarla.
int woofySearchScore(String query, Iterable<String?> fields) {
  final tokens = woofyTokens(query);
  if (tokens.isEmpty) return 0;

  final haystack = <String>[];
  for (final field in fields) {
    if (field == null || field.isEmpty) continue;
    haystack.addAll(woofyTokens(field));
  }
  if (haystack.isEmpty) return 0;

  var total = 0;
  for (final token in tokens) {
    final score = _tokenScore(token, haystack);
    if (score == 0) return 0;
    total += score;
  }
  return total;
}

/// Versión de sí o no, para filtrar listas.
bool woofyMatches(String query, Iterable<String?> fields) =>
    woofySearchScore(query, fields) > 0;
