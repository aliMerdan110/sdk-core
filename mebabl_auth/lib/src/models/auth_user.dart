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

  factory AuthUser.fromJson(
    Map<String, dynamic> json, {
    String? fallbackApplicationId,
  }) {
    return AuthUser(
      accountId: _readString(json, 'accountId'),
      userId: _readString(json, 'userId'),
      applicationId: _readString(json, 'applicationId').isNotEmpty
          ? _readString(json, 'applicationId')
          : (fallbackApplicationId ?? ''),
      email: _readString(json, 'email'),
      username: _readString(json, 'username'),
      roles: _readStringList(json['roles']),
      permissions: _readStringList(json['permissions']),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value : (value?.toString() ?? '');
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool hasRole(String role) => roles.contains(role);

  bool hasPermission(String permission) => permissions.contains(permission);

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
