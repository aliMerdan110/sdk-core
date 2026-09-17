class MebablConfig {
  final String applicationId;
  final String platformId;
  final String platform;
  final String? packageName;
  final String? bundleId;
  final String? domain;
  final String apiKey;
  final String baseUrl;

  const MebablConfig({
    required this.applicationId,
    required this.platformId,
    required this.platform,
    required this.apiKey,
    required this.baseUrl,
    this.packageName,
    this.bundleId,
    this.domain,
  });

  factory MebablConfig.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];

      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Invalid configuration: "$key" is missing.',
        );
      }

      return value.trim();
    }

    String? optionalString(String key) {
      final value = json[key];

      if (value == null) {
        return null;
      }

      if (value is! String) {
        throw FormatException(
          'Invalid configuration: "$key".',
        );
      }

      final result = value.trim();

      return result.isEmpty ? null : result;
    }

    return MebablConfig(
      applicationId: requiredString('applicationId'),
      platformId: requiredString('platformId'),
      platform: requiredString('platform'),
      apiKey: requiredString('apiKey'),
      baseUrl: requiredString('baseUrl'),
      packageName: optionalString('packageName'),
      bundleId: optionalString('bundleId'),
      domain: optionalString('domain'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'platformId': platformId,
      'platform': platform,
      'packageName': packageName,
      'bundleId': bundleId,
      'domain': domain,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
    };
  }

  MebablConfig copyWith({
    String? applicationId,
    String? platformId,
    String? platform,
    String? packageName,
    String? bundleId,
    String? domain,
    String? apiKey,
    String? baseUrl,
  }) {
    return MebablConfig(
      applicationId: applicationId ?? this.applicationId,
      platformId: platformId ?? this.platformId
      ,
      platform: platform ?? this.platform,
      packageName: packageName ?? this.packageName,
      bundleId: bundleId ?? this.bundleId,
      domain: domain ?? this.domain,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
