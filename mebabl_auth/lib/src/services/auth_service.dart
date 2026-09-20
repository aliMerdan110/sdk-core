// lib/src/services/auth_service.dart

import 'dart:convert';

import 'package:mebabl_auth/mebabl_auth.dart';
import 'package:mebabl_auth/src/models/register_response.dart';
import 'package:mebabl_auth/src/models/session_manager.dart';
import 'package:mebabl_core/mebabl_core.dart';

class MebablAuthService implements MebablAuthProvider {
  final MebablCore core;

  late final MebablSessionManager session;

  Future<String?>? _refreshFuture;

  MebablAuthService({
    required this.core,
  }) {
    core.addAuthInterceptor(
      getValidAccessToken: getValidAccessToken,
    );

    session = MebablSessionManager(
      auth: this,
    );
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(
        base64Url.decode(normalized),
      );

      final data = jsonDecode(decoded);

      if (data is! Map<String, dynamic>) {
        return true;
      }

      final exp = data['exp'];

      if (exp is! num) {
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      return !DateTime.now().toUtc().isBefore(expiry);
    } catch (_) {
      return true;
    }
  }

  Future<MebablRegisterResponse> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final request = MebablRegisterRequest(
      email: email,
      username: username,
      password: password,
    );

    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/register',
      data: request.toJson(),
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid register response.',
      );
    }

    final result = MebablRegisterResponse.fromJson(data);

    await core.tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    try {
      final user = await me();
      session.signedIn(user);
    } catch (_) {}

    return result;
  }

  Future<MebablLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid login response.',
      );
    }

    final result = MebablLoginResponse.fromJson(data);

    await core.tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    try {
      final user = await me();
      session.signedIn(user);
    } catch (_) {}

    return result;
  }

  Future<MebablRefreshResponse> refresh() async {
    final refreshToken = await core.tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const MebablException(
        message: 'No refresh token available.',
      );
    }

    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid refresh response.',
      );
    }

    final result = MebablRefreshResponse.fromJson(data);

    await core.tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    return result;
  }

  Future<AuthUser> me() async {
    final response = await core.http.get<Map<String, dynamic>>(
      '/api/sdk/auth/me',
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid current user response.',
      );
    }

    return AuthUser.fromJson(data);
  }

  AuthUser? get currentUser => session.currentUser;

  Stream<AuthUser?> get authStateChanges => session.authStateChanges;

  Future<void> initialize() {
    return session.initialize();
  }

  Future<AuthUser?> reload() {
    return session.reload();
  }

  Future<bool> isAuthenticated() async {
    final token = await getValidAccessToken();

    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() {
    return core.tokenStorage.getAccessToken();
  }

  @override
  Future<String?> getValidAccessToken() async {
    final accessToken = await getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    if (!_isTokenExpired(accessToken)) {
      return accessToken;
    }

    final existingRefresh = _refreshFuture;

    if (existingRefresh != null) {
      return existingRefresh;
    }

    final refreshFuture = _performRefresh();

    _refreshFuture = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<String?> _performRefresh() async {
    try {
      final response = await refresh();
      return response.accessToken;
    } on MebablException {
      await clearLocalSession();
      rethrow;
    }
  }

  Future<void> clearLocalSession() async {
    await core.tokenStorage.clear();
    session.signedOutLocal();
  }

  Future<void> logout() async {
    final refreshToken = await core.tokenStorage.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await core.http.post(
          '/api/sdk/auth/logout',
          data: {
            'refreshToken': refreshToken,
          },
        );
      }
    } finally {
      await clearLocalSession();
    }
  }

  Future<String> forgotPassword({
    required String email,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/forgot-password',
      data: {
        'email': email,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid forgot password response.',
      );
    }

    return data['message']?.toString() ??
        'Password reset instructions have been sent.';
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid reset password response.',
      );
    }

    return data['message']?.toString() ??
        'Password has been reset successfully.';
  }

  Future<String> verifyEmail({
    required String token,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/verify-email',
      data: {
        'token': token,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid email verification response.',
      );
    }

    return data['message']?.toString() ??
        'Email has been verified successfully.';
  }

  Future<String> resendVerificationEmail() async {
    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/resend-verification-email',
    );

    final data = response.data;

    if (data == null) {
      throw const MebablException(
        message: 'Invalid resend verification response.',
      );
    }

    return data['message']?.toString() ??
        'Verification email has been sent.';
  }
}