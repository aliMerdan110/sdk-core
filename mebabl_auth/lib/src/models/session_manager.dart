// lib/src/models/session_manager.dart

import 'dart:async';

import 'package:mebabl_core/mebabl_core.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';

class MebablSessionManager {
  final MebablAuthService auth;

  AuthUser? _currentUser;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  bool _initialized = false;

  MebablSessionManager({
    required this.auth,
  });

  AuthUser? get currentUser => _currentUser;

  Stream<AuthUser?> get authStateChanges => _controller.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    final token = await auth.getValidAccessToken();

    if (token == null || token.isEmpty) {
      _setUser(null);
      return;
    }

    try {
      final user = await auth.me();
      _setUser(user);
    } on MebablException {
      await auth.clearLocalSession();
      _setUser(null);
    }
  }

  Future<AuthUser?> reload() async {
    final token = await auth.getValidAccessToken();

    if (token == null || token.isEmpty) {
      _setUser(null);
      return null;
    }

    try {
      final user = await auth.me();
      _setUser(user);
      return user;
    } on MebablException {
      _setUser(null);
      return null;
    }
  }

  void signedIn(AuthUser user) {
    _setUser(user);
  }

  Future<void> signedOut() async {
    await auth.logout();
  }

  void signedOutLocal() {
    _setUser(null);
  }

  void _setUser(AuthUser? user) {
    _currentUser = user;

    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
