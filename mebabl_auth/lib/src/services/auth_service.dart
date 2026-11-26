import 'dart:convert';

import 'package:mebabl_core/mebabl_core.dart';

import '../models/auth_state.dart';
import '../models/auth_user.dart';
import '../models/login_response.dart';
import '../models/refresh_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/session_manager.dart';

/// User authentication for Mebabl applications.
///
/// Application authentication is handled by [MebablCore]. This service owns
/// the user access/refresh-token pair and always selects the correct auth mode
/// for each endpoint.
class MebablAuthService implements MebablAuthProvider {
  static const String registerEndpoint = '/api/sdk/auth/register';
  static const String loginEndpoint = '/api/sdk/auth/login';
  static const String refreshEndpoint = '/api/sdk/auth/refresh';
  static const String logoutEndpoint = '/api/sdk/auth/logout';
  static const String meEndpoint = '/api/sdk/auth/me';
  static const String changePasswordEndpoint = '/api/sdk/auth/change-password';
  static const String forgotPasswordEndpoint = '/api/sdk/auth/forgot-password';
  static const String resetPasswordEndpoint = '/api/sdk/auth/reset-password';
  static const String verifyEmailEndpoint = '/api/sdk/auth/verify-email';
  static const String resendVerificationEmailEndpoint =
      '/api/sdk/auth/resend-verification-email';

  final MebablCore core;
  final Duration clockSkew;

  late final MebablSessionManager session;
  Future<MebablRefreshResponse>? _refreshFuture;
  MebablRefreshResponse? _lastRefreshResponse;

  MebablAuthService({
    required this.core,
    this.clockSkew = const Duration(seconds: 30),
  }) {
    session = MebablSessionManager(auth: this);
    core.addAuthProvider(this);
  }

  AuthUser? get currentUser => session.currentUser;

  Stream<AuthUser?> get authStateChanges => session.authStateChanges;

  Stream<MebablAuthStateChanged> get authStateEvents => session.authStateEvents;

  Future<void> initialize() => session.initialize();

  Future<AuthUser?> reload() => session.reload();

