/// A project-scoped Database collection addressed by its stable code.
///
/// The backend keeps the internal collection GUID private. Applications use
/// [code] for all collection operations, so a collection can be configured
/// before its first document is written and materialized automatically.
class Collection {
  final String code;
  final String name;
  final String description;

  const Collection({
    required this.code,
    required this.name,
    required this.description,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    final code = json['code'];
    final name = json['name'];
    final description = json['description'];

    if (code is! String || code.trim().isEmpty) {
      throw const FormatException('Collection.code must be a non-empty string.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Collection.name must be a non-empty string.');
    }
    if (description != null && description is! String) {
      throw const FormatException('Collection.description must be a string or null.');
    }

    return Collection(
      code: code,
      name: name,
      description: (description as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name,
        'description': description,
      };
}
