// lib/src/models/auth_user.dart

class AuthUser {
  final String accountId;
  final String userId;
  final String applicationId;
  final String email;
  final String username;
  final List<String> roles;
  final List<String> permissions;

  const AuthUser({
    required this.accountId,
    required this.userId,
    required this.applicationId,
    required this.email,
    required this.username,
    required this.roles,
    required this.permissions,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      accountId: json['accountId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  @override
  String toString() {
    return 'AuthUser('
        'accountId: $accountId, '
        'userId: $userId, '
        'applicationId: $applicationId, '
        'email: $email, '
        'username: $username, '
        'roles: $roles, '
        'permissions: $permissions'
        ')';
  }
}
