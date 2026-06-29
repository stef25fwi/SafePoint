// ---------------------------------------------------------------------------
// ApiClient — placeholder pour le backend NestJS + PostgreSQL + Keycloak V2
//
// En V2, ce client sera configuré avec :
//   - baseUrl : URL de l'API REST sur Cloud Temple OpenShift
//   - authToken : JWT Bearer obtenu depuis Keycloak (OpenID Connect)
//   - organizationId : injecté dans chaque requête
//
// Pattern d'intégration V2 :
//   ApiClient(baseUrl: env.apiUrl, token: keycloakToken)
//
// Les implémentations ApiXxxRepository utilisent ce client.
// ---------------------------------------------------------------------------

class ApiClient {
  const ApiClient({
    required this.baseUrl,
    required this.organizationId,
  });

  final String baseUrl;
  final String organizationId;

  // En V2 : Authorization: Bearer <keycloak_jwt>
  String? _bearerToken;

  void setToken(String token) {
    _bearerToken = token;
  }

  void clearToken() {
    _bearerToken = null;
  }

  bool get isAuthenticated => _bearerToken != null;

  // Les méthodes HTTP seront implémentées en V2 avec le package http ou dio.
  // Exemple d'en-tête requis :
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Organization-Id': organizationId,
        if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
      };
}
