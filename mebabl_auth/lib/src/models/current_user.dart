class MebablCurrentUser {
  final String accountId;
  final String userId;
  final String applicationId;
  final String email;
  final String username;
  final List<String> roles;
  final List<String> permissions;

  const MebablCurrentUser({
    required this.accountId,
    required this.userId,
    required this.applicationId,
    required this.email,
    required this.username,
    required this.roles,
    required this.permissions,
  });

  factory MebablCurrentUser.fromJson(Map<String, dynamic> json) {
    return MebablCurrentUser(
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
}
