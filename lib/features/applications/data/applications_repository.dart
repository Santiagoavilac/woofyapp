import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ApplicationsRepository {
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId);

  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  );
}

abstract interface class ApplicationsDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>?> fetchApplicationForDog(
    String adopterId,
    String dogId,
  );

  Future<Map<String, dynamic>> insertApplication(Map<String, dynamic> values);
}

class SupabaseApplicationsDataSource implements ApplicationsDataSource {
  SupabaseApplicationsDataSource(this._client);

  static const _applicationFields =
      'id, dog_id, adopter_id, shelter_id, status, created_at';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchApplicationForDog(
    String adopterId,
    String dogId,
  ) => _client
      .from('applications')
      .select(_applicationFields)
      .eq('adopter_id', adopterId)
      .eq('dog_id', dogId)
      .maybeSingle();

  @override
  Future<Map<String, dynamic>> insertApplication(Map<String, dynamic> values) =>
      _client
          .from('applications')
          .insert(values)
          .select(_applicationFields)
          .single();
}

class SupabaseApplicationsRepository implements ApplicationsRepository {
  SupabaseApplicationsRepository(SupabaseClient client)
    : _source = SupabaseApplicationsDataSource(client);

  SupabaseApplicationsRepository.withDataSource(ApplicationsDataSource source)
    : _source = source;

  final ApplicationsDataSource _source;

  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) async {
    final userId = _requireUserId();
    try {
      final row = await _source.insertApplication({
        'dog_id': dog.id,
        'adopter_id': userId,
        'shelter_id': dog.shelterId,
        'status': ApplicationStatus.submitted.value,
        ...formData.toJson(),
      });
      return AdoptionApplication.fromJson(row);
    } on PostgrestException catch (error, stackTrace) {
      if (error.code == '23505') {
        throw AppException(
          code: 'duplicate_application',
          message: 'Ya postulaste a este perrito.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (error.code == '42501') {
        throw AppException(
          code: 'dog_unavailable',
          message: 'Este perrito ya no está disponible para postular.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw _submissionError(error, stackTrace);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw _submissionError(error, stackTrace);
    }
  }

  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async {
    final userId = _requireUserId();
    try {
      final row = await _source.fetchApplicationForDog(userId, dogId);
      return row == null ? null : AdoptionApplication.fromJson(row);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'application_load',
        message: 'No pudimos revisar tu postulación.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _requireUserId() {
    final userId = _source.currentUserId;
    if (userId == null) {
      throw const AppException(
        code: 'auth_required',
        message: 'Necesitás iniciar sesión para continuar.',
      );
    }
    return userId;
  }

  AppException _submissionError(Object error, StackTrace stackTrace) =>
      AppException(
        code: 'application_submit',
        message: 'No pudimos enviar tu postulación.',
        cause: error,
        stackTrace: stackTrace,
      );
}
