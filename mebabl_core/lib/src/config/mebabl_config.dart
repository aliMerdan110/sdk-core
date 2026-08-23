class MebablConfig {
  final String applicationId;
  final String apiKey;
  final String baseUrl;

  const MebablConfig({
    required this.applicationId,
    required this.apiKey,
    required this.baseUrl,
  });

  MebablConfig copyWith({
    String? applicationId,
    String? apiKey,
    String? baseUrl,
  }) {
    return MebablConfig(
      applicationId: applicationId ?? this.applicationId,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
