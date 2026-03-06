class MicrosoftSsoConfig {
  static const String tenantId = String.fromEnvironment('MS_TENANT_ID');
  static const String clientId = String.fromEnvironment('MS_CLIENT_ID');
  static const String loginHintDomain =
      String.fromEnvironment('MS_LOGIN_HINT_DOMAIN');

  static bool get hasTenantId => tenantId.trim().isNotEmpty;
  static bool get hasLoginHintDomain => loginHintDomain.trim().isNotEmpty;
  static String get resolvedTenant => hasTenantId ? tenantId.trim() : 'common';

  static String buildLoginHint(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isNotEmpty && normalizedEmail.contains('@')) {
      return normalizedEmail;
    }

    if (hasLoginHintDomain) {
      return '@$loginHintDomain';
    }

    return '';
  }
}