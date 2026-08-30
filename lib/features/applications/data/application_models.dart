enum ApplicationStatus {
  submitted('submitted', 'Enviada'),
  reviewing('reviewing', 'En revisión'),
  interview('interview', 'Entrevista'),
  approved('approved', 'Aprobada'),
  rejected('rejected', 'Rechazada'),
  withdrawn('withdrawn', 'Retirada'),
  completed('completed', 'Completada');

  const ApplicationStatus(this.value, this.label);

  final String value;
  final String label;

  static ApplicationStatus parse(Object? value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => submitted,
  );
}

enum HousingType {
  houseWithYard('casa_con_patio', 'Casa con patio'),
  houseWithoutYard('casa_sin_patio', 'Casa sin patio'),
  apartment('departamento', 'Departamento');

  const HousingType(this.value, this.label);

  final String value;
  final String label;
}

class AdoptionApplication {
  const AdoptionApplication({
    required this.id,
    required this.dogId,
    required this.adopterId,
    required this.shelterId,
    required this.status,
    required this.createdAt,
    DateTime? updatedAt,
    this.dogName,
    this.dogSlug,
    // Cuándo cambió por última vez: es lo que decide si una postulación cuenta
    // como novedad. Si la fila vino sin el campo, la creación es el último
    // cambio conocido.
  }) : updatedAt = updatedAt ?? createdAt;

  factory AdoptionApplication.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updated_at'];
    final dog = _embeddedDog(json['dogs']);
    return AdoptionApplication(
      id: json['id'] as String,
      dogId: json['dog_id'] as String,
      adopterId: json['adopter_id'] as String,
      shelterId: json['shelter_id'] as String,
      status: ApplicationStatus.parse(json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : null,
      dogName: dog?['name'] as String?,
      dogSlug: dog?['slug'] as String?,
    );
  }

  /// El perro embebido llega como mapa o como lista de uno según cómo
  /// PostgREST resuelva la relación.
  static Map<String, dynamic>? _embeddedDog(Object? value) => switch (value) {
    Map<String, dynamic>() => value,
    Map() => value.cast<String, dynamic>(),
    List() when value.isNotEmpty && value.first is Map =>
      (value.first as Map).cast<String, dynamic>(),
    _ => null,
  };

  final String id;
  final String dogId;
  final String adopterId;
  final String shelterId;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String? dogName;
  final String? dogSlug;
  final DateTime updatedAt;
}

class ApplicationFormData {
  const ApplicationFormData({
    required this.phone,
    required this.city,
    required this.housingType,
    required this.hasChildren,
    required this.hasPets,
    required this.experience,
    required this.motivation,
  });

  final String phone;
  final String city;
  final HousingType housingType;
  final bool hasChildren;
  final bool hasPets;
  final String experience;
  final String motivation;

  Map<String, dynamic> toJson() => {
    'phone': phone.trim(),
    'city': city.trim(),
    'housing_type': housingType.value,
    'has_children': hasChildren,
    'has_pets': hasPets,
    'experience': experience.trim(),
    'motivation': motivation.trim(),
  };
}
