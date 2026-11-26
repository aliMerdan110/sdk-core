import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_media/mebabl_media.dart';

void main() {
  group('MebablMediaVisibility', () {
    test('uses backend form and numeric JSON enum values', () {
      expect(MebablMediaVisibility.private.formValue, 'Private');
      expect(MebablMediaVisibility.public.formValue, 'Public');
      expect(MebablMediaVisibility.unlisted.formValue, 'Unlisted');

      expect(MebablMediaVisibility.private.jsonValue, 1);
      expect(MebablMediaVisibility.public.jsonValue, 2);
      expect(MebablMediaVisibility.unlisted.jsonValue, 3);
    });
  });

  group('Numeric backend media enums', () {
    test('recognizes numeric MediaKind and processing status values', () {
      final image = MebablMediaEnumValue.fromJson(1);
      final video = MebablMediaEnumValue.fromJson(2);
      final ready = MebablMediaEnumValue.fromJson(5);

      expect(image.matches('Image', 1), isTrue);
      expect(video.matches('Video', 2), isTrue);
      expect(ready.matches('Ready', 5), isTrue);
    });

    test('parses an Unlisted upload response', () {
      final result = MebablMediaUploadResult.fromJson({
        'id': '9f88dded-4ef8-4e4d-b8f1-5e1d8c7c9f01',
        'kind': 2,
        'visibility': 3,
        'status': 3,
        'originalFileName': 'clip.mp4',
        'originalContentType': 'video/mp4',
        'originalSizeBytes': 2048,
        'sha256Hash': 'abc123',
        'createdAt': '2026-11-17T00:00:00Z',
      });

      expect(result.isVideo, isTrue);
      expect(result.isUnlisted, isTrue);
      expect(result.isReady, isFalse);
    });
  });
}
