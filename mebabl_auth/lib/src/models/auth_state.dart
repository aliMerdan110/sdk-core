import 'auth_user.dart';

enum MebablAuthState {
  signedOut,
  signedIn,
}

/// A typed authentication-state event for consumers that need more than the
/// current user's nullable stream value.
class MebablAuthStateChanged {
  final MebablAuthState state;
  final AuthUser? user;

  const MebablAuthStateChanged({
    required this.state,
    this.user,
  });
}
