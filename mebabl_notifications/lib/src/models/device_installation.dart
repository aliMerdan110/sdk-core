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
  final bool isActive;
  final DateTime? lastSeenAtUtc;
  final DateTime? createdAtUtc;

  const MebablDeviceInstallation({
    required this.id,
    required this.installationId,
    required this.platform,
    required this.provider,
    this.locale,
    this.isActive = true,
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
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
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
        'isActive': isActive,
        'lastSeenAtUtc': lastSeenAtUtc?.toIso8601String(),
        'createdAtUtc': createdAtUtc?.toIso8601String(),
      };
}
