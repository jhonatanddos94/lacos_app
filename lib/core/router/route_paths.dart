/// Caminhos oficiais de navegação do Laços.
abstract final class RoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const welcome = '/welcome';
  static const createSalon = '/create-salon';
  static const completeProfile = '/complete-profile';
  static const home = '/home';
  static const clientDetails = '/clients/:clientId';
  static const clientMemories = '/client-memories';

  static String clientDetailsPath(String clientId) => '/clients/$clientId';
}
