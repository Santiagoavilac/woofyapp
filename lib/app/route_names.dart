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
  static const services = 'services';
  static const partnerDetail = 'partner-detail';
  static const cart = 'cart';
  static const partnerProduct = 'partner-product';
  static const partnerReservation = 'partner-reservation';
  static const store = 'store';
  static const storeProduct = 'store-product';
  static const orders = 'orders';
  static const search = 'search';
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
  static const orders = '/perfil/pedidos';

  // Veterinarias y Servicios son dos vistas del mismo padrón de aliados: la
  // primera lista negocios del rubro `vet`, la segunda lista servicios sueltos
  // de todos los rubros. El perfil es uno solo y por eso vive en `/aliados`:
  // un paseador de perros abriéndose bajo `/veterinarias/` sería mentira.
  static const vets = '/veterinarias';
  static const services = '/servicios';
  static const cart = '/carrito';
  static const partnerDetailPattern = '/aliados/:slug';
  static const partnerReservationPattern = '/aliados/:slug/reservar';
  static const partnerProductPattern = '/aliados/:slug/producto/:productId';
  static const search = '/buscar';
  static const store = '/tienda';
  static const storeProductPattern = '/tienda/producto/:productId';

  static String partnerDetail(String slug) =>
      '/aliados/${Uri.encodeComponent(slug)}';

  static String partnerReservation(String slug) =>
      '${partnerDetail(slug)}/reservar';

  static String partnerProduct(String slug, String productId) =>
      '${partnerDetail(slug)}/producto/${Uri.encodeComponent(productId)}';

  static String storeProduct(String productId) =>
      '/tienda/producto/${Uri.encodeComponent(productId)}';

  static String dogDetail(String slug) =>
      '/perros/${Uri.encodeComponent(slug)}';

  static String applicationForm(String slug) => '${dogDetail(slug)}/postular';

  static String conversation(String threadId) =>
      '/mensajes/${Uri.encodeComponent(threadId)}';

  static String publisherEditDog(String dogId) =>
      '/publicador/${Uri.encodeComponent(dogId)}/editar';
}
