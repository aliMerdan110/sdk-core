/// Request body for `POST /api/sdk/content/posts`.
///
/// [mediaAssetIds] is the preferred way to attach images and videos.
/// [storageFileIds] retains the backend field name for StoredFile-backed
/// attachments and is compatible with Project Storage V2 file IDs.
class MebablPostCreateRequest {
  final String? text;
  final List<String> storageFileIds;
  final List<String> mediaAssetIds;
  final String visibility;

  MebablPostCreateRequest({
    required this.text,
    Iterable<String> storageFileIds = const [],
    Iterable<String> mediaAssetIds = const [],
    this.visibility = 'Public',
  }) : storageFileIds = List.unmodifiable(_normalizeIds(storageFileIds)),
       mediaAssetIds = List.unmodifiable(_normalizeIds(mediaAssetIds));

  Map<String, dynamic> toJson() => {
    'text': text,
    'visibility': visibility,
    if (storageFileIds.isNotEmpty) 'storageFileIds': storageFileIds,
    if (mediaAssetIds.isNotEmpty) 'mediaAssetIds': mediaAssetIds,
  };
}

List<String> _normalizeIds(Iterable<String> values) {
  final normalized = <String>[];
  final seen = <String>{};

  for (final value in values) {
    final id = value.trim();
    if (!_guidPattern.hasMatch(id) ||
        id.toLowerCase() == '00000000-0000-0000-0000-000000000000') {
      throw ArgumentError.value(
        value,
        'attachmentIds',
        'Attachment IDs must be valid GUIDs.',
      );
    }
    if (seen.add(id.toLowerCase())) normalized.add(id);
  }

  return normalized;
}

final RegExp _guidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
