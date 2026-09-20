// lib/src/models/register_request.dart

class MebablRegisterRequest {
  final String email;
  final String username;
  final String password;

  const MebablRegisterRequest({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
    };
  }
}
