import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_content/mebabl_content.dart';

void main() {
  group('PostAttachment', () {
    test('creates attachment from JSON', () {
      final attachment = PostAttachment.fromJson({
        'id': 'attachment-1',
        'storageFileId': 'file-1',
        'type': 'Image',
        'order': 0,
        'name': 'image.jpg',
        'path': 'posts/image.jpg',
        'contentType': 'image/jpeg',
        'size': 1024,
        'isPublic': true,
        'createdAt': '2026-09-18T10:00:00Z',
        'url': '/storage/files/file-1',
      });

      expect(attachment.id, 'attachment-1');
      expect(attachment.storageFileId, 'file-1');
      expect(attachment.type, 'Image');
      expect(attachment.order, 0);
      expect(attachment.name, 'image.jpg');
      expect(attachment.contentType, 'image/jpeg');
      expect(attachment.size, 1024);
      expect(attachment.isPublic, true);
      expect(attachment.url, '/storage/files/file-1');
    });
  });

  group('Post', () {
    test('creates post from JSON', () {
      final post = Post.fromJson({
        'id': 'post-1',
        'ownerId': 'user-1',
        'text': 'Hello Mebabl',
        'createdAt': '2026-09-18T10:00:00Z',
        'attachments': [
          {
            'id': 'attachment-1',
            'storageFileId': 'file-1',
            'type': 'Image',
            'order': 0,
            'name': 'image.jpg',
            'path': 'posts/image.jpg',
            'contentType': 'image/jpeg',
            'size': 1024,
            'isPublic': true,
            'createdAt': '2026-09-18T10:00:00Z',
            'url': '/storage/files/file-1',
          },
        ],
      });

      expect(post.id, 'post-1');
      expect(post.ownerId, 'user-1');
      expect(post.text, 'Hello Mebabl');
      expect(post.attachments.length, 1);
      expect(post.attachments.first.storageFileId, 'file-1');
    });

    test('creates text-only post', () {
      final post = Post.fromJson({
        'id': 'post-2',
        'ownerId': 'user-2',
        'text': 'Text only',
        'createdAt': '2026-09-18T10:00:00Z',
        'attachments': [],
      });

      expect(post.text, 'Text only');
      expect(post.attachments, isEmpty);
    });
  });
}
