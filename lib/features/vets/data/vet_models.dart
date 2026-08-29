/// Modelos de la vertical de veterinarias.
///
/// El dinero viaja y se guarda siempre como enteros de centavos. Nunca se pasa
/// a `double` para operar: sumar precios en flotante termina en totales que no
/// cierran contra los del panel web.
library;

class Vet {
  const Vet({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.city,
    this.address,
    this.locationNotes,
    this.lat,
    this.lng,
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
  });

  factory Vet.fromJson(Map<String, dynamic> json) => Vet(
    id: _string(json['id']),
    name: _string(json['name']),
    slug: _string(json['slug']),
    description: _nullableString(json['description']),
    city: _nullableString(json['city']),
    address: _nullableString(json['address']),
    locationNotes: _nullableString(json['location_notes']),
    lat: _double(json['lat']),
    lng: _double(json['lng']),
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
  );

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? city;
  final String? address;
  final String? locationNotes;
  final double? lat;
  final double? lng;
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

  /// Hay coordenadas utilizables para abrir el mapa.
  bool get hasLocation => lat != null && lng != null;

  Vet copyWith({String? profileImageUrl, String? coverImageUrl}) => Vet(
    id: id,
    name: name,
    slug: slug,
    description: description,
    city: city,
    address: address,
    locationNotes: locationNotes,
    lat: lat,
    lng: lng,
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
  );
}

class VetProduct {
  const VetProduct({
    required this.id,
    required this.vetId,
    required this.name,
    required this.priceCents,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.stock,
    this.position = 0,
  });

  factory VetProduct.fromJson(Map<String, dynamic> json) => VetProduct(
    id: _string(json['id']),
    vetId: _string(json['vet_id']),
    name: _string(json['name']),
    priceCents: _int(json['price_cents']) ?? 0,
    description: _nullableString(json['description']),
    imagePath: _nullableString(json['image_path']),
    stock: _int(json['stock']),
    position: _int(json['position']) ?? 0,
  );

  final String id;
  final String vetId;
  final String name;
  final int priceCents;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final int? stock;
  final int position;

  /// `stock` nulo significa "sin control de stock", no "sin unidades".
  bool get isAvailable => stock == null || stock! > 0;

  VetProduct copyWith({String? imageUrl}) => VetProduct(
    id: id,
    vetId: vetId,
    name: name,
    priceCents: priceCents,
    description: description,
    imagePath: imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    stock: stock,
    position: position,
  );
}

class VetService {
  const VetService({
    required this.id,
    required this.vetId,
    required this.name,
    required this.priceCents,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.position = 0,
  });

  factory VetService.fromJson(Map<String, dynamic> json) => VetService(
    id: _string(json['id']),
    vetId: _string(json['vet_id']),
    name: _string(json['name']),
    priceCents: _int(json['price_cents']) ?? 0,
    description: _nullableString(json['description']),
    imagePath: _nullableString(json['image_path']),
    position: _int(json['position']) ?? 0,
  );

  final String id;
  final String vetId;
  final String name;
  final int priceCents;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final int position;

  VetService copyWith({String? imageUrl}) => VetService(
    id: id,
    vetId: vetId,
    name: name,
    priceCents: priceCents,
    description: description,
    imagePath: imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    position: position,
  );
}

/// Veterinaria con su catálogo, tal como la muestra el detalle.
class VetDetail {
  const VetDetail({
    required this.vet,
    this.products = const [],
    this.services = const [],
  });

  final Vet vet;
  final List<VetProduct> products;
  final List<VetService> services;
}

class VetOrderItem {
  const VetOrderItem({
    required this.id,
    required this.nameSnapshot,
    required this.unitPriceCents,
    required this.quantity,
    required this.lineTotalCents,
  });

  factory VetOrderItem.fromJson(Map<String, dynamic> json) => VetOrderItem(
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

class VetOrder {
  const VetOrder({
    required this.id,
    required this.vetId,
    required this.status,
    required this.totalCents,
    this.items = const [],
    this.notes,
    this.contactPhone,
    this.createdAt,
    this.vetName,
  });

  factory VetOrder.fromJson(Map<String, dynamic> json) => VetOrder(
    id: _string(json['id']),
    vetId: _string(json['vet_id']),
    status: _string(json['status']),
    totalCents: _int(json['total_cents']) ?? 0,
    items: _mapList(json['items']).map(VetOrderItem.fromJson).toList(),
    notes: _nullableString(json['notes']),
    contactPhone: _nullableString(json['contact_phone']),
    createdAt: _date(json['created_at']),
    vetName: _nullableString(_singleMap(json['vets'])?['name']),
  );

  final String id;
  final String vetId;
  final String status;
  final int totalCents;
  final List<VetOrderItem> items;
  final String? notes;
  final String? contactPhone;
  final DateTime? createdAt;
  final String? vetName;
}

class VetReservation {
  const VetReservation({
    required this.id,
    required this.vetId,
    required this.status,
    required this.serviceNameSnapshot,
    required this.priceCentsSnapshot,
    required this.scheduledFor,
    this.petName,
    this.notes,
    this.contactPhone,
    this.vetName,
  });

  factory VetReservation.fromJson(Map<String, dynamic> json) => VetReservation(
    id: _string(json['id']),
    vetId: _string(json['vet_id']),
    status: _string(json['status']),
    serviceNameSnapshot: _string(json['service_name_snapshot']),
    priceCentsSnapshot: _int(json['price_cents_snapshot']) ?? 0,
    scheduledFor: _date(json['scheduled_for']),
    petName: _nullableString(json['pet_name']),
    notes: _nullableString(json['notes']),
    contactPhone: _nullableString(json['contact_phone']),
    vetName: _nullableString(_singleMap(json['vets'])?['name']),
  );

  final String id;
  final String vetId;
  final String status;
  final String serviceNameSnapshot;
  final int priceCentsSnapshot;
  final DateTime? scheduledFor;
  final String? petName;
  final String? notes;
  final String? contactPhone;
  final String? vetName;
}

String _string(Object? value) => value?.toString().trim() ?? '';

String? _nullableString(Object? value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}

int? _int(Object? value) => value is int ? value : int.tryParse('$value');

double? _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

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
