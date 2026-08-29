import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/services/secure_storage_service.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/features/publisher/data/publisher_repository.dart';

const _kSecureChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);
const _kSessionKey = 'woofy_shelter_portal_session';

const _storedSession = ShelterPortalSession(
  sessionId: 'session-1',
  token: 'token-abc',
  expiresAt: '2099-01-01T00:00:00Z',
  shelterId: 'shelter-1',
  shelterName: 'Refugio guardado',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, String?> storage = {};
  bool deleteCalled = false;

  setUp(() {
    storage = {};
    deleteCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kSecureChannel, (call) async {
          final args = call.arguments;
          final key = args is Map ? args['key']?.toString() : null;
          switch (call.method) {
            case 'read':
              return storage[key];
            case 'readAll':
              return storage;
            case 'write':
              final value = args is Map ? args['value']?.toString() : null;
              if (key != null) storage[key] = value;
              return null;
            case 'delete':
              if (key != null) {
                deleteCalled = deleteCalled || key == _kSessionKey;
                storage.remove(key);
              }
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
            case 'containsKey':
              return storage.containsKey(key);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kSecureChannel, null);
  });

  test('devuelve null cuando no hay sesión guardada', () async {
    final container = ProviderContainer(
      overrides: [
        shelterPortalRepositoryProvider.overrideWithValue(_FakeRepo.ok()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(shelterPortalSessionProvider.future);

    expect(result, isNull);
  });

  test(
    'sesión guardada se devuelve inmediatamente aunque el refresh sea lento',
    () async {
      storage[_kSessionKey] = jsonEncode(_storedSession.toJson());
      final repo = _FakeRepo.ok(
        refreshDelay: const Duration(milliseconds: 200),
      );

      final container = ProviderContainer(
        overrides: [shelterPortalRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final immediate = await container.read(
        shelterPortalSessionProvider.future,
      );

      expect(immediate?.sessionId, 'session-1');
      expect(immediate?.shelterName, 'Refugio guardado');
      expect(deleteCalled, isFalse);
    },
  );

  test('error transitorio en refresh NO borra la sesión local', () async {
    storage[_kSessionKey] = jsonEncode(_storedSession.toJson());
    final repo = _FakeRepo.throwsOnRefresh(
      const AppException(code: 'network_error', message: 'sin red'),
    );

    final container = ProviderContainer(
      overrides: [shelterPortalRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(shelterPortalSessionProvider.future);
    // Espera a que el refresh en background corra.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(storage[_kSessionKey], isNotNull);
    expect(deleteCalled, isFalse);
    final finalState = container.read(shelterPortalSessionProvider).value;
    expect(finalState?.sessionId, 'session-1');
  });

  test(
    'respuesta "shelter_session_invalid" SÍ borra la sesión local',
    () async {
      storage[_kSessionKey] = jsonEncode(_storedSession.toJson());
      final repo = _FakeRepo.throwsOnRefresh(
        const AppException(
          code: 'shelter_session_invalid',
          message: 'expirada',
        ),
      );

      final container = ProviderContainer(
        overrides: [shelterPortalRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(shelterPortalSessionProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(deleteCalled, isTrue);
      expect(storage[_kSessionKey], isNull);
      expect(container.read(shelterPortalSessionProvider).value, isNull);
    },
  );

  test('the session survives through the injected storage service', () async {
    // El refactor a secureStorageServiceProvider existe para esto: probar el
    // ciclo de vida de la sesión sin mockear el canal nativo del plugin.
    final fakeStorage = _FakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(fakeStorage),
        shelterPortalRepositoryProvider.overrideWithValue(
          _FakeRepo.logsIn(_storedSession),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(shelterPortalSessionProvider.future);
    await container
        .read(shelterPortalSessionProvider.notifier)
        .login('refugio-1', 'clave');

    expect(fakeStorage.values[_kSessionKey], isNotNull);
    expect(
      jsonDecode(fakeStorage.values[_kSessionKey]!)['session_id'],
      'session-1',
    );

    await container.read(shelterPortalSessionProvider.notifier).logout();
    expect(fakeStorage.values.containsKey(_kSessionKey), isFalse);
  });
}

class _FakeRepo implements ShelterPortalRepository {
  _FakeRepo._({
    this.refreshDelay = Duration.zero,
    this.refreshError,
    this.loginSession,
  });

  factory _FakeRepo.ok({Duration refreshDelay = Duration.zero}) =>
      _FakeRepo._(refreshDelay: refreshDelay);

  factory _FakeRepo.logsIn(ShelterPortalSession session) =>
      _FakeRepo._(loginSession: session);

  factory _FakeRepo.throwsOnRefresh(Object error) =>
      _FakeRepo._(refreshError: error);

  final Duration refreshDelay;
  final Object? refreshError;
  final ShelterPortalSession? loginSession;

  @override
  Future<ShelterPortalSession> login(String loginCode, String password) async =>
      loginSession ?? (throw UnimplementedError());

  @override
  Future<void> logout(ShelterPortalSession session) async {}

  @override
  Future<ShelterPortalSession> refreshSession(
    ShelterPortalSession session,
  ) async {
    if (refreshDelay > Duration.zero) await Future<void>.delayed(refreshDelay);
    if (refreshError != null) throw refreshError!;
    return session;
  }

  @override
  Future<List<DogDetail>> fetchDogs(ShelterPortalSession session) async =>
      const [];

  @override
  Future<String> saveDog(
    ShelterPortalSession session,
    DogFormData formData, {
    String? dogId,
  }) async => 'x';

  @override
  Future<void> updateDogStatus(
    ShelterPortalSession session,
    String dogId,
    String status,
  ) async {}

  @override
  Future<String> uploadDogPhoto(
    ShelterPortalSession session,
    String dogId,
    String filePath,
    String mimeType,
  ) async => 'x';

  @override
  Future<ShelterPortalSession> updateShelter(
    ShelterPortalSession session,
    ShelterProfileFormData data,
  ) async => session;

  @override
  Future<String> uploadShelterProfileImage(
    ShelterPortalSession session,
    String filePath,
    String mimeType,
  ) async => 'x';

  @override
  Future<ShelterPortalSession> updateShelterProfileImage(
    ShelterPortalSession session,
    String storagePath,
  ) async => session;
}

class _FakeSecureStorage implements SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    values.clear();
  }
}
