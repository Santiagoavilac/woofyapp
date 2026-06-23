class DogPhoto {
  const DogPhoto({
    required this.id,
    required this.dogId,
    required this.storagePath,
    this.publicUrl,
    this.isCover = false,
    this.position = 0,
  });

  factory DogPhoto.fromJson(Map<String, dynamic> json) => DogPhoto(
    id: _string(json['id']),
    dogId: _string(json['dog_id']),
    storagePath: _string(json['storage_path']),
    isCover: _bool(json['is_cover']) ?? false,
    position: _int(json['position']) ?? 0,
  );

  final String id;
  final String dogId;
  final String storagePath;
  final String? publicUrl;
  final bool isCover;
  final int position;

  DogPhoto copyWith({String? publicUrl}) => DogPhoto(
    id: id,
    dogId: dogId,
    storagePath: storagePath,
    publicUrl: publicUrl ?? this.publicUrl,
    isCover: isCover,
    position: position,
  );
}

class DogShelter {
  const DogShelter({
    required this.id,
    required this.name,
    this.description,
    this.city,
    this.address,
    this.phone,
    this.instagram,
    this.verified,
    this.status,
    this.email,
    this.facebook,
    this.website,
    this.profileImagePath,
    this.publicContactName,
    this.locationNotes,
  });

  factory DogShelter.fromJson(Map<String, dynamic> json) => DogShelter(
    id: _string(json['id']),
    name: _string(json['name']),
    description: _nullableString(json['description']),
    city: _nullableString(json['city']),
    address: _nullableString(json['address']),
    phone: _nullableString(json['phone']),
    instagram: _nullableString(json['instagram']),
    verified: _bool(json['verified']),
    status: _nullableString(json['status']),
    email: _nullableString(json['email']),
    facebook: _nullableString(json['facebook']),
    website: _nullableString(json['website']),
    profileImagePath: _nullableString(json['profile_image_path']),
    publicContactName: _nullableString(json['public_contact_name']),
    locationNotes: _nullableString(json['location_notes']),
  );

  final String id;
  final String name;
  final String? description;
  final String? city;
  final String? address;
  final String? phone;
  final String? instagram;
  final bool? verified;
  final String? status;
  final String? email;
  final String? facebook;
  final String? website;
  final String? profileImagePath;
  final String? publicContactName;
  final String? locationNotes;
}

class Dog {
  const Dog({
    required this.id,
    required this.shelterId,
    required this.name,
    required this.slug,
    required this.story,
    required this.status,
    this.sex,
    this.ageMonths,
    this.size,
    this.energyLevel,
    this.sterilized,
    this.vaccinated,
    this.medicalNotes,
    this.temperament,
    this.goodWithChildren,
    this.goodWithDogs,
    this.goodWithCats,
    this.createdAt,
    this.deletedAt,
    this.shelter,
    this.photos = const [],
  });

  factory Dog.fromJson(Map<String, dynamic> json) {
    final photos = _mapList(json['dog_photos']).map(DogPhoto.fromJson).toList()
      ..sort(_comparePhotos);
    final shelterJson = _singleMap(json['shelters']);

    return Dog(
      id: _string(json['id']),
      shelterId: _string(json['shelter_id']),
      name: _string(json['name']),
      slug: _string(json['slug']),
      story: _string(json['story']),
      status: _string(json['status']),
      sex: _nullableString(json['sex']),
      ageMonths: _int(json['age_months']),
      size: _nullableString(json['size']),
      energyLevel: _nullableString(json['energy_level']),
      sterilized: _bool(json['sterilized']),
      vaccinated: _bool(json['vaccinated']),
      medicalNotes: _nullableString(json['medical_notes']),
      temperament: _nullableString(json['temperament']),
      goodWithChildren: _bool(json['good_with_children']),
      goodWithDogs: _bool(json['good_with_dogs']),
      goodWithCats: _bool(json['good_with_cats']),
      createdAt: _date(json['created_at']),
      deletedAt: _date(json['deleted_at']),
      shelter: shelterJson == null ? null : DogShelter.fromJson(shelterJson),
      photos: photos,
    );
  }

  final String id;
  final String shelterId;
  final String name;
  final String slug;
  final String story;
  final String status;
  final String? sex;
  final int? ageMonths;
  final String? size;
  final String? energyLevel;
  final bool? sterilized;
  final bool? vaccinated;
  final String? medicalNotes;
  final String? temperament;
  final bool? goodWithChildren;
  final bool? goodWithDogs;
  final bool? goodWithCats;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final DogShelter? shelter;
  final List<DogPhoto> photos;

  DogPhoto? get coverPhoto => photos.isEmpty ? null : photos.first;

  String? get ageLabel {
    final months = ageMonths;
    if (months == null) return null;
    if (months < 12) return '$months ${months == 1 ? 'mes' : 'meses'}';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    final yearsText = '$years ${years == 1 ? 'año' : 'años'}';
    if (remainingMonths == 0) return yearsText;
    return '$yearsText y $remainingMonths '
        '${remainingMonths == 1 ? 'mes' : 'meses'}';
  }

