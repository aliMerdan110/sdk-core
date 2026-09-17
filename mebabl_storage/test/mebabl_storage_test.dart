import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_storage/mebabl_storage.dart';

void main() {
  group('StorageFile', () {
    test('creates model from json', () {
      final file = StorageFile.fromJson({
        'id': 'file-1',
        'name': 'photo',
        'path': 'images',
        'contentType': 'image/jpeg',
        'size': 1024,
        'isPublic': true,
        'createdAt': '2026-09-17T00:00:00Z',
      });

      expect(file.id, 'file-1');
      expect(file.name, 'photo');
      expect(file.path, 'images');
      expect(file.contentType, 'image/jpeg');
      expect(file.size, 1024);
      expect(file.isPublic, true);
      expect(file.createdAt, isNotNull);
    });

    test('serializes model to json', () {
      final file = StorageFile(
        id: 'file-1',
        name: 'photo',
        path: 'images',
        contentType: 'image/jpeg',
        size: 1024,
        isPublic: false,
      );

      final json = file.toJson();

      expect(json['id'], 'file-1');
      expect(json['name'], 'photo');
      expect(json['path'], 'images');
      expect(json['contentType'], 'image/jpeg');
      expect(json['size'], 1024);
      expect(json['isPublic'], false);
    });
  });

  group('Uint8List', () {
    test('creates binary content', () {
      final bytes = Uint8List.fromList([1, 2, 3]);

      expect(bytes.length, 3);
      expect(bytes[0], 1);
      expect(bytes[1], 2);
      expect(bytes[2], 3);
    });
  });
}