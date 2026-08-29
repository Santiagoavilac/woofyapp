abstract final class RouteNames {
  static const landing = 'landing';
  static const dogs = 'dogs';
  static const dogDetail = 'dog-detail';
  static const auth = 'auth';
  static const profile = 'profile';
  static const favorites = 'favorites';
  static const applicationForm = 'application-form';
  static const messages = 'messages';
  static const conversation = 'conversation';
  static const publisher = 'publisher';
  static const publisherNewDog = 'publisher-new-dog';
  static const publisherEditDog = 'publisher-edit-dog';
  static const shelterLogin = 'shelter-login';
  static const shelterEditProfile = 'shelter-edit-profile';
  static const adopterEditProfile = 'adopter-edit-profile';
  static const deleteAccount = 'delete-account';
  static const forgotPassword = 'forgot-password';
  static const newPassword = 'new-password';
  static const blockedAccounts = 'blocked-accounts';
  static const vets = 'vets';
  static const vetDetail = 'vet-detail';
  static const vetCart = 'vet-cart';
  static const vetProduct = 'vet-product';
  static const vetReservation = 'vet-reservation';
}

abstract final class RoutePaths {
  static const landing = '/';
  static const dogs = '/perros';
  static const dogDetailPattern = '/perros/:slug';
  static const auth = '/auth';
  static const profile = '/perfil';
  static const favorites = '/favoritos';
  static const applicationFormPattern = '/perros/:slug/postular';
  static const messages = '/mensajes';
  static const conversationPattern = '/mensajes/:threadId';
  static const publisher = '/publicador';
  static const publisherNewDog = '/publicador/nuevo';
  static const publisherEditDogPattern = '/publicador/:dogId/editar';
  static const shelterLogin = '/acceso-refugio';
  static const shelterEditProfile = '/perfil/refugio/editar';
  static const adopterEditProfile = '/perfil/adoptante/editar';
  static const deleteAccount = '/perfil/eliminar-cuenta';
  // Sin acentos ni ñ: estas rutas viajan en deep links y logs.
  static const forgotPassword = '/auth/recuperar';
  static const newPassword = '/auth/nueva-contrasena';
  static const blockedAccounts = '/perfil/bloqueados';

  static const vets = '/veterinarias';
  // Va declarada antes que `vetDetailPattern` en el router: `carrito` también
  // encajaría en `:slug` y go_router se queda con la primera coincidencia.
  static const vetCart = '/veterinarias/carrito';
  static const vetDetailPattern = '/veterinarias/:slug';
  static const vetReservationPattern = '/veterinarias/:slug/reservar';
  static const vetProductPattern = '/veterinarias/:slug/producto/:productId';

  static String vetDetail(String slug) =>
      '/veterinarias/${Uri.encodeComponent(slug)}';

  static String vetReservation(String slug) => '${vetDetail(slug)}/reservar';

  static String vetProduct(String slug, String productId) =>
      '${vetDetail(slug)}/producto/${Uri.encodeComponent(productId)}';

  static String dogDetail(String slug) =>
      '/perros/${Uri.encodeComponent(slug)}';

  static String applicationForm(String slug) => '${dogDetail(slug)}/postular';

  static String conversation(String threadId) =>
      '/mensajes/${Uri.encodeComponent(threadId)}';

  static String publisherEditDog(String dogId) =>
      '/publicador/${Uri.encodeComponent(dogId)}/editar';
}
