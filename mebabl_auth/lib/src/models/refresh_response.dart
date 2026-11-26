class MebablRefreshResponse {
  final String accountId;
  final String userId;
  final String accessToken;
  final String refreshToken;

  const MebablRefreshResponse({
    required this.accountId,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory MebablRefreshResponse.fromJson(Map<String, dynamic> json) {
    return MebablRefreshResponse(
      accountId: _requiredString(json, 'accountId'),
      userId: _requiredString(json, 'userId'),
      accessToken: _requiredString(json, 'accessToken'),
      refreshToken: _requiredString(json, 'refreshToken'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Refresh response is missing "$key".');
  }
  return value.trim();
}
