import 'json_helpers.dart';

String optionalId(Map<String, dynamic> json) {
  final value = json['id'] ?? json['deviceId'] ?? json['installationRecordId'];
  if (value is String && value.trim().isNotEmpty) return value;
  throw const FormatException('Expected a device id.');
}

class MebablDeviceInstallation {
  final String id;
  final String installationId;
  final String platform;
  final String provider;
  final String? locale;
  final String? appVersion;
  final bool isActive;
  final DateTime? lastRegisteredAtUtc;
  final DateTime? lastSeenAtUtc;
  final DateTime? createdAtUtc;

  const MebablDeviceInstallation({
    required this.id,
    required this.installationId,
    required this.platform,
    required this.provider,
    this.locale,
    this.appVersion,
    this.isActive = true,
    this.lastRegisteredAtUtc,
    this.lastSeenAtUtc,
    this.createdAtUtc,
  });

  factory MebablDeviceInstallation.fromJson(Map<String, dynamic> json) {
    return MebablDeviceInstallation(
      id: optionalId(json),
      installationId: requiredString(json, 'installationId'),
      platform: requiredString(json, 'platform'),
      provider: requiredString(json, 'provider'),
      locale: optionalString(json, 'locale'),
      appVersion: optionalString(json, 'appVersion'),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      lastRegisteredAtUtc: optionalDateTime(json['lastRegisteredAtUtc']),
      lastSeenAtUtc: optionalDateTime(json['lastSeenAtUtc'] ?? json['lastSeenAt']),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'installationId': installationId,
        'platform': platform,
        'provider': provider,
        'locale': locale,
        'appVersion': appVersion,
        'isActive': isActive,
        'lastRegisteredAtUtc': lastRegisteredAtUtc?.toIso8601String(),
        'lastSeenAtUtc': lastSeenAtUtc?.toIso8601String(),
        'createdAtUtc': createdAtUtc?.toIso8601String(),
      };
}
