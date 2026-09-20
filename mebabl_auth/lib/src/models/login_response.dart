// lib/src/models/login_response.dart

class MebablLoginResponse {
  final String accountId;
  final String userId;
  final String accessToken;
  final String refreshToken;

  const MebablLoginResponse({
    required this.accountId,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory MebablLoginResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MebablLoginResponse(
      accountId: json['accountId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }
}
