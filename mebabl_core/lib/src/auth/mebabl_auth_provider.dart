// lib/src/auth/mebabl_auth_provider.dart

abstract interface class MebablAuthProvider {
  Future<String?> getValidAccessToken();
}
