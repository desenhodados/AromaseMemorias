abstract final class AppInfo {
  static const name = 'Aromas & Memórias';
  static const tagline = 'As suas receitas, em três modos de cozinhar';
  static const logoAsset = 'assets/branding/logo.png';

  /// Altere para o endereço de e-mail que vai receber o feedback.
  static const feedbackEmail = 'feedback@exemplo.pt';

  /// Na web os sites bloqueiam pedidos diretos (CORS), por isso a importação
  /// por link passa por um proxy público. Pode ser trocado por um proxy próprio.
  static const webProxyPrefixes = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?url=',
    'https://api.codetabs.com/v1/proxy?quest=',
  ];
}
