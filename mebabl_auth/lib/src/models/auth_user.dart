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
      roles: List<String>.from(
        json['roles'] ?? const [],
      ),
      permissions: List<String>.from(
        json['permissions'] ?? const [],
      ),
    );
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
        'userId: $userId, '
        'email: $email, '
        'username: $username, '
        'roles: $roles, '
        'permissions: $permissions'
        ')';
  }
}