  /// Registers a user. Backend registration creates the user session and
  /// returns both tokens; a separate login request is not required.
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
      registerEndpoint,
      data: request.toJson(),
      authMode: MebablAuthMode.application,
    );

    final result = _parseLoginResponse(
      response.data,
      'Invalid register response.',
    );

    await _storeSession(result);
    session.signedIn(
      AuthUser(
        accountId: result.accountId,
        userId: result.userId,
        applicationId: core.config.applicationId,
        email: email.trim(),
        username: username.trim(),
        roles: const [],
        permissions: const [],
      ),
    );
    await _tryLoadCurrentUser();
    return result;
  }

  Future<MebablLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      loginEndpoint,
      data: {
        'email': email.trim(),
        'password': password,
      },
      authMode: MebablAuthMode.application,
    );

    final result = _parseLoginResponse(
      response.data,
      'Invalid login response.',
    );

    await _storeSession(result);
    session.signedIn(
      AuthUser(
        accountId: result.accountId,
        userId: result.userId,
        applicationId: core.config.applicationId,
        email: email.trim(),
        username: '',
        roles: const [],
        permissions: const [],
      ),
    );
    await _tryLoadCurrentUser();
    return result;
  }

  /// Forces a refresh-token rotation and stores the returned token pair.
  /// Concurrent refresh calls share the same in-flight rotation.
  Future<MebablRefreshResponse> refresh() async {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final observedAccessToken = await core.tokenStorage.getAccessToken();
    final refreshStartedWhileReading = _refreshFuture;
    if (refreshStartedWhileReading != null) {
      return refreshStartedWhileReading;
    }

    final latestAccessToken = await core.tokenStorage.getAccessToken();
    final lastRefresh = _lastRefreshResponse;
    if (lastRefresh != null &&
        latestAccessToken != null &&
        latestAccessToken != observedAccessToken &&
        latestAccessToken == lastRefresh.accessToken) {
      return lastRefresh;
    }

    return _refreshOnce(
      observedAccessToken: observedAccessToken,
      force: true,
    );
  }

  Future<String?> getAccessToken() => core.tokenStorage.getAccessToken();

  /// Returns a non-expired User JWT, rotating the refresh token when needed.
  /// Returns null when there is no locally stored user session.
  @override
  Future<String?> getValidAccessToken() async {
    final accessToken = await core.tokenStorage.getAccessToken();
    final refreshToken = await core.tokenStorage.getRefreshToken();

    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !_isTokenExpired(accessToken)) {
      return accessToken;
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      await clearLocalSession();
      return null;
    }

    return _refreshAccessTokenOnce(observedAccessToken: accessToken);
  }

  Future<String> _refreshAccessTokenOnce({
    String? observedAccessToken,
  }) async {
    final result = await _refreshOnce(
      observedAccessToken: observedAccessToken,
    );
    return result.accessToken;
  }

  Future<MebablRefreshResponse> _refreshOnce({
    String? observedAccessToken,
    bool force = false,
  }) {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final future = _refreshWithRecheck(
      observedAccessToken: observedAccessToken,
      force: force,
    );
    _refreshFuture = future;

    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    });
  }

  Future<MebablRefreshResponse> _refreshWithRecheck({
    required String? observedAccessToken,
    required bool force,
  }) async {
    // A parallel request may already have rotated and stored a newer pair.
    // Reuse that exact response rather than rotating the new refresh token a
    // second time. This cache is process-local and never stores secrets on disk.
    if (!force) {
      final latestAccessToken = await core.tokenStorage.getAccessToken();
      final lastRefresh = _lastRefreshResponse;
      if (lastRefresh != null &&
          latestAccessToken != null &&
          latestAccessToken.isNotEmpty &&
          latestAccessToken != observedAccessToken &&
          latestAccessToken == lastRefresh.accessToken &&
          !_isTokenExpired(latestAccessToken)) {
        return lastRefresh;
      }
    }

    return _requestRefresh();
  }

  Future<MebablRefreshResponse> _requestRefresh() async {
    final refreshToken = await core.tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearLocalSession();
      throw const MebablException(
        message: 'No refresh token is available. Please sign in again.',
        statusCode: 401,
      );
    }

    try {
      final response = await core.http.post<Map<String, dynamic>>(
        refreshEndpoint,
        data: {'refreshToken': refreshToken},
        authMode: MebablAuthMode.none,
      );

      final data = response.data;
      if (data == null) {
        throw const MebablException(
          message: 'The refresh endpoint returned an empty response.',
        );
      }

      final result = MebablRefreshResponse.fromJson(data);
      await core.tokenStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _lastRefreshResponse = result;
      return result;
    } on MebablException catch (error) {
      // Only definitive credential rejection destroys the local session.
      // Network errors, timeouts, and server failures leave it available for
      // a later retry.
      if (error.isUnauthorized) {
        await clearLocalSession();
      }
      rethrow;
    } on FormatException catch (error) {
      throw MebablException(
        message: 'The refresh endpoint returned an invalid response.',
        cause: error,
      );
    }
  }

  Future<AuthUser> me() async {
    final response = await core.http.get<Map<String, dynamic>>(
      meEndpoint,
      authMode: MebablAuthMode.user,
    );

    final data = response.data;
    if (data == null) {
      throw const MebablException(
        message: 'The current-user endpoint returned an empty response.',
      );
    }

    return AuthUser.fromJson(
      data,
      fallbackApplicationId: core.config.applicationId,
    );
  }

  Future<bool> isAuthenticated() async {
    final token = await getValidAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      // Resolve an expired access token first. The logout command must contain
      // the currently active refresh token after any automatic rotation.
      await getValidAccessToken();
      final refreshToken = await core.tokenStorage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await core.http.post<void>(
          logoutEndpoint,
          data: {'refreshToken': refreshToken},
          authMode: MebablAuthMode.user,
        );
      }
    } finally {
      await clearLocalSession();
    }
  }

  Future<void> clearLocalSession() async {
    _lastRefreshResponse = null;
    await core.tokenStorage.clear();
    session.signedOutLocal();
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await core.http.post<Map<String, dynamic>>(
      forgotPasswordEndpoint,
      data: {'email': email.trim()},
      authMode: MebablAuthMode.application,
    );
    return _readMessage(
      response.data,
      fallback: 'Password reset instructions have been sent.',
    );
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await core.http.post<Map<String, dynamic>>(
      resetPasswordEndpoint,
      data: {
        'token': token,
        'newPassword': newPassword,
      },
      authMode: MebablAuthMode.none,
    );
    return _readMessage(
      response.data,
      fallback: 'Password has been reset successfully.',
    );
  }

  Future<String> verifyEmail({required String token}) async {
    final response = await core.http.post<Map<String, dynamic>>(
      verifyEmailEndpoint,
      data: {'token': token},
      authMode: MebablAuthMode.none,
    );
    return _readMessage(
      response.data,
      fallback: 'Email has been verified successfully.',
    );
  }

  Future<String> resendVerificationEmail() async {
    final response = await core.http.post<Map<String, dynamic>>(
      resendVerificationEmailEndpoint,
      authMode: MebablAuthMode.user,
    );
    return _readMessage(
      response.data,
      fallback: 'Verification email has been sent.',
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await core.http.post<void>(
      changePasswordEndpoint,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      authMode: MebablAuthMode.user,
    );
  }

  Future<void> dispose() async {
    core.removeAuthInterceptor();
    await session.dispose();
  }

  Future<void> _storeSession(MebablLoginResponse result) async {
    _lastRefreshResponse = null;
    await core.tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }

  Future<void> _tryLoadCurrentUser() async {
    try {
      final user = await me();
      session.signedIn(user);
    } on MebablException catch (error) {
      if (error.isUnauthorized) {
        await clearLocalSession();
        rethrow;
      }
      if (error.isClientError && !error.isRateLimited) {
        rethrow;
      }
      // Authentication itself succeeded. Preserve tokens after transient
      // network/server errors; initialize() or reload() can hydrate the user.
    }
  }

  MebablLoginResponse _parseLoginResponse(
    Map<String, dynamic>? data,
    String emptyMessage,
  ) {
    if (data == null) {
      throw MebablException(message: emptyMessage);
    }

    try {
      return MebablLoginResponse.fromJson(data);
    } on FormatException catch (error) {
      throw MebablException(
        message: emptyMessage,
        cause: error,
      );
    }
  }

  String _readMessage(
    Map<String, dynamic>? data, {
    required String fallback,
  }) {
    final message = data?['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return fallback;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return true;

      final expiration = decoded['exp'];
      if (expiration is! num) return true;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiration.toInt() * 1000,
        isUtc: true,
      );

      return !DateTime.now().toUtc().add(clockSkew).isBefore(expiresAt);
    } catch (_) {
      return true;
    }
  }
}
