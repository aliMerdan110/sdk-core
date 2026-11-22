import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_database/mebabl_database.dart';

void main() {
  test('Collection parses the public code-only catalog contract', () {
    final collection = Collection.fromJson({
      'code': 'user_profiles',
      'name': 'User Profiles',
      'description': 'Public profile documents',
    });

    expect(collection.code, 'user_profiles');
    expect(collection.name, 'User Profiles');
    expect(collection.description, 'Public profile documents');
    expect(collection.toJson().containsKey('id'), isFalse);
    expect(collection.toJson().containsKey('collectionId'), isFalse);
  });

  test('Collection accepts a null description', () {
    final collection = Collection.fromJson({
      'code': 'settings',
      'name': 'Settings',
      'description': null,
    });

    expect(collection.description, isEmpty);
  });

  test('Collection rejects responses that expose only an internal id', () {
    expect(
      () => Collection.fromJson({
        'id': '00000000-0000-0000-0000-000000000001',
        'name': 'Legacy',
      }),
      throwsFormatException,
    );
  });
}
