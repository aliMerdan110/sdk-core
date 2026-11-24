import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_posts/mebabl_posts.dart';

void main() {
  group('MebablPost models', () {
    test('parses a post with a MediaAsset attachment', () {
      final post = MebablPost.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'ownerId': '22222222-2222-4222-8222-222222222222',
        'text': 'A photo post',
        'createdAt': '2026-11-17T02:00:00Z',
        'attachments': [
          {
            'id': '33333333-3333-4333-8333-333333333333',
            'storageFileId': null,
            'type': 'Image',
            'order': 0,
            'name': 'photo.webp',
            'path': '',
            'contentType': 'image/webp',
            'size': 2048,
            'isPublic': false,
            'createdAt': '2026-11-17T02:00:00Z',
            'url': '/api/sdk/media/44444444-4444-4444-8444-444444444444/content',
            'mediaAssetId': '44444444-4444-4444-8444-444444444444',
          },
        ],
      });

      expect(post.id, '11111111-1111-4111-8111-111111111111');
      expect(post.ownerId, '22222222-2222-4222-8222-222222222222');
      expect(post.hasText, isTrue);
      expect(post.hasMediaAssets, isTrue);
      expect(post.hasStoredFileAttachments, isFalse);
      expect(post.attachments, hasLength(1));
      expect(post.attachments.single.isMediaAsset, isTrue);
      expect(post.attachments.single.isImage, isTrue);
      expect(post.attachments.single.mediaAssetId, '44444444-4444-4444-8444-444444444444');
      expect(
        post.attachments.single.resolveUri('https://api.example.com'),
        Uri.parse('https://api.example.com/api/sdk/media/44444444-4444-4444-8444-444444444444/content'),
      );
    });

    test('parses a StoredFile attachment from Project Storage V2', () {
      final attachment = MebablPostAttachment.fromJson({
        'id': '55555555-5555-4555-8555-555555555555',
        'storageFileId': '66666666-6666-4666-8666-666666666666',
        'type': 'Video',
        'order': 1,
        'name': 'clip.mp4',
        'path': 'uploads/clip.mp4',
        'contentType': 'video/mp4',
        'size': 4096,
        'isPublic': true,
        'createdAt': '2026-11-17T02:00:00Z',
        'url': '/api/sdk/storage/66666666-6666-4666-8666-666666666666/content',
        'mediaAssetId': null,
      });

      expect(attachment.isStoredFile, isTrue);
      expect(attachment.isPublic, isTrue);
      expect(attachment.isMediaAsset, isFalse);
      expect(attachment.isVideo, isTrue);
    });

    test('rejects a malformed post response', () {
      expect(
        () => MebablPost.fromJson({
          'id': '11111111-1111-4111-8111-111111111111',
          'ownerId': '22222222-2222-4222-8222-222222222222',
          'text': null,
          'createdAt': 'not-a-date',
          'attachments': [],
        }),
        throwsFormatException,
      );
    });
  });

  group('MebablPostCreateRequest', () {
    test('serializes MediaAsset and StoredFile IDs', () {
      final request = MebablPostCreateRequest(
        text: '  Hello  ',
        storageFileIds: const ['66666666-6666-4666-8666-666666666666'],
        mediaAssetIds: const [
          '44444444-4444-4444-8444-444444444444',
          '77777777-7777-4777-8777-777777777777',
        ],
      );

      expect(request.toJson(), {
        'text': '  Hello  ',
        'visibility': 'Public',
        'storageFileIds': ['66666666-6666-4666-8666-666666666666'],
        'mediaAssetIds': [
          '44444444-4444-4444-8444-444444444444',
          '77777777-7777-4777-8777-777777777777',
        ],
      });
    });

    test('normalizes duplicate IDs and rejects empty IDs', () {
      final request = MebablPostCreateRequest(
        text: null,
        mediaAssetIds: const ['44444444-4444-4444-8444-444444444444', '44444444-4444-4444-8444-444444444444'],
      );
      expect(request.mediaAssetIds, ['44444444-4444-4444-8444-444444444444']);

      expect(
        () => MebablPostCreateRequest(text: null, mediaAssetIds: const ['not-a-guid']),
        throwsArgumentError,
      );
    });
  });

  group('Post visibility', () {
    test('parses public, followers and private values', () {
      expect(MebablPostVisibility.validate('Public'), 'Public');
      expect(MebablPostVisibility.validate('Followers'), 'Followers');
      expect(MebablPostVisibility.validate('Private'), 'Private');
    });

    test('rejects unsupported visibility values', () {
      expect(() => MebablPostVisibility.validate('Friends'), throwsArgumentError);
    });

    test('post response defaults to Public for older API payloads', () {
      final post = MebablPost.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'ownerId': '22222222-2222-4222-8222-222222222222',
        'text': 'Legacy public post',
        'createdAt': '2026-11-17T02:00:00Z',
        'attachments': [],
      });
      expect(post.visibility, MebablPostVisibility.public);
    });

    test('post create request serializes selected visibility', () {
      final request = MebablPostCreateRequest(
        text: 'Followers only',
        visibility: MebablPostVisibility.followers,
      );
      expect(request.toJson()['visibility'], 'Followers');
    });
  });
}
