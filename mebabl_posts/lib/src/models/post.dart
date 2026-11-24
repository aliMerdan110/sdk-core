import 'post_attachment.dart';

/// A post returned by the Mebabl SDK Content API.
///
/// [attachments] are ordered according to the backend's attachment order.
class MebablPost {
  final String id;
  final String ownerId;
  final String? text;
  final DateTime createdAt;
  final String visibility;
  final List<MebablPostAttachment> attachments;

  const MebablPost({
    required this.id,
    required this.ownerId,
    required this.text,
    required this.createdAt,
    required this.attachments,
    this.visibility = 'Public',
  });

  factory MebablPost.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    if (rawAttachments is! List) {
      throw const FormatException(
        'The post response field "attachments" is missing or invalid.',
      );
    }

    final attachments = rawAttachments
        .map((item) {
          return MebablPostAttachment.fromJson(_asMap(item, 'attachment'));
        })
        .toList(growable: false);

    return MebablPost(
      id: _requiredString(json, 'id'),
      ownerId: _requiredString(json, 'ownerId'),
      text: _nullableString(json['text']),
      createdAt: _requiredDateTime(json, 'createdAt'),
      visibility: _nullableString(json['visibility']) ?? 'Public',
      attachments: List.unmodifiable(attachments),
    );
  }

  bool get hasText => text?.trim().isNotEmpty == true;

  bool get hasAttachments => attachments.isNotEmpty;

  bool get hasMediaAssets => attachments.any((item) => item.isMediaAsset);

  bool get hasStoredFileAttachments =>
      attachments.any((item) => item.isStoredFile);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException(
    'The post response field "$key" is missing or invalid.',
  );
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  throw const FormatException('The post text field is invalid.');
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException(
      'The post response field "$key" is missing or invalid.',
    );
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException(
      'The post response field "$key" is not a valid date.',
    );
  }
  return parsed;
}

Map<String, dynamic> _asMap(Object? value, String fieldName) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('The post response $fieldName is invalid.');
}
