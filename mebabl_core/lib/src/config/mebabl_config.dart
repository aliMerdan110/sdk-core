/// Public configuration embedded in a Mebabl client application.
///
/// [apiKey] is a public identifier. It is not a secret and must only be used
/// to obtain a limited public Application JWT. Never put trusted server
/// credentials or an API secret in a Flutter client configuration.
class MebablConfig {
  final String applicationId;
  final String platformId;
  final String platform;
  final String apiKey;
  final String baseUrl;
  final String? packageName;
  final String? bundleId;
  final String? domain;

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
          'Invalid configuration: "$key" is missing or empty.',
        );
      }
      return value.trim();
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) {
        throw FormatException(
            'Invalid configuration: "$key" must be a string.');
      }
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    final baseUrl = _normalizeBaseUrl(requiredString('baseUrl'));

    return MebablConfig(
      applicationId: requiredString('applicationId'),
      platformId: requiredString('platformId'),
      platform: requiredString('platform'),
      apiKey: requiredString('apiKey'),
      baseUrl: baseUrl,
      packageName: optionalString('packageName'),
      bundleId: optionalString('bundleId'),
      domain: optionalString('domain'),
    );
  }

  /// Serializes only public client configuration.
  ///
  /// Legacy `apiSecret` values in an old JSON file are intentionally ignored
  /// and are never emitted by this model. Remove such values from the asset
  /// itself as well; ignoring a field does not remove it from the bundled file.
  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'platformId': platformId,
        'platform': platform,
        'packageName': packageName,
        'bundleId': bundleId,
        'domain': domain,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
      };

  MebablConfig copyWith({
    String? applicationId,
    String? platformId,
    String? platform,
    String? apiKey,
    String? baseUrl,
    String? packageName,
    String? bundleId,
    String? domain,
  }) {
    return MebablConfig(
      applicationId: applicationId ?? this.applicationId,
      platformId: platformId ?? this.platformId,
      platform: platform ?? this.platform,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl == null ? this.baseUrl : _normalizeBaseUrl(baseUrl),
      packageName: packageName ?? this.packageName,
      bundleId: bundleId ?? this.bundleId,
      domain: domain ?? this.domain,
    );
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw FormatException(
        'Invalid configuration: "baseUrl" must be an absolute HTTP or HTTPS URL without credentials, query, or fragment.',
      );
    }

    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }
}
