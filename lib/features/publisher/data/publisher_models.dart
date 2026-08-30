import 'package:woofy/features/dogs/data/dog_models.dart';

class ShelterPortalSession {
  const ShelterPortalSession({
    required this.sessionId,
    required this.token,
    required this.expiresAt,
    required this.shelterId,
    required this.shelterName,
    this.shelterCity,
    this.profileImagePath,
    this.description,
    this.phone,
    this.email,
    this.instagram,
    this.facebook,
    this.website,
    this.publicContactName,
    this.locationNotes,
    this.address,
  });

  factory ShelterPortalSession.fromJson(Map<String, dynamic> json) {
    final shelter = json['shelter'] as Map<String, dynamic>? ?? {};
    return ShelterPortalSession(
      sessionId: json['session_id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      shelterId: shelter['id'] as String? ?? '',
      shelterName: shelter['name'] as String? ?? 'Tu refugio',
      shelterCity: shelter['city'] as String?,
      profileImagePath: shelter['profile_image_path'] as String?,
      description: shelter['description'] as String?,
      phone: shelter['phone'] as String?,
      email: shelter['email'] as String?,
      instagram: shelter['instagram'] as String?,
      facebook: shelter['facebook'] as String?,
      website: shelter['website'] as String?,
      publicContactName: shelter['public_contact_name'] as String?,
      locationNotes: shelter['location_notes'] as String?,
      address: shelter['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'token': token,
    'expires_at': expiresAt,
    'shelter': {
      'id': shelterId,
      'name': shelterName,
      'city': shelterCity,
      'profile_image_path': profileImagePath,
      'description': description,
      'phone': phone,
      'email': email,
      'instagram': instagram,
      'facebook': facebook,
      'website': website,
      'public_contact_name': publicContactName,
      'location_notes': locationNotes,
      'address': address,
    },
  };

  ShelterPortalSession copyWith({
    String? shelterName,
    String? shelterCity,
    String? profileImagePath,
    String? description,
    String? phone,
    String? email,
    String? instagram,
    String? facebook,
    String? website,
    String? publicContactName,
    String? locationNotes,
    String? address,
  }) => ShelterPortalSession(
    sessionId: sessionId,
    token: token,
    expiresAt: expiresAt,
    shelterId: shelterId,
    shelterName: shelterName ?? this.shelterName,
    shelterCity: shelterCity ?? this.shelterCity,
    profileImagePath: profileImagePath ?? this.profileImagePath,
    description: description ?? this.description,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    instagram: instagram ?? this.instagram,
    facebook: facebook ?? this.facebook,
    website: website ?? this.website,
    publicContactName: publicContactName ?? this.publicContactName,
    locationNotes: locationNotes ?? this.locationNotes,
    address: address ?? this.address,
  );

  final String sessionId;
  final String token;
  final String expiresAt;
  final String shelterId;
  final String shelterName;
  final String? shelterCity;
  final String? profileImagePath;
  final String? description;
  final String? phone;
  final String? email;
  final String? instagram;
  final String? facebook;
  final String? website;
  final String? publicContactName;
  final String? locationNotes;
  final String? address;
}

class ShelterProfileFormData {
  const ShelterProfileFormData({
    this.description,
    this.phone,
    this.email,
    this.instagram,
    this.facebook,
    this.website,
    this.publicContactName,
    this.locationNotes,
    this.address,
  });

  final String? description;
  final String? phone;
  final String? email;
  final String? instagram;
  final String? facebook;
  final String? website;
  final String? publicContactName;
  final String? locationNotes;
  final String? address;

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    void put(String key, String? value) {
      if (value != null) result[key] = value.trim();
    }

    put('description', description);
    put('phone', phone);
    put('email', email);
    put('instagram', instagram);
    put('facebook', facebook);
    put('website', website);
    put('public_contact_name', publicContactName);
    put('location_notes', locationNotes);
    put('address', address);
    return result;
  }
}

class ShelterMembership {
  const ShelterMembership({
    required this.id,
    required this.shelterId,
    required this.shelterName,
    required this.role,
  });

  factory ShelterMembership.fromJson(Map<String, dynamic> json) {
    final shelterJson = json['shelters'];
    final name = shelterJson is Map
        ? shelterJson['name']?.toString().trim() ?? ''
        : '';
    return ShelterMembership(
      id: json['id']?.toString() ?? '',
      shelterId: json['shelter_id']?.toString() ?? '',
      shelterName: name,
      role: json['role']?.toString() ?? 'editor',
    );
  }

  final String id;
  final String shelterId;
  final String shelterName;
  final String role;
}

class MedicalEventFormData {
  const MedicalEventFormData({
    required this.title,
    this.eventType,
    this.eventDate,
    this.description,
  });

  final String title;
  final String? eventType;
  final DateTime? eventDate;
  final String? description;

  MedicalEventFormData copyWith({
    String? title,
    String? eventType,
    DateTime? eventDate,
    String? description,
  }) => MedicalEventFormData(
    title: title ?? this.title,
    eventType: eventType ?? this.eventType,
    eventDate: eventDate ?? this.eventDate,
    description: description ?? this.description,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    if (eventType != null && eventType!.isNotEmpty) 'event_type': eventType,
    if (eventDate != null)
      'event_date': eventDate!.toIso8601String().split('T').first,
    if (description != null && description!.isNotEmpty)
      'description': description,
  };
}

class DogFormData {
  const DogFormData({
    required this.name,
    required this.slug,
    required this.story,
    required this.status,
    this.species = AnimalSpecies.perro,
    this.sex,
    this.ageMonths,
    this.size,
    this.energyLevel,
    this.temperament,
    this.medicalNotes,
    this.sterilized = false,
    this.vaccinated = false,
    this.goodWithChildren,
    this.goodWithDogs,
    this.goodWithCats,
    this.breed,
    this.idealHome,
    this.specialCare,
    this.feedingNotes,
    this.behaviorNotes,
    this.currentTreatment,
    this.knownConditions,
    this.extraNotes,
    this.medicalEvents = const [],
  });

  final String name;
  final String slug;
  final String story;
  final String status;
  final AnimalSpecies species;
  final String? sex;
  final int? ageMonths;
  final String? size;

  // dogs table extras
  final String? energyLevel;
  final String? temperament;
  final String? medicalNotes;
  final bool sterilized;
  final bool vaccinated;
  final bool? goodWithChildren;
  final bool? goodWithDogs;
  final bool? goodWithCats;

  // dog_details
  final String? breed;
  final String? idealHome;
  final String? specialCare;
  final String? feedingNotes;
  final String? behaviorNotes;
  final String? currentTreatment;
  final String? knownConditions;
  final String? extraNotes;

  // dog_medical_events
  final List<MedicalEventFormData> medicalEvents;

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'story': story,
    'status': status,
    'species': species.value,
    if (sex != null) 'sex': sex,
    if (ageMonths != null) 'age_months': ageMonths,
    if (size != null) 'size': size,
  };

  Map<String, dynamic> toPortalJson() {
    final details = <String, dynamic>{
      if (_hasText(breed)) 'breed': breed,
      if (_hasText(idealHome)) 'ideal_home': idealHome,
      if (_hasText(specialCare)) 'special_care': specialCare,
      if (_hasText(feedingNotes)) 'feeding_notes': feedingNotes,
      if (_hasText(behaviorNotes)) 'behavior_notes': behaviorNotes,
      if (_hasText(currentTreatment)) 'current_treatment': currentTreatment,
      if (_hasText(knownConditions)) 'known_conditions': knownConditions,
      if (_hasText(extraNotes)) 'extra_notes': extraNotes,
    };
    return {
      'name': name,
      'slug': slug,
      'story': story,
      'status': status,
      'species': species.value,
      'sex': sex ?? '',
      'age_months': ageMonths,
      'size': size ?? 'mediano',
      'energy_level': energyLevel ?? 'media',
      'sterilized': sterilized,
      'vaccinated': vaccinated,
      'medical_notes': medicalNotes ?? '',
      'temperament': temperament ?? '',
      'good_with_children': goodWithChildren,
      'good_with_dogs': goodWithDogs,
      'good_with_cats': goodWithCats,
      'details': details,
      'medical_events': medicalEvents
          .where((e) => e.title.trim().isNotEmpty)
          .map((e) => e.toJson())
          .toList(),
    };
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
