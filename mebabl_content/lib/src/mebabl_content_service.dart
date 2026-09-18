import 'package:mebabl_content/models/post.dart';
import 'package:mebabl_core/mebabl_core.dart';


class MebablContentService {
  final MebablCore core;

  const MebablContentService({required this.core});

  Future<Post> createPost({String? text, List<String>? storageFileIds}) async {
    final response = await core.http.post(
      '/api/sdk/content/posts',
      data: {
        if (text != null) 'text': text,
        if (storageFileIds != null) 'storageFileIds': storageFileIds,
      },
    );

    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Post> getPost(String postId) async {
    final response = await core.http.get('/api/sdk/content/posts/$postId');

    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Post>> getPosts({int page = 1, int pageSize = 20}) async {
    final response = await core.http.get(
      '/api/sdk/content/posts',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    final data = response.data;

    final List<dynamic> items = data is List
        ? data
        : (data['items'] as List<dynamic>? ?? []);

    return items
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Post> updatePost(String postId, {String? text}) async {
    final response = await core.http.patch(
      '/api/sdk/content/posts/$postId',
      data: {'text': text},
    );

    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await core.http.delete('/api/sdk/content/posts/$postId');
  }
}
