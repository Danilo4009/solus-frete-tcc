/// Configuracao do prototipo.
class Config {
  /// false = roda com dados simulados em memoria (nao precisa de backend).
  /// true  = consome a API Express/MySQL em [baseUrl].
  /// Sem editar o arquivo: flutter run --dart-define=USAR_API=false
  static const bool usarApi = bool.fromEnvironment('USAR_API', defaultValue: true);

  /// Android emulador: http://10.0.2.2:3333
  /// iOS simulador / desktop / web: http://localhost:3333
  /// Celular fisico na mesma rede: http://SEU_IP_LOCAL:3333
  /// Sobrescreva sem editar o arquivo: flutter run --dart-define=API_URL=http://localhost:3333
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3333');

  static const String cidadePadrao = 'Sao Paulo';

  /// Enquanto o Google Maps nao estiver configurado, o app desenha
  /// um mapa esquematico proprio. Troque para true depois de colocar
  /// a chave de API e adicionar google_maps_flutter ao pubspec.
  static const bool usarMapaReal = false;
}
