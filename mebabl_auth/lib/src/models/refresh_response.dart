// lib/src/models/refresh_response.dart

class MebablRefreshResponse {
  final String accessToken;
  final String refreshToken;

  const MebablRefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory MebablRefreshResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MebablRefreshResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }
}
