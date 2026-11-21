import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_storage/mebabl_storage.dart';

void main() {
  group('StorageFile compatibility alias', () {
    test('supports fromJson through the legacy public name', () {
      final file = StorageFile.fromJson({
        'id': '7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124',
        'bucketId': '3c0a3c6d-9958-44ef-8d48-d4a79d9bc5ba',
        'path': 'avatars/user-1/avatar.png',
        'fileName': 'avatar.png',
        'contentType': 'image/png',
        'size': 1024,
      });

      expect(file, isA<MebablStoredFile>());
      expect(file.fileName, 'avatar.png');
      expect(file.createdAt, isNull);
    });

    test('supports direct construction through the legacy public name', () {
      final file = StorageFile(
        id: '7b59b90e-3b8e-4c3b-b42f-e9d1e06c9124',
        bucketId: '3c0a3c6d-9958-44ef-8d48-d4a79d9bc5ba',
        path: 'docs/report.pdf',
        fileName: 'report.pdf',
        contentType: 'application/pdf',
        size: 256,
      );

      expect(file.name, 'report');
      expect(file.size, 256);
    });
  });
}
