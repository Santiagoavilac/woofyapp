import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/applications/data/applications_repository.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/data/messages_repository.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('router exposes public routes and protects profile', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    router.go(RoutePaths.dogs);
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos animales publicados todavía.'),
      findsOneWidget,
    );

    router.go(RoutePaths.dogDetail('luna'));
    await tester.pumpAndSettle();
    expect(find.text('Este perrito no está disponible.'), findsOneWidget);

    router.go(RoutePaths.profile);
    await tester.pumpAndSettle();
    expect(find.text('Ingresar a Woofy'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);

    router.go(RoutePaths.favorites);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);

    router.go(RoutePaths.messages);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);

    router.go(RoutePaths.conversation('thread-1'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);

    router.go(RoutePaths.applicationForm('milo-demo'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);
  });

  testWidgets('authenticated users are redirected from auth to profile', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );

    final router = container.read(routerProvider);
    router.go(RoutePaths.auth);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.profile);
    expect(find.text('Tu perfil todavía no está completo.'), findsOneWidget);

    await _androidBack(tester);

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.landing);
    expect(find.text('Hola 👋'), findsOneWidget);
  });

  testWidgets('auth stream refreshes the same router without redirect loops', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);
    router.go(RoutePaths.auth);
    await tester.pumpAndSettle();

    auth.setUser(const AppUser(id: 'user-1', email: 'ana@example.com'));
    await tester.pumpAndSettle();

    expect(identical(router, container.read(routerProvider)), isTrue);
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.profile);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth stream ensures an authenticated profile only once', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final profiles = _EmptyProfileRepository();
    final container = _container(auth, profiles: profiles);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    await tester.pumpAndSettle();
    const user = AppUser(
      id: 'user-1',
      email: 'ana@example.com',
      fullName: 'Ana Pérez',
    );

    auth.setUser(user);
    await tester.pumpAndSettle();
    auth.setUser(user);
    await tester.pumpAndSettle();

    expect(profiles.ensureCalls, 1);
  });

  testWidgets('application form Android back returns to dog detail', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final dog = _sampleDog();
    final container = _container(
      auth,
      dogRepository: _SingleDogRepository(dog),
      applications: _EmptyApplicationsRepository(),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.dogDetail(dog.slug));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Postular a Milo'));
    await tester.tap(find.widgetWithText(FilledButton, 'Postular a Milo'));
    await tester.pumpAndSettle();

    expect(find.text('Postular a Milo'), findsOneWidget);
    expect(
      find.text(
        'Contanos sobre tu hogar para que el refugio pueda evaluar la adopción.',
      ),
      findsOneWidget,
    );

    await _androidBack(tester);

    expect(
      router.routeInformationProvider.value.uri.path,
      RoutePaths.dogDetail(dog.slug),
    );
    expect(find.text('Una historia real.'), findsOneWidget);
  });

  testWidgets('conversation Android back returns to messages', (tester) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final container = _container(
      auth,
      messages: _FakeMessagesRepository.withMessages(),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.conversation('thread-1'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación'), findsOneWidget);
    expect(find.text('Hola refugio'), findsOneWidget);

    await _androidBack(tester);

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.messages);
    expect(find.text('Mensajes'), findsOneWidget);
  });

  testWidgets('messages empty state opens dogs page', (tester) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final container = _container(auth, messages: _FakeMessagesRepository());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.messages);
    await tester.pumpAndSettle();
    expect(find.text('Todavía no tenés conversaciones.'), findsOneWidget);

    await tester.tap(find.text('Ver perritos'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.dogs);
    expect(
      find.text('No encontramos animales publicados todavía.'),
      findsOneWidget,
    );
  });

  testWidgets('catalog messages icon opens messages for authenticated users', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final container = _container(auth, messages: _FakeMessagesRepository());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.dogs);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

    await tester.tap(find.byTooltip('Mis mensajes'));
    await tester.pumpAndSettle();

    expect(find.text('Mensajes'), findsOneWidget);
  });

  testWidgets('detail with application opens direct thread when it exists', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final dog = _sampleDog();
    final container = _container(
      auth,
      dogRepository: _SingleDogRepository(dog),
      applications: _AppliedApplicationsRepository(),
      messages: _FakeMessagesRepository(openThread: _thread()),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.dogDetail(dog.slug));
    await tester.pumpAndSettle();
    // The detail page is a CustomScrollView now, so the scroll triggered by
    // ensureVisible needs a frame before the button can be tapped.
    await tester.ensureVisible(find.text('Escribir al refugio'));
    await tester.pumpAndSettle();

    expect(find.text('Tu postulación'), findsOneWidget);
    expect(find.text('Escribir al refugio'), findsOneWidget);

    await tester.tap(find.text('Escribir al refugio'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación'), findsOneWidget);
  });

  testWidgets(
    'detail with application creates and opens thread without existing thread',
    (tester) async {
      const user = AppUser(id: 'user-1', email: 'ana@example.com');
      final auth = FakeAuthRepository(user: user);
      addTearDown(auth.dispose);
      final dog = _sampleDog();
      final messages = _FakeMessagesRepository(openThread: _thread());
      final container = _container(
        auth,
        dogRepository: _SingleDogRepository(dog),
        applications: _AppliedApplicationsRepository(),
        messages: messages,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const WoofyApp(),
        ),
      );
      final router = container.read(routerProvider);

      router.go(RoutePaths.dogDetail(dog.slug));
      await tester.pumpAndSettle();
      // The detail page is a CustomScrollView now, so the scroll triggered by
      // ensureVisible needs a frame before the button can be tapped.
      await tester.ensureVisible(find.text('Escribir al refugio'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escribir al refugio'));
      await tester.pumpAndSettle();

      expect(messages.openDogIds, ['dog-1']);
      expect(find.text('Conversación'), findsOneWidget);
    },
  );

  testWidgets('a pending password recovery pins the user to the new password '
      'screen', (tester) async {
    final auth = FakeAuthRepository(
      user: const AppUser(id: 'user-1', email: 'ana@example.com'),
    );
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    container.read(passwordRecoveryPendingProvider.notifier).start();
    await tester.pumpAndSettle();

    // Aunque hay sesión válida, el perfil no debe ganarle a la recuperación.
    router.go(RoutePaths.profile);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RoutePaths.newPassword,
    );
    expect(find.text('Elegí tu contraseña nueva'), findsOneWidget);

    container.read(passwordRecoveryPendingProvider.notifier).complete();
    await tester.pumpAndSettle();
    router.go(RoutePaths.profile);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.profile);
  });

  testWidgets('a password recovery event raises the pending flag', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    await tester.pumpAndSettle();

    expect(container.read(passwordRecoveryPendingProvider), isFalse);

    auth.authEventChanges.add(AuthLifecycleEvent.passwordRecovery);
    await tester.pumpAndSettle();

    expect(container.read(passwordRecoveryPendingProvider), isTrue);
  });

  testWidgets('the vets catalog and profiles stay open without a session', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.vets);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.vets);
    expect(find.text('Todavía no hay veterinarias'), findsOneWidget);

    router.go(RoutePaths.partnerDetail('vet-santa-cruz'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RoutePaths.partnerDetail('vet-santa-cruz'),
    );
    expect(find.text('Veterinaria no disponible'), findsOneWidget);
  });

  testWidgets('booking requires a session but the cart does not', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    // El carrito se arma sin cuenta: el login se pide recién al mandar el
    // pedido, que es lo único que escribe una fila con `user_id`.
    router.go(RoutePaths.cart);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.cart);

    // Reservar sí guarda desde el formulario, así que sin sesión no tiene
    // sentido dejar llenarlo.
    router.go(RoutePaths.partnerReservation('vet-santa-cruz'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);
  });

  testWidgets('the order history requires a session', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    // El historial se lee con RLS por `auth.uid()`: sin sesión no hay nada que
    // mostrar, así que la ruta manda al login.
    router.go(RoutePaths.orders);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);
  });

  testWidgets('the cart route wins over the vet slug pattern', (tester) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.cart);
    await tester.pumpAndSettle();

    // `carrito` también encaja en `/veterinarias/:slug`: si el orden de las
    // rutas se invierte, acá saldría "Veterinaria no disponible".
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.cart);
    expect(find.text('Tu carrito está vacío'), findsOneWidget);

    router.go(RoutePaths.partnerReservation('vet-santa-cruz'));
    await tester.pumpAndSettle();
    expect(find.text('Sin servicios disponibles'), findsOneWidget);
  });
}

