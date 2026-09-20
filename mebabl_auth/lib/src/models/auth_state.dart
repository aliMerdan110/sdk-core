// lib/src/models/auth_state.dart

import 'auth_user.dart';

enum MebablAuthState {
  signedOut,
  signedIn,
}

class MebablAuthStateChanged {
  final MebablAuthState state;
  final AuthUser? user;

  const MebablAuthStateChanged({
    required this.state,
    this.user,
  });
}
