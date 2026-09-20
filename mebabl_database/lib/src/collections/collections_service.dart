import 'package:mebabl_core/mebabl_core.dart';

import 'collection.dart';

class CollectionsService {
  final MebablCore core;

  CollectionsService({required this.core});

  Future<Collection> create({required String name, String? description}) async {
    _validateName(name);

    final response = await core.http.post(
      '/api/sdk/data/collections',
      data: {'name': name.trim(), 'description': description},
    );

    return Collection.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Collection> get({required String collectionId}) async {
    _validateId(collectionId);

    final response = await core.http.get(
      '/api/sdk/data/collections/$collectionId',
    );

    return Collection.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Collection>> list() async {
    final response = await core.http.get('/api/sdk/data/collections');

    final data = response.data;

    if (data is! List) {
      throw FormatException('Collections response must be a JSON array.');
    }

    return data
        .map(
          (item) => Collection.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Collection> update({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    _validateId(collectionId);
    _validateName(name);

    final response = await core.http.put(
      '/api/sdk/data/collections/$collectionId',
      data: {'name': name.trim(), 'description': description},
    );

    return Collection.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> delete({required String collectionId}) async {
    _validateId(collectionId);

    await core.http.delete('/api/sdk/data/collections/$collectionId');
  }

  void _validateId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('collectionId cannot be empty.');
    }
  }

  void _validateName(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Collection name cannot be empty.');
    }

    if (value.trim().length > 100) {
      throw ArgumentError('Collection name cannot exceed 100 characters.');
    }
  }
}