ProviderContainer _container(
  FakeAuthRepository auth, {
  _EmptyProfileRepository? profiles,
  DogRepository? dogRepository,
  ApplicationsRepository? applications,
  MessagesRepository? messages,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(
        profiles ?? _EmptyProfileRepository(),
      ),
      dogRepositoryProvider.overrideWithValue(
        dogRepository ?? _EmptyDogRepository(),
      ),
      partnerRepositoryProvider.overrideWithValue(
        const _EmptyPartnerRepository(),
      ),
      if (applications != null)
        applicationsRepositoryProvider.overrideWithValue(applications),
      if (messages != null)
        messagesRepositoryProvider.overrideWithValue(messages),
    ],
  );
}

class _EmptyDogRepository implements DogRepository {
  @override
  Future<List<Dog>> fetchPublishedDogs() async => const [];

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async => null;
}

class _EmptyPartnerRepository implements PartnerRepository {
  const _EmptyPartnerRepository();

  @override
  Future<List<Partner>> fetchActivePartners({
    PartnerCategory? category,
  }) async => const [];

  @override
  Future<List<PartnerService>> fetchServices() async => const [];

  @override
  Future<PartnerDetail?> fetchPartnerBySlug(String slug) async => null;

  @override
  Future<PartnerDetail?> fetchOfficialStore() async => null;

