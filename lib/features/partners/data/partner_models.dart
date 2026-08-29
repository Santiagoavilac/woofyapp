/// Modelos de la vertical de aliados: veterinarias, paseadores, peluquerías,
/// hoteles caninos. Todos son el mismo negocio con distinto rubro.
///
/// El dinero viaja y se guarda siempre como enteros de centavos. Nunca se pasa
/// a `double` para operar: sumar precios en flotante termina en totales que no
/// cierran contra los del panel web.
library;

/// Rubros de un aliado. Los identificadores son los del enum
/// `public.partner_category` en Postgres y por eso van en inglés: renombrar un
/// valor de enum es una migración, renombrar la etiqueta que ve el usuario es
/// cambiar una línea acá.
enum PartnerCategory {
  vet('vet', 'Veterinaria'),
  vaccination('vaccination', 'Vacunación'),
  emergency('emergency', 'Urgencias'),
  grooming('grooming', 'Peluquería'),
  walking('walking', 'Paseos'),
  boarding('boarding', 'Hotel'),
  training('training', 'Adiestramiento'),
  transport('transport', 'Transporte'),
  homeCare('home_care', 'A domicilio'),
  shop('shop', 'Tienda');

  const PartnerCategory(this.id, this.label);

  final String id;
  final String label;

  static PartnerCategory? tryParse(Object? value) {
    final id = value?.toString();
    for (final category in PartnerCategory.values) {
      if (category.id == id) return category;
    }
    // Un rubro nuevo en la base no puede tumbar una app vieja: se ignora.
    return null;
  }

  static List<PartnerCategory> parseList(Object? value) => value is List
      ? value.map(PartnerCategory.tryParse).nonNulls.toList()
      : const [];
}

class Partner {
  const Partner({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.city,
    this.address,
    this.locationNotes,
    this.whatsappPhone,
    this.phone,
    this.email,
    this.instagram,
    this.facebook,
    this.website,
    this.profileImagePath,
    this.coverImagePath,
    this.profileImageUrl,
    this.coverImageUrl,
    this.verified = false,
    this.status,
    this.categories = const [],
  });

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
    id: _string(json['id']),
    name: _string(json['name']),
    slug: _string(json['slug']),
    description: _nullableString(json['description']),
    city: _nullableString(json['city']),
    address: _nullableString(json['address']),
    locationNotes: _nullableString(json['location_notes']),
    whatsappPhone: _nullableString(json['whatsapp_phone']),
    phone: _nullableString(json['phone']),
    email: _nullableString(json['email']),
    instagram: _nullableString(json['instagram']),
    facebook: _nullableString(json['facebook']),
    website: _nullableString(json['website']),
    profileImagePath: _nullableString(json['profile_image_path']),
    coverImagePath: _nullableString(json['cover_image_path']),
    verified: _bool(json['verified']) ?? false,
    status: _nullableString(json['status']),
    categories: PartnerCategory.parseList(json['categories']),
  );

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? city;
  final String? address;
  final String? locationNotes;
  final String? whatsappPhone;
  final String? phone;
  final String? email;
  final String? instagram;
  final String? facebook;
  final String? website;
  final String? profileImagePath;
  final String? coverImagePath;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final bool verified;
  final String? status;
  final List<PartnerCategory> categories;

  /// Hay algo escrito con qué buscar al aliado en el mapa.
  bool get hasLocation =>
      (address?.isNotEmpty ?? false) || (city?.isNotEmpty ?? false);

  bool get isVet => categories.contains(PartnerCategory.vet);

  Partner copyWith({String? profileImageUrl, String? coverImageUrl}) => Partner(
    id: id,
    name: name,
    slug: slug,
    description: description,
    city: city,
    address: address,
    locationNotes: locationNotes,
    whatsappPhone: whatsappPhone,
    phone: phone,
    email: email,
    instagram: instagram,
    facebook: facebook,
    website: website,
    profileImagePath: profileImagePath,
    coverImagePath: coverImagePath,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    verified: verified,
    status: status,
    categories: categories,
  );
}

class PartnerProduct {
  const PartnerProduct({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.priceCents,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.stock,
    this.position = 0,
  });

  factory PartnerProduct.fromJson(Map<String, dynamic> json) => PartnerProduct(
    id: _string(json['id']),
    partnerId: _string(json['partner_id']),
    name: _string(json['name']),
    priceCents: _int(json['price_cents']) ?? 0,
    description: _nullableString(json['description']),
    imagePath: _nullableString(json['image_path']),
    stock: _int(json['stock']),
    position: _int(json['position']) ?? 0,
  );

  final String id;
  final String partnerId;
  final String name;
  final int priceCents;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final int? stock;
  final int position;

  /// `stock` nulo significa "sin control de stock", no "sin unidades".
  bool get isAvailable => stock == null || stock! > 0;

  PartnerProduct copyWith({String? imageUrl}) => PartnerProduct(
    id: id,
    partnerId: partnerId,
    name: name,
    priceCents: priceCents,
    description: description,
    imagePath: imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    stock: stock,
    position: position,
  );
}

class PartnerService {
  const PartnerService({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.priceCents,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.position = 0,
    this.durationMinutes,
    this.kinds = const [],
    this.partnerName,
    this.partnerSlug,
    this.partnerCity,
  });

