/// A reference to an already uploaded Storage/Media file.
class MebablChatAttachmentInput {
  final String storedFileId;
  final String kind;
  final String? caption;
  final int? durationMilliseconds;
  final List<double> waveform;

  const MebablChatAttachmentInput({
    required this.storedFileId,
    this.kind = 'file',
    this.caption,
    this.durationMilliseconds,
    this.waveform = const [],
  });

  Map<String, dynamic> toJson() => {
        'storedFileId': storedFileId,
        'kind': kind,
        if (caption != null) 'caption': caption,
        if (durationMilliseconds != null)
          'durationMilliseconds': durationMilliseconds,
        if (waveform.isNotEmpty) 'waveform': waveform,
      };
}