  Dog copyWith({List<DogPhoto>? photos}) => Dog(
    id: id,
    shelterId: shelterId,
    name: name,
    slug: slug,
    story: story,
    status: status,
    sex: sex,
    ageMonths: ageMonths,
    size: size,
    energyLevel: energyLevel,
    sterilized: sterilized,
    vaccinated: vaccinated,
    medicalNotes: medicalNotes,
    temperament: temperament,
    goodWithChildren: goodWithChildren,
    goodWithDogs: goodWithDogs,
    goodWithCats: goodWithCats,
    createdAt: createdAt,
    deletedAt: deletedAt,
    shelter: shelter,
    photos: photos ?? this.photos,
  );
}

class DogMedicalEvent {
  const DogMedicalEvent({
    required this.id,
    required this.dogId,
    required this.title,
    this.eventDate,
    this.eventType,
    this.description,
  });

  factory DogMedicalEvent.fromJson(Map<String, dynamic> json) =>
      DogMedicalEvent(
        id: _string(json['id']),
        dogId: _string(json['dog_id']),
        title: _string(json['title']),
        eventDate: _date(json['event_date']),
        eventType: _nullableString(json['event_type']),
        description: _nullableString(json['description']),
      );

  final String id;
  final String dogId;
  final String title;
  final DateTime? eventDate;
  final String? eventType;
  final String? description;
}

class DogDetail {
  const DogDetail({
    required this.dog,
    this.arrivalDate,
    this.arrivalCondition,
    this.rescueContext,
    this.foundLocation,
    this.breed,
    this.breedNotes,
    this.motherKnown,
    this.motherBreed,
    this.motherNotes,
    this.fatherKnown,
    this.fatherBreed,
    this.fatherNotes,
    this.healthOnArrival,
    this.knownConditions,
    this.currentTreatment,
    this.dewormed,
    this.dewormingDate,
    this.specialCare,
    this.feedingNotes,
    this.behaviorNotes,
    this.idealHome,
    this.extraNotes,
    this.medicalEvents = const [],
  });

  factory DogDetail.fromJson({
    required Dog dog,
    Map<String, dynamic>? detailsJson,
    required List<dynamic> medicalEventsJson,
  }) {
    final json = detailsJson ?? const <String, dynamic>{};
    final events =
        medicalEventsJson
            .whereType<Map>()
            .map(
              (event) =>
                  DogMedicalEvent.fromJson(event.cast<String, dynamic>()),
            )
            .toList()
          ..sort(_compareMedicalEvents);

    return DogDetail(
      dog: dog,
      arrivalDate: _date(json['arrival_date']),
      arrivalCondition: _nullableString(json['arrival_condition']),
      rescueContext: _nullableString(json['rescue_context']),
      foundLocation: _nullableString(json['found_location']),
      breed: _nullableString(json['breed']),
      breedNotes: _nullableString(json['breed_notes']),
      motherKnown: _bool(json['mother_known']),
      motherBreed: _nullableString(json['mother_breed']),
      motherNotes: _nullableString(json['mother_notes']),
      fatherKnown: _bool(json['father_known']),
      fatherBreed: _nullableString(json['father_breed']),
      fatherNotes: _nullableString(json['father_notes']),
      healthOnArrival: _nullableString(json['health_on_arrival']),
      knownConditions: _nullableString(json['known_conditions']),
      currentTreatment: _nullableString(json['current_treatment']),
      dewormed: _bool(json['dewormed']),
      dewormingDate: _date(json['deworming_date']),
      specialCare: _nullableString(json['special_care']),
      feedingNotes: _nullableString(json['feeding_notes']),
      behaviorNotes: _nullableString(json['behavior_notes']),
      idealHome: _nullableString(json['ideal_home']),
      extraNotes: _nullableString(json['extra_notes']),
      medicalEvents: events,
    );
  }

  final Dog dog;
  final DateTime? arrivalDate;
  final String? arrivalCondition;
  final String? rescueContext;
  final String? foundLocation;
  final String? breed;
  final String? breedNotes;
  final bool? motherKnown;
  final String? motherBreed;
  final String? motherNotes;
  final bool? fatherKnown;
  final String? fatherBreed;
  final String? fatherNotes;
  final String? healthOnArrival;
  final String? knownConditions;
  final String? currentTreatment;
  final bool? dewormed;
  final DateTime? dewormingDate;
  final String? specialCare;
  final String? feedingNotes;
  final String? behaviorNotes;
  final String? idealHome;
  final String? extraNotes;
  final List<DogMedicalEvent> medicalEvents;
}

int _comparePhotos(DogPhoto a, DogPhoto b) {
  if (a.isCover != b.isCover) return a.isCover ? -1 : 1;
  return a.position.compareTo(b.position);
}

int _compareMedicalEvents(DogMedicalEvent a, DogMedicalEvent b) {
  if (a.eventDate == null && b.eventDate == null) return 0;
  if (a.eventDate == null) return 1;
  if (b.eventDate == null) return -1;
  return b.eventDate!.compareTo(a.eventDate!);
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
