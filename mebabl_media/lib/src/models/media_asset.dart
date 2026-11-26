import 'media_enum_value.dart';
import 'media_variant.dart';

/// Detailed representation of an image or video media asset.
///
/// Enum fields retain the raw API value. Use [MebablMediaEnumValue.isNamed]
/// when the backend emits enum names, or [MebablMediaEnumValue.numericValue]
/// when it emits numeric enum values.
class MebablMediaAsset {
  final String id;
  final MebablMediaEnumValue kind;
  final MebablMediaEnumValue visibility;
  final MebablMediaEnumValue status;
  final String originalFileName;
  final String originalContentType;
  final int originalSizeBytes;
  final String? sha256Hash;
  final int? width;
  final int? height;
  final int? durationMilliseconds;
  final String? failureCode;
  final String? failureMessage;
  final DateTime createdAt;
  final String originalContentUrl;
  final List<MebablMediaVariant> variants;

  const MebablMediaAsset({
    required this.id,
    required this.kind,
    required this.visibility,
    required this.status,
    required this.originalFileName,
    required this.originalContentType,
    required this.originalSizeBytes,
    required this.sha256Hash,
    required this.width,
    required this.height,
    required this.durationMilliseconds,
    required this.failureCode,
    required this.failureMessage,
    required this.createdAt,
    required this.originalContentUrl,
    required this.variants,
  });

  factory MebablMediaAsset.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'];
    if (variantsJson is! List) {
      throw const FormatException(
        'The media response field "variants" is invalid.',
      );
    }

    return MebablMediaAsset(
      id: _requiredString(json, 'id'),
      kind: MebablMediaEnumValue.fromJson(json['kind']),
      visibility: MebablMediaEnumValue.fromJson(json['visibility']),
      status: MebablMediaEnumValue.fromJson(json['status']),
      originalFileName: _requiredString(json, 'originalFileName'),
      originalContentType: _requiredString(json, 'originalContentType'),
      originalSizeBytes: _requiredInt(json, 'originalSizeBytes'),
      sha256Hash: _nullableString(json['sha256Hash']),
      width: _nullableInt(json['width']),
      height: _nullableInt(json['height']),
      durationMilliseconds: _nullableInt(json['durationMilliseconds']),
      failureCode: _nullableString(json['failureCode']),
      failureMessage: _nullableString(json['failureMessage']),
      createdAt: _requiredDateTime(json, 'createdAt'),
      originalContentUrl: _requiredString(json, 'originalContentUrl'),
      variants: variantsJson
          .map((item) => MebablMediaVariant.fromJson(_asMap(item, 'variant')))
          .toList(growable: false),
    );
  }

  bool get isImage => kind.matches('Image', 1);
  bool get isVideo => kind.matches('Video', 2);
  bool get isReady => status.matches('Ready', 5);
  bool get isPrivate => visibility.matches('Private', 1);
  bool get isPublic => visibility.matches('Public', 2);
  bool get isUnlisted => visibility.matches('Unlisted', 3);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException(
    'The media response field "$key" is missing or invalid.',
  );
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'The media response field "$key" is missing or invalid.',
  );
}

String? _nullableString(Object? value) => value?.toString();

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException(
      'The media response field "$key" is missing or invalid.',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException(
      'The media response field "$key" is not a valid date.',
    );
  }
  return parsed;
}

Map<String, dynamic> _asMap(Object? value, String fieldName) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('The media response $fieldName is invalid.');
}
