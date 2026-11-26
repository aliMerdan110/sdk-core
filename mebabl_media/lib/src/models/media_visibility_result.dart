import 'media_enum_value.dart';

/// Response returned after changing an asset's visibility.
class MebablMediaVisibilityResult {
  final String mediaAssetId;
  final MebablMediaEnumValue visibility;
  final DateTime? updatedAt;

  const MebablMediaVisibilityResult({
    required this.mediaAssetId,
    required this.visibility,
    required this.updatedAt,
  });

  bool get isPrivate => visibility.matches('Private', 1);
  bool get isPublic => visibility.matches('Public', 2);
  bool get isUnlisted => visibility.matches('Unlisted', 3);

  factory MebablMediaVisibilityResult.fromJson(Map<String, dynamic> json) {
    final updatedAtValue = json['updatedAt'];
    DateTime? updatedAt;
    if (updatedAtValue is String) {
      updatedAt = DateTime.tryParse(updatedAtValue);
    }

    return MebablMediaVisibilityResult(
      mediaAssetId: _requiredString(json, 'mediaAssetId'),
      visibility: MebablMediaEnumValue.fromJson(json['visibility']),
      updatedAt: updatedAt,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException(
    'The media response field "$key" is missing or invalid.',
  );
}
