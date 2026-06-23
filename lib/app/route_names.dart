abstract final class RouteNames {
  static const landing = 'landing';
  static const dogs = 'dogs';
  static const dogDetail = 'dog-detail';
  static const auth = 'auth';
  static const profile = 'profile';
  static const favorites = 'favorites';
  static const applicationForm = 'application-form';
}

abstract final class RoutePaths {
  static const landing = '/';
  static const dogs = '/perros';
  static const dogDetailPattern = '/perros/:slug';
  static const auth = '/auth';
  static const profile = '/perfil';
  static const favorites = '/favoritos';
  static const applicationFormPattern = '/perros/:slug/postular';

  static String dogDetail(String slug) =>
      '/perros/${Uri.encodeComponent(slug)}';

  static String applicationForm(String slug) => '${dogDetail(slug)}/postular';
}
