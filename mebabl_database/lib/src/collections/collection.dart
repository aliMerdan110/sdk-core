/// A collection owned by a Mebabl project.
///
/// Collections are project-scoped resources. Applications registered under
/// the same project share the collection, subject to the collection's
/// published database security policy.
class Collection {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Collection({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: _requiredString(json, 'id'),
      projectId: _requiredString(json, 'projectId'),
      name: _requiredString(json, 'name'),
      description: _optionalString(json, 'description'),
      isActive: _optionalBool(json, 'isActive', defaultValue: true),
      createdAt: _requiredDateTime(json, 'createdAt'),
      updatedAt: _optionalDateTime(json, 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Collection.$key must be a non-empty string.');
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Collection.$key must be a string or null.');
    }
    return value;
  }

  static bool _optionalBool(
    Map<String, dynamic> json,
    String key, {
    required bool defaultValue,
  }) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is! bool) {
      throw FormatException('Collection.$key must be a boolean.');
    }
    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Collection.$key must be an ISO-8601 string.');
    }
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('Collection.$key is not a valid date/time.');
    }
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Collection.$key must be a date/time string or null.',
      );
    }
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('Collection.$key is not a valid date/time.');
    }
  }
}
