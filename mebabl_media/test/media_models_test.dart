import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_media/mebabl_media.dart';

void main() {
  group('MebablMediaEnumValue', () {
    test('preserves string enum values', () {
      final value = MebablMediaEnumValue.fromJson('Ready');

      expect(value.name, 'Ready');
      expect(value.isNamed('ready'), isTrue);
      expect(value.numericValue, isNull);
    });

    test('preserves numeric enum values without guessing ordinals', () {
      final value = MebablMediaEnumValue.fromJson(2);

      expect(value.numericValue, 2);
      expect(value.name, isNull);
      expect(value.rawValue, 2);
    });
  });

  test('parses upload result', () {
    final result = MebablMediaUploadResult.fromJson({
      'id': '99999999-9999-4999-8999-999999999991',
      'kind': 'Image',
      'visibility': 'Private',
      'status': 'Processing',
      'originalFileName': 'photo.jpg',
      'originalContentType': 'image/jpeg',
      'originalSizeBytes': 1024,
      'sha256Hash': 'abc123',
      'createdAt': '2026-11-17T00:00:00Z',
    });

    expect(result.id, '99999999-9999-4999-8999-999999999991');
    expect(result.kind.isNamed('image'), isTrue);
    expect(result.status.isNamed('processing'), isTrue);
    expect(result.originalSizeBytes, 1024);
  });

  test('parses media details and variants', () {
    final asset = MebablMediaAsset.fromJson({
      'id': '77777777-7777-4777-8777-777777777777',
      'kind': 2,
      'visibility': 1,
      'status': 5,
      'originalFileName': 'clip.mp4',
      'originalContentType': 'video/mp4',
      'originalSizeBytes': 2048,
      'sha256Hash': null,
      'width': 1280,
      'height': 720,
      'durationMilliseconds': 12500,
      'failureCode': null,
      'failureMessage': null,
      'createdAt': '2026-11-17T00:00:00Z',
      'originalContentUrl': '/api/sdk/media/77777777-7777-4777-8777-777777777777/content',
      'variants': [
        {
          'kind': 1,
          'contentType': 'image/jpeg',
          'extension': '.jpg',
          'sizeBytes': 300,
          'width': 320,
          'height': 180,
          'bitrateKbps': null,
          'contentUrl': '/api/sdk/media/77777777-7777-4777-8777-777777777777/variants/Thumbnail/content',
        },
      ],
    });

    expect(asset.kind.numericValue, 2);
    expect(asset.isVideo, isTrue);
    expect(asset.width, 1280);
    expect(asset.durationMilliseconds, 12500);
    expect(asset.variants, hasLength(1));
    expect(asset.variants.single.kind.numericValue, 1);
    expect(asset.variants.single.isThumbnail, isTrue);
    expect(asset.isPrivate, isTrue);
    expect(asset.isReady, isTrue);
  });

  test('parses a paged media library', () {
    final page = MebablMediaLibraryPage.fromJson({
      'page': 1,
      'pageSize': 24,
      'totalCount': 25,
      'items': [
        {
          'id': '88888888-8888-4888-8888-888888888888',
          'kind': 'Video',
          'visibility': 'Private',
          'status': 'Ready',
          'originalFileName': 'clip.webm',
          'originalContentType': 'video/webm',
          'originalSizeBytes': 1024,
          'sha256Hash': null,
          'width': 640,
          'height': 360,
          'durationMilliseconds': 5000,
          'failureCode': null,
          'failureMessage': null,
          'createdAt': '2026-11-17T00:00:00Z',
          'originalContentUrl': '/api/sdk/media/88888888-8888-4888-8888-888888888888/content',
          'variants': [],
        },
      ],
    });

    expect(page.totalPages, 2);
    expect(page.hasNextPage, isTrue);
    expect(page.items.single.isVideo, isTrue);
    expect(page.items.single.isReady, isTrue);
  });
}


