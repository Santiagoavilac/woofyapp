import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/partner_models.dart';

const _vetA = Partner(
  id: 'vet-a',
  name: 'Partner Santa Cruz',
  slug: 'vet-santa-cruz',
  whatsappPhone: '70123456',
);

const _vetB = Partner(id: 'vet-b', name: 'Partner La Paz', slug: 'vet-la-paz');

const _alimento = PartnerProduct(
  id: 'p1',
  partnerId: 'vet-a',
  name: 'Alimento Premium',
  priceCents: 15000,
);

const _collar = PartnerProduct(
  id: 'p2',
  partnerId: 'vet-a',
  name: 'Collar',
  priceCents: 4550,
);

const _juguete = PartnerProduct(
  id: 'p3',
  partnerId: 'vet-b',
  name: 'Juguete',
  priceCents: 3000,
);

const _store = Partner(
  id: 'store-1',
  name: 'Woofy Merch',
  slug: 'woofy-merch',
  isWoofyStore: true,
  categories: [PartnerCategory.shop],
);

const _talleS = PartnerProductVariant(
  id: 'size-s',
  productId: 'p4',
  sizeLabel: 'S',
  stock: 4,
);

const _talleM = PartnerProductVariant(
  id: 'size-m',
  productId: 'p4',
  sizeLabel: 'M',
  stock: 4,
);

const _polera = PartnerProduct(
  id: 'p4',
  partnerId: 'store-1',
  name: 'Polera Woofy negra',
  priceCents: 12500,
  variants: [_talleS, _talleM],
);

void main() {
  late ProviderContainer container;
  late Cart cart;

  setUp(() {
    container = ProviderContainer();
    cart = container.read(cartProvider.notifier);
    addTearDown(container.dispose);
  });

  Map<String, CartGroup> get() => container.read(cartProvider);

  group('agrupación por veterinaria', () {
    test('mantiene un grupo por cada veterinaria', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetB, _juguete);

      expect(get().keys, ['vet-a', 'vet-b']);
      expect(get()['vet-a']!.lines.single.name, 'Alimento Premium');
      expect(get()['vet-b']!.lines.single.name, 'Juguete');
    });

    test('guarda el WhatsApp de cada veterinaria en su grupo', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetB, _juguete);

      expect(get()['vet-a']!.whatsappPhone, '70123456');
      expect(get()['vet-b']!.whatsappPhone, isNull);
    });

    test('agregar el mismo producto suma cantidad en vez de duplicar', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetA, _alimento);

      expect(get()['vet-a']!.lines, hasLength(1));
      expect(get()['vet-a']!.lines.single.quantity, 2);
    });

    test('ignora cantidades no positivas', () {
      cart.add(_vetA, _alimento, quantity: 0);
      cart.add(_vetA, _alimento, quantity: -3);

      expect(get(), isEmpty);
    });
  });

  group('totales', () {
    test('suma en centavos enteros, sin pasar por flotante', () {
      cart.add(_vetA, _alimento, quantity: 2);
      cart.add(_vetA, _collar);

      final group = get()['vet-a']!;
      expect(group.lines.first.lineTotalCents, 30000);
      expect(group.totalCents, 34550);
      expect(group.itemCount, 3);
    });

    test('el total de una veterinaria no arrastra el de la otra', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetB, _juguete, quantity: 2);

      expect(get()['vet-a']!.totalCents, 15000);
      expect(get()['vet-b']!.totalCents, 6000);
      expect(container.read(cartItemCountProvider), 3);
    });
  });

  group('cantidades', () {
    test('increment y decrement mueven una sola línea', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetA, _collar);

      cart.increment('vet-a', 'p1');
      expect(get()['vet-a']!.lines.first.quantity, 2);
      expect(get()['vet-a']!.lines.last.quantity, 1);

      cart.decrement('vet-a', 'p1');
      expect(get()['vet-a']!.lines.first.quantity, 1);
    });

    test('bajar a cero saca la línea pero deja el resto del grupo', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetA, _collar);

      cart.decrement('vet-a', 'p1');

      expect(get()['vet-a']!.lines, hasLength(1));
      expect(get()['vet-a']!.lines.single.productId, 'p2');
    });

    test('sacar la última línea borra el grupo entero', () {
      cart.add(_vetA, _alimento);

      cart.removeLine('vet-a', 'p1');

      // Un grupo sin líneas pintaría un botón "Comprar" que no compra nada.
      expect(get().containsKey('vet-a'), isFalse);
    });

    test('no hace nada con ids que no están en el carrito', () {
      cart.add(_vetA, _alimento);

      cart.increment('vet-z', 'p1');
      cart.decrement('vet-a', 'no-existe');
      cart.setQuantity('vet-z', 'p1', 5);

      expect(get()['vet-a']!.lines.single.quantity, 1);
      expect(get().keys, ['vet-a']);
    });
  });

  group('talles', () {
    test('la misma polera en S y en M son dos líneas', () {
      cart.add(_store, _polera, variant: _talleS);
      cart.add(_store, _polera, variant: _talleM);

      // Sin la variante en la clave, la M le habría subido la cantidad a la S
      // y el pedido saldría con el talle equivocado.
      final lines = get()['store-1']!.lines;
      expect(lines, hasLength(2));
      expect(lines.map((line) => line.sizeLabel), ['S', 'M']);
      expect(lines.every((line) => line.quantity == 1), isTrue);
    });

    test('el mismo talle sí suma cantidad', () {
      cart.add(_store, _polera, variant: _talleM);
      cart.add(_store, _polera, quantity: 2, variant: _talleM);

      final line = get()['store-1']!.lines.single;
      expect(line.quantity, 3);
      expect(line.lineKey, 'p4:size-m');
    });

    test('un producto sin variante conserva su id como clave', () {
      cart.add(_vetA, _alimento);

      final line = get()['vet-a']!.lines.single;
      expect(line.lineKey, 'p1');
      expect(line.variantId, isNull);
      expect(line.sizeLabel, isNull);
    });

    test('mover un talle no toca el otro', () {
      cart.add(_store, _polera, quantity: 2, variant: _talleS);
      cart.add(_store, _polera, quantity: 2, variant: _talleM);

      cart.increment('store-1', 'p4:size-s');
      cart.decrement('store-1', 'p4:size-m');

      final lines = get()['store-1']!.lines;
      expect(lines.firstWhere((line) => line.sizeLabel == 'S').quantity, 3);
      expect(lines.firstWhere((line) => line.sizeLabel == 'M').quantity, 1);
    });

    test('sacar un talle deja el otro en el carrito', () {
      cart.add(_store, _polera, variant: _talleS);
      cart.add(_store, _polera, variant: _talleM);

      cart.removeLine('store-1', 'p4:size-s');

      expect(get()['store-1']!.lines.single.sizeLabel, 'M');
    });

    test('la merch y la veterinaria quedan en grupos separados', () {
      cart.add(_store, _polera, variant: _talleM);
      cart.add(_vetA, _alimento);

      cart.clearVet('store-1');

      expect(get().containsKey('store-1'), isFalse);
      expect(get()['vet-a']!.lines.single.name, 'Alimento Premium');
    });
  });

  group('vaciado', () {
    test('clearVet solo toca la veterinaria comprada', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetB, _juguete);

      cart.clearVet('vet-a');

      expect(get().keys, ['vet-b']);
    });

    test('clear deja el carrito vacío', () {
      cart.add(_vetA, _alimento);
      cart.add(_vetB, _juguete);

      cart.clear();

      expect(get(), isEmpty);
      expect(container.read(cartItemCountProvider), 0);
    });
  });
}