  @override
  Future<PartnerOrder> createOrder({
    required String partnerId,
    required List<({String productId, String? variantId, int quantity})> items,
    String? contactPhone,
    String? notes,
  }) => throw UnimplementedError('No se usa en esta prueba.');

  @override
  Future<PartnerReservation> createReservation({
    required String partnerId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  }) => throw UnimplementedError('No se usa en esta prueba.');

  @override
  Future<List<PartnerOrder>> fetchMyOrders() async => const [];

  @override
  Future<List<PartnerReservation>> fetchMyReservations() async => const [];
}

class _EmptyProfileRepository implements ProfileRepository {
  int ensureCalls = 0;

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async {
    ensureCalls += 1;
    return UserProfile(id: user.id, role: 'adopter', email: user.email);
  }

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => null;

  @override
  Future<String?> fetchEmailByFullName(String name) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async => UserProfile(id: userId, role: 'adopter');
}

Dog _sampleDog() => const Dog(
  id: 'dog-1',
  shelterId: 'shelter-1',
  name: 'Milo',
  slug: 'milo-demo',
  story: 'Una historia real.',
  status: 'published',
  sex: 'macho',
  ageMonths: 18,
  size: 'mediano',
  shelter: DogShelter(id: 'shelter-1', name: 'Woofy'),
);

class _SingleDogRepository implements DogRepository {
  const _SingleDogRepository(this.dog);

  final Dog dog;

  @override
  Future<List<Dog>> fetchPublishedDogs() async => [dog];

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async =>
      slug == dog.slug ? DogDetail(dog: dog) : null;
}

class _EmptyApplicationsRepository implements ApplicationsRepository {
  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async =>
      null;

  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) {
    throw UnimplementedError('No se usa en esta prueba.');
  }
}

class _AppliedApplicationsRepository implements ApplicationsRepository {
  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async =>
      AdoptionApplication(
        id: 'application-1',
        dogId: dogId,
        adopterId: 'user-1',
        shelterId: 'shelter-1',
        status: ApplicationStatus.submitted,
        createdAt: DateTime(2026, 6, 23, 10),
      );

  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) {
    throw UnimplementedError('No se usa en esta prueba.');
  }
}

class _FakeMessagesRepository implements MessagesRepository {
  _FakeMessagesRepository({this.messages = const [], this.openThread});

  factory _FakeMessagesRepository.withMessages() => _FakeMessagesRepository(
    messages: [
      Message(
        id: 'message-1',
        threadId: 'thread-1',
        senderId: 'user-1',
        body: 'Hola refugio',
        hiddenByAdmin: false,
        createdAt: DateTime(2026, 6, 23, 10),
      ),
    ],
  );

  final List<Message> messages;
  final ConversationThread? openThread;
  final openDogIds = <String>[];

  @override
  Future<List<ConversationThread>> fetchMyThreads() async => messages.isEmpty
      ? const <ConversationThread>[]
      : [_thread(lastMessagePreview: 'Hola refugio')];

  @override
  Future<ConversationThread> fetchThreadById(String threadId) async =>
      _thread();

  @override
  Future<ConversationThread?> fetchThreadForDog(String dogId) async =>
      dogId == 'dog-1' ? openThread : null;

  @override
  Future<ConversationThread> getOrCreateThreadForDog(String dogId) async {
    openDogIds.add(dogId);
    return openThread ?? _thread();
  }

  @override
  Future<ConversationThread> getOrCreateInquiryThreadForDog(
    String dogId,
  ) async {
    openDogIds.add(dogId);
    return openThread ?? _thread();
  }

  @override
  Future<List<Message>> fetchMessages(String threadId) async => messages;

  @override
  Future<void> sendMessage(String threadId, String body) async {}
}

ConversationThread _thread({String? lastMessagePreview}) => ConversationThread(
  id: 'thread-1',
  dogId: 'dog-1',
  shelterId: 'shelter-1',
  adopterId: 'user-1',
  status: 'open',
  createdAt: DateTime(2026, 6, 23, 10),
  updatedAt: DateTime(2026, 6, 23, 10),
  dogName: 'Milo',
  shelterName: 'Woofy',
  lastMessagePreview: lastMessagePreview,
);

Future<void> _androidBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
