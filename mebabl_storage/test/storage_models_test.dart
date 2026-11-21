import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_storage/mebabl_storage.dart';

void main() {
  group('MebablStoredFile', () {
    test('parses safe metadata from the current StoredFile response', () {
      final file = MebablStoredFile.fromJson({
        'id': '7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124',
        'projectId': 'e48deac6-3cd4-4d49-9b7b-c7d46c28ea01',
        'applicationId': 'cc7ba15e-1ef0-4705-a186-e6a22d659140',
        'bucketId': '3c0a3c6d-9958-44ef-8d48-d4a79d9bc5ba',
        'userId': '8a7aeedf-fc65-4e15-9d5c-3a6e7fdd2eb5',
        'path': 'avatars/user-1/avatar.png',
        'fileName': 'avatar.png',
        'name': 'avatar',
        'contentType': 'image/png',
        'extension': '.png',
        'size': 1024,
        'storageProviderKey': 'local',
        'storageKey': 'internal-provider-key',
        'hash': 'abc123',
        'version': 1,
        'createdAt': '2026-11-21T05:00:00Z',
      });

      expect(file.id, '7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124');
      expect(file.fileName, 'avatar.png');
      expect(file.name, 'avatar');
      expect(file.size, 1024);
      expect(file.contentType, 'image/png');
      expect(file.hash, 'abc123');
      expect(file.version, 1);
      expect(file.createdAt, DateTime.parse('2026-11-21T05:00:00Z'));
    });

    test('supports PascalCase response fields', () {
      final file = MebablStoredFile.fromJson({
        'Id': '7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124',
        'BucketId': '3c0a3c6d-9958-44ef-8d48-d4a79d9bc5ba',
        'Path': 'docs/report.pdf',
        'FileName': 'report.pdf',
        'ContentType': 'application/pdf',
        'Size': 256,
      });

      expect(file.fileName, 'report.pdf');
      expect(file.createdAt, isNull);
    });
  });

  group('MebablStorageObjectPage', () {
    test('parses paged objects', () {
      final page = MebablStorageObjectPage.fromJson({
        'page': 2,
        'pageSize': 1,
        'hasMore': true,
        'items': [
          {
            'id': '7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124',
            'bucketId': '3c0a3c6d-9958-44ef-8d48-d4a79d9bc5ba',
            'path': 'images/photo.jpg',
            'fileName': 'photo.jpg',
            'contentType': 'image/jpeg',
            'size': 4096,
            'createdAt': '2026-11-21T05:00:00Z',
            'contentUrl':
                '/api/sdk/storage/7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124/content',
          },
        ],
      });

      expect(page.page, 2);
      expect(page.pageSize, 1);
      expect(page.hasMore, isTrue);
      expect(page.items.single.path, 'images/photo.jpg');
      expect(page.items.single.size, 4096);
    });

    test('rejects an invalid items collection', () {
      expect(
        () => MebablStorageObjectPage.fromJson({
          'page': 1,
          'pageSize': 50,
          'hasMore': false,
          'items': {},
        }),
        throwsFormatException,
      );
    });
  });
}
