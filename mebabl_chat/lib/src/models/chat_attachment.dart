import 'json_helpers.dart';

class MebablChatAttachment {
  final String id;
  final String storedFileId;
  final String kind;
  final String? caption;
  final String? fileName;
  final String? contentType;
  final int? sizeBytes;
  final int? durationMilliseconds;
  final List<double> waveform;
  final String? contentUrl;
  final DateTime? createdAtUtc;

  const MebablChatAttachment({
    required this.id,
    required this.storedFileId,
    required this.kind,
    this.caption,
    this.fileName,
    this.contentType,
    this.sizeBytes,
    this.durationMilliseconds,
    this.waveform = const [],
    this.contentUrl,
    this.createdAtUtc,
  });

  factory MebablChatAttachment.fromJson(Map<String, dynamic> json) {
    final rawWaveform = json['waveform'] ?? json['waveformJson'];
    List<double> points = const [];
    if (rawWaveform is List) {
      points = rawWaveform.whereType<num>().map((v) => v.toDouble()).toList(growable: false);
    }
    return MebablChatAttachment(
      id: optionalString(json, 'id') ?? optionalString(json, 'attachmentId') ?? '',
      storedFileId: requiredString(json, 'storedFileId'),
      kind: optionalString(json, 'kind') ?? 'file',
      caption: optionalString(json, 'caption'),
      fileName: optionalString(json, 'fileName') ?? optionalString(json, 'name'),
      contentType: optionalString(json, 'contentType'),
      sizeBytes: (json['sizeBytes'] ?? json['fileSizeBytes']) == null
          ? null
          : intValue(json['sizeBytes'] ?? json['fileSizeBytes']),
      durationMilliseconds: json['durationMilliseconds'] == null
          ? null
          : intValue(json['durationMilliseconds']),
      waveform: points,
      contentUrl: optionalString(json, 'contentUrl') ?? optionalString(json, 'url'),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storedFileId': storedFileId,
        'kind': kind,
        'caption': caption,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'durationMilliseconds': durationMilliseconds,
        'waveform': waveform,
        'contentUrl': contentUrl,
        'createdAtUtc': createdAtUtc?.toIso8601String(),
      };
}
