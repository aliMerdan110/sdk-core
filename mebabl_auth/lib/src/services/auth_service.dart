import 'dart:convert';

import 'package:mebabl_auth/src/models/register_response.dart';
import 'package:mebabl_core/mebabl_core.dart';

import '../models/login_response.dart';
import '../models/refresh_response.dart';
import '../models/auth_user.dart';

class MebablAuthService implements MebablAuthProvider {
  final MebablCore core;

  MebablAuthService({
    required this.core,
  }) {
    // التصحيح هنا: تمرير الدالة بدلاً من الكلاس
    core.http.addInterceptor(
      MebablAuthInterceptor(
        getValidAccessToken: () => getValidAccessToken(),
      ),
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

      final exp = data['exp'];

      if (exp is! num) {
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      return DateTime.now().toUtc().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

  Future<MebablRegisterResponse> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      '/api/sdk/auth/register',
      data: {
        'email': email,
        'username': username,
        'password': password,
      },
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

    return result;
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

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

    return result;
  }

  // ------------------------------------------------------------
  // REFRESH
  // ------------------------------------------------------------

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

  // method to get the current authenticated user
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

  Future<bool> isAuthenticated() async {
    final accessToken = await core.tokenStorage.getAccessToken();

    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
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

    try {
      final response = await refresh();

      return response.accessToken;
    } on MebablException {
      await core.tokenStorage.clear();
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

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
      await core.tokenStorage.clear();
    }
  }

// ------------------------------------------------------------

  // ------------------------------------------------------------
  // FORGOT PASSWORD
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // RESET PASSWORD
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // VERIFY EMAIL
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // RESEND VERIFICATION EMAIL
  // ------------------------------------------------------------

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

    return data['message']?.toString() ?? 'Verification email has been sent.';
  }
}
