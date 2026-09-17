import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mebabl_core/mebabl_core.dart';

import 'storage_file.dart';

class MebablStorageService {
  final MebablCore core;

  MebablStorageService({
    required this.core,
  });

  Future<StorageFile> upload({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String path = '',
    bool isPublic = false,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
      'path': path,
      'isPublic': isPublic,
    });

    final response = await core.http.postMultipart<Map<String, dynamic>>(
      '/api/sdk/storage/upload',
      data: formData,
    );

    return StorageFile.fromJson(response.data!);
  }

  Future<String> getUrl(String fileId) async {
    final response = await core.http.get<Map<String, dynamic>>(
      '/api/sdk/storage/$fileId/url',
    );

    return response.data!['url'] as String;
  }

  Future<void> delete(String fileId) async {
    await core.http.delete(
      '/api/sdk/storage/$fileId',
    );
  }
}
