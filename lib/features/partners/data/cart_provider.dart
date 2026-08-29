import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/features/partners/data/partner_models.dart';

/// Una línea del carrito.
///
/// Guarda nombre y precio al momento de agregar para poder pintar el carrito
/// sin volver a pedir el catálogo. El precio real lo recalcula el servidor al
/// confirmar, así que esto es solo para mostrar.
class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final int unitPriceCents;
  final int quantity;
  final String? imageUrl;

  int get lineTotalCents => unitPriceCents * quantity;

  CartLine copyWith({int? quantity}) => CartLine(
    productId: productId,
    name: name,
    unitPriceCents: unitPriceCents,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl,
  );
}

/// Carrito de una veterinaria: sus datos mínimos + sus líneas.
class CartGroup {
  const CartGroup({
    required this.partnerId,
    required this.partnerName,
    required this.vetSlug,
    required this.lines,
    this.whatsappPhone,
  });

  final String partnerId;
  final String partnerName;
  final String vetSlug;
  final String? whatsappPhone;
  final List<CartLine> lines;

  int get totalCents =>
      lines.fold(0, (total, line) => total + line.lineTotalCents);

  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);

  CartGroup copyWith({List<CartLine>? lines}) => CartGroup(
    partnerId: partnerId,
    partnerName: partnerName,
    vetSlug: vetSlug,
    whatsappPhone: whatsappPhone,
    lines: lines ?? this.lines,
  );
}

/// Carrito agrupado por veterinaria.
///
/// Vive solo en memoria: no se persiste ni se sube a la base. La fila real se
/// crea recién al confirmar, con `create_partner_order`.
final cartProvider = NotifierProvider<Cart, Map<String, CartGroup>>(Cart.new);

class Cart extends Notifier<Map<String, CartGroup>> {
  @override
  Map<String, CartGroup> build() => const {};

  int get totalItemCount =>
      state.values.fold(0, (total, group) => total + group.itemCount);

  void add(Partner partner, PartnerProduct product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final next = Map<String, CartGroup>.from(state);
    final group =
        next[partner.id] ??
        CartGroup(
          partnerId: partner.id,
          partnerName: partner.name,
          vetSlug: partner.slug,
          whatsappPhone: partner.whatsappPhone,
          lines: const [],
        );

    final lines = List<CartLine>.from(group.lines);
    final index = lines.indexWhere((line) => line.productId == product.id);
    if (index >= 0) {
      lines[index] = lines[index].copyWith(
        quantity: lines[index].quantity + quantity,
      );
    } else {
      lines.add(
        CartLine(
          productId: product.id,
          name: product.name,
          unitPriceCents: product.priceCents,
          quantity: quantity,
          imageUrl: product.imageUrl,
        ),
      );
    }

    next[partner.id] = group.copyWith(lines: lines);
    state = next;
  }

  /// Fija la cantidad. Con `quantity <= 0` la línea se va, y si era la última
  /// de esa veterinaria el grupo entero desaparece: un carrito con un grupo
  /// vacío mostraría un botón "Comprar" que no compra nada.
  void setQuantity(String partnerId, String productId, int quantity) {
    final group = state[partnerId];
    if (group == null) return;

    final lines = group.lines
        .map(
          (line) => line.productId == productId
              ? line.copyWith(quantity: quantity)
              : line,
        )
        .where((line) => line.quantity > 0)
        .toList();

    final next = Map<String, CartGroup>.from(state);
    if (lines.isEmpty) {
      next.remove(partnerId);
    } else {
      next[partnerId] = group.copyWith(lines: lines);
    }
    state = next;
  }

  void increment(String partnerId, String productId) {
    final line = state[partnerId]?.lines.firstWhere(
      (line) => line.productId == productId,
      orElse: () => const CartLine(
        productId: '',
        name: '',
        unitPriceCents: 0,
        quantity: 0,
      ),
    );
    if (line == null || line.productId.isEmpty) return;
    setQuantity(partnerId, productId, line.quantity + 1);
  }

  void decrement(String partnerId, String productId) {
    final line = state[partnerId]?.lines.firstWhere(
      (line) => line.productId == productId,
      orElse: () => const CartLine(
        productId: '',
        name: '',
        unitPriceCents: 0,
        quantity: 0,
      ),
    );
    if (line == null || line.productId.isEmpty) return;
    setQuantity(partnerId, productId, line.quantity - 1);
  }

  void removeLine(String partnerId, String productId) =>
      setQuantity(partnerId, productId, 0);

  /// Vacía el carrito de una veterinaria. Se llama después de comprar, para no
  /// tocar lo que el usuario tenga cargado de las demás.
  void clearVet(String partnerId) {
    if (!state.containsKey(partnerId)) return;
    final next = Map<String, CartGroup>.from(state)..remove(partnerId);
    state = next;
  }

  void clear() => state = const {};
}

/// Cantidad total de unidades, para el globo del ícono del carrito.
final cartItemCountProvider = Provider<int>(
  (ref) => ref
      .watch(cartProvider)
      .values
      .fold(0, (total, group) => total + group.itemCount),
);
