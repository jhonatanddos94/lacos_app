/// Caminhos centralizados de assets do Laços.
///
/// Toda referência a imagens, ícones, animações e fontes deve
/// utilizar estas constantes em vez de strings literais.
abstract final class AppAssets {
  // ── Branding ─────────────────────────────────────────────────────────────

  /// Laço oficial da marca — PNG transparente, recorte limpo.
  static const String lacosLogo = 'assets/images/branding/lacos_logo.png';

  /// Ícone da marca para a Splash (canvas legado — preferir [lacosLogo]).
  static const String logoSplash = 'assets/images/branding/logo_splash.png';

  /// Arte oficial da marca — laço, wordmark e tagline.
  static const String logoBrand = 'assets/images/branding/logo_brand.png';

  // ── Icons ────────────────────────────────────────────────────────────────

  static const String whatsappIcon = 'assets/icons/whatsapp.png';
  static const String instagramIcon = 'assets/icons/instagram.png';
}
