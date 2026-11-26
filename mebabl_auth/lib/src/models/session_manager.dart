import 'dart:async';

import 'package:mebabl_core/mebabl_core.dart';

import '../services/auth_service.dart';
import 'auth_state.dart';
import 'auth_user.dart';

/// Maintains the in-memory current user and publishes authentication changes.
/// The persisted tokens remain owned by [MebablAuthService].
class MebablSessionManager {
  final MebablAuthService auth;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  final StreamController<MebablAuthStateChanged> _stateController =
      StreamController<MebablAuthStateChanged>.broadcast();

  AuthUser? _currentUser;
  bool _initialized = false;
  Future<void>? _initializationFuture;

  MebablSessionManager({required this.auth});

  AuthUser? get currentUser => _currentUser;

  Stream<AuthUser?> get authStateChanges => _controller.stream;

  Stream<MebablAuthStateChanged> get authStateEvents => _stateController.stream;

  bool get isInitialized => _initialized;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();

    final pending = _initializationFuture;
    if (pending != null) return pending;

    final future = _initializeInternal();
    _initializationFuture = future;

    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> _initializeInternal() async {
    try {
      final accessToken = await auth.getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _setUser(null);
        _initialized = true;
        return;
      }

      final user = await auth.me();
      _setUser(user);
      _initialized = true;
    } on MebablException catch (error) {
      if (error.isUnauthorized) {
        await auth.clearLocalSession();
        _setUser(null);
        _initialized = true;
        return;
      }

      // Network/server failures must not erase a potentially valid session.
      rethrow;
    }
  }

  Future<AuthUser?> reload() async {
    try {
      final accessToken = await auth.getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _setUser(null);
        return null;
      }

      final user = await auth.me();
      _setUser(user);
      return user;
    } on MebablException catch (error) {
      if (error.isUnauthorized) {
        await auth.clearLocalSession();
        _setUser(null);
        return null;
      }
      rethrow;
    }
  }

  void signedIn(AuthUser user) {
    _setUser(user);
    _initialized = true;
  }

  Future<void> signedOut() => auth.logout();

  void signedOutLocal() {
    _setUser(null);
    _initialized = true;
  }

  void _setUser(AuthUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) _controller.add(user);
    if (!_stateController.isClosed) {
      _stateController.add(
        MebablAuthStateChanged(
          state: user == null
              ? MebablAuthState.signedOut
              : MebablAuthState.signedIn,
          user: user,
        ),
      );
    }
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
    if (!_stateController.isClosed) await _stateController.close();
  }
}
