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

  static String dogDetail(String slug) =>
      '/perros/${Uri.encodeComponent(slug)}';

  static String applicationForm(String slug) => '${dogDetail(slug)}/postular';

  static String conversation(String threadId) =>
      '/mensajes/${Uri.encodeComponent(threadId)}';

  static String publisherEditDog(String dogId) =>
      '/publicador/${Uri.encodeComponent(dogId)}/editar';
}
