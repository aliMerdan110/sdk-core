import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'application_auth/application_auth_service.dart';
import 'application_auth/application_token_storage.dart';
import 'auth/mebabl_auth_provider.dart';
import 'auth/token_storage.dart';
import 'client/interceptors/mebabl_application_auth_interceptor.dart';
import 'client/interceptors/mebabl_auth_interceptor.dart';
import 'client/mebabl_http_client.dart';
import 'config/mebabl_config.dart';

/// Entry point for the Mebabl Flutter SDK.
///
/// Core owns public application authentication and shared infrastructure.
/// User registration, login, refresh, and logout are implemented by the
/// separate `mebabl_auth` package.
class MebablCore {
  static MebablCore? _instance;
  static Future<MebablCore>? _initializationFuture;

  final MebablConfig config;
  final MebablTokenStorage tokenStorage;
  final MebablApplicationTokenStorage applicationTokenStorage;
  final MebablHttpClient http;
  final MebablApplicationAuthService applicationAuth;

  MebablApplicationAuthInterceptor? _applicationAuthInterceptor;
  MebablAuthInterceptor? _userAuthInterceptor;

  MebablCore._({
    required this.config,
    required this.tokenStorage,
    required this.applicationTokenStorage,
    required this.http,
    required this.applicationAuth,
  });

  static MebablCore get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'MebablCore has not been initialized. '
        'Call await MebablCore.initialize() first.',
      );
    }
    return current;
  }

  static bool get isInitialized => _instance != null;

  /// Loads `assets/mebabl.json` and initializes the singleton.
  ///
  /// Concurrent calls share the same initialization operation.
  static Future<MebablCore> initialize({
    String assetPath = 'assets/mebabl.json',
    FlutterSecureStorage? secureStorage,
  }) {
    return _initializeOnce(() async {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid mebabl.json format.');
      }

      final config = MebablConfig.fromJson(decoded);
      return _create(
        config: config,
        secureStorage: secureStorage,
      );
    });
  }

  /// Initializes Core from an already-loaded configuration.
  ///
  /// This is useful for tests or applications that obtain configuration from
  /// a source other than Flutter's asset bundle.
  static Future<MebablCore> initializeWithConfig({
    required MebablConfig config,
    FlutterSecureStorage? secureStorage,
  }) {
    return _initializeOnce(() async => _create(
          config: config,
          secureStorage: secureStorage,
        ));
  }

  static Future<MebablCore> _initializeOnce(
    Future<MebablCore> Function() factory,
  ) {
    final current = _instance;
    if (current != null) return Future<MebablCore>.value(current);

    final pending = _initializationFuture;
    if (pending != null) return pending;

    final future = factory().then((core) {
      _instance = core;
      return core;
    });

    _initializationFuture = future;
    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  static MebablCore _create({
    required MebablConfig config,
    FlutterSecureStorage? secureStorage,
  }) {
    final storage = secureStorage ?? const FlutterSecureStorage();
    final userTokenStorage = MebablTokenStorage(storage: storage);
    final appTokenStorage = MebablApplicationTokenStorage(storage: storage);

    final http = MebablHttpClient(
      config: config,
      tokenStorage: userTokenStorage,
    );

    final applicationAuth = MebablApplicationAuthService(
      config: config,
      http: http,
      tokenStorage: appTokenStorage,
    );

    final core = MebablCore._(
      config: config,
      tokenStorage: userTokenStorage,
      applicationTokenStorage: appTokenStorage,
      http: http,
      applicationAuth: applicationAuth,
    );

    core.addApplicationAuthInterceptor();
    return core;
  }

  /// Adds the application interceptor once. It is installed automatically
  /// during initialization; this method remains available for compatibility.
  void addApplicationAuthInterceptor() {
    final current = _applicationAuthInterceptor;
    if (current != null) return;

    final interceptor = MebablApplicationAuthInterceptor(
      applicationAuth: applicationAuth,
      dio: http.dio,
    );
    _applicationAuthInterceptor = interceptor;
    http.addInterceptor(interceptor);
  }

  /// Registers an implementation of [MebablAuthProvider] from
  /// `mebabl_auth` as the source of User JWTs.
  void addAuthProvider(MebablAuthProvider provider) {
    addAuthInterceptor(
      getValidAccessToken: provider.getValidAccessToken,
    );
  }

  /// Configures the User JWT token loader directly.
  ///
  /// Calling this again replaces the previous provider interceptor rather
  /// than adding a duplicate.
  void addAuthInterceptor({
    required Future<String?> Function() getValidAccessToken,
  }) {
    final previous = _userAuthInterceptor;
    if (previous != null) {
      http.removeInterceptor(previous);
    }

    final interceptor = MebablAuthInterceptor(
      getValidAccessToken: getValidAccessToken,
    );
    _userAuthInterceptor = interceptor;
    http.addInterceptor(interceptor);
  }

  /// Removes the configured User JWT interceptor.
  void removeAuthInterceptor() {
    final previous = _userAuthInterceptor;
    if (previous == null) return;
    http.removeInterceptor(previous);
    _userAuthInterceptor = null;
  }

  /// Closes the HTTP client. Securely stored tokens are not deleted.
  void dispose({bool force = false}) {
    http.close(force: force);
  }

  /// Resets the singleton, primarily for tests.
  ///
  /// This does not delete persisted tokens. Call the relevant storage
  /// `clear()` method when a session must be removed.
  static void reset() {
    final oldInstance = _instance;
    _instance = null;
    _initializationFuture = null;
    oldInstance?.dispose(force: true);
  }
}
