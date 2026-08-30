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
    return MebablConfig(
      applicationId: json['applicationId'] as String,
      platformId: json['platformId'] as String,
      platform: json['platform'] as String,
      packageName: json['packageName'] as String?,
      bundleId: json['bundleId'] as String?,
      domain: json['domain'] as String?,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String,
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
      platformId: platformId ?? this.platformId,
      platform: platform ?? this.platform,
      packageName: packageName ?? this.packageName,
      bundleId: bundleId ?? this.bundleId,
      domain: domain ?? this.domain,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