  factory PartnerService.fromJson(Map<String, dynamic> json) {
    final partner = _singleMap(json['partners']);
    return PartnerService(
      id: _string(json['id']),
      partnerId: _string(json['partner_id']),
      name: _string(json['name']),
      priceCents: _int(json['price_cents']) ?? 0,
      description: _nullableString(json['description']),
      imagePath: _nullableString(json['image_path']),
      position: _int(json['position']) ?? 0,
      durationMinutes: _int(json['duration_minutes']),
      kinds: PartnerCategory.parseList(json['kinds']),
      partnerName: _nullableString(partner?['name']),
      partnerSlug: _nullableString(partner?['slug']),
      partnerCity: _nullableString(partner?['city']),
    );
  }

  final String id;
  final String partnerId;
  final String name;
  final int priceCents;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final int position;
  final int? durationMinutes;

  /// Rubros del servicio, hasta cuatro. Son los que alimentan los filtros de
  /// la pantalla de Servicios, y pueden ser un subconjunto de los del negocio:
  /// una veterinaria que además pasea perros marca `walking` solo en ese
  /// servicio, no en toda la ficha.
  final List<PartnerCategory> kinds;

  /// Datos del aliado que lo ofrece. Vienen del join y quedan nulos cuando el
  /// servicio se leyó desde el perfil, donde el aliado ya se conoce.
  final String? partnerName;
  final String? partnerSlug;
  final String? partnerCity;

  PartnerService copyWith({String? imageUrl}) => PartnerService(
    id: id,
    partnerId: partnerId,
    name: name,
    priceCents: priceCents,
    description: description,
    imagePath: imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    position: position,
    durationMinutes: durationMinutes,
    kinds: kinds,
    partnerName: partnerName,
    partnerSlug: partnerSlug,
    partnerCity: partnerCity,
  );
}

/// Veterinaria con su catálogo, tal como la muestra el detalle.
class PartnerDetail {
  const PartnerDetail({
    required this.partner,
    this.products = const [],
    this.services = const [],
  });

  final Partner partner;
  final List<PartnerProduct> products;
  final List<PartnerService> services;
}

class PartnerOrderItem {
  const PartnerOrderItem({
    required this.id,
    required this.nameSnapshot,
    required this.unitPriceCents,
    required this.quantity,
    required this.lineTotalCents,
  });

  factory PartnerOrderItem.fromJson(Map<String, dynamic> json) =>
      PartnerOrderItem(
        id: _string(json['id']),
        nameSnapshot: _string(json['name_snapshot']),
        unitPriceCents: _int(json['unit_price_cents']) ?? 0,
        quantity: _int(json['quantity']) ?? 0,
        lineTotalCents: _int(json['line_total_cents']) ?? 0,
      );

  final String id;
  final String nameSnapshot;
  final int unitPriceCents;
  final int quantity;
  final int lineTotalCents;
}

class PartnerOrder {
  const PartnerOrder({
    required this.id,
    required this.partnerId,
    required this.status,
    required this.totalCents,
    this.items = const [],
    this.notes,
    this.contactPhone,
    this.createdAt,
    this.partnerName,
  });

  factory PartnerOrder.fromJson(Map<String, dynamic> json) => PartnerOrder(
    id: _string(json['id']),
    partnerId: _string(json['partner_id']),
    status: _string(json['status']),
    totalCents: _int(json['total_cents']) ?? 0,
    items: _mapList(json['items']).map(PartnerOrderItem.fromJson).toList(),
    notes: _nullableString(json['notes']),
    contactPhone: _nullableString(json['contact_phone']),
    createdAt: _date(json['created_at']),
    partnerName: _nullableString(_singleMap(json['partners'])?['name']),
  );

  final String id;
  final String partnerId;
  final String status;
  final int totalCents;
  final List<PartnerOrderItem> items;
  final String? notes;
  final String? contactPhone;
  final DateTime? createdAt;
  final String? partnerName;
}

class PartnerReservation {
  const PartnerReservation({
    required this.id,
    required this.partnerId,
    required this.status,
    required this.serviceNameSnapshot,
    required this.priceCentsSnapshot,
    required this.scheduledFor,
    this.petName,
    this.notes,
    this.contactPhone,
    this.partnerName,
  });

  factory PartnerReservation.fromJson(Map<String, dynamic> json) =>
      PartnerReservation(
        id: _string(json['id']),
        partnerId: _string(json['partner_id']),
        status: _string(json['status']),
        serviceNameSnapshot: _string(json['service_name_snapshot']),
        priceCentsSnapshot: _int(json['price_cents_snapshot']) ?? 0,
        scheduledFor: _date(json['scheduled_for']),
        petName: _nullableString(json['pet_name']),
        notes: _nullableString(json['notes']),
        contactPhone: _nullableString(json['contact_phone']),
        partnerName: _nullableString(_singleMap(json['partners'])?['name']),
      );

  final String id;
  final String partnerId;
  final String status;
  final String serviceNameSnapshot;
  final int priceCentsSnapshot;
  final DateTime? scheduledFor;
  final String? petName;
  final String? notes;
  final String? contactPhone;
  final String? partnerName;
}

String _string(Object? value) => value?.toString().trim() ?? '';

String? _nullableString(Object? value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}

int? _int(Object? value) => value is int ? value : int.tryParse('$value');

bool? _bool(Object? value) {
  if (value is bool) return value;
  if (value == 'true') return true;
  if (value == 'false') return false;
  return null;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  return value == null ? null : DateTime.tryParse(value.toString());
}

List<Map<String, dynamic>> _mapList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList()
    : const [];

Map<String, dynamic>? _singleMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  if (value is List && value.isNotEmpty && value.first is Map) {
    return (value.first as Map).cast<String, dynamic>();
  }
  return null;
}
