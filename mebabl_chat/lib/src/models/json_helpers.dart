String requiredString(Map<String, dynamic> json, String key, {String? alias}) {
  final value = json[key] ?? (alias == null ? null : json[alias]);
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Expected "$key" to be a non-empty string.');
}

String? optionalString(Map<String, dynamic> json, String key, {String? alias}) {
  final value = json[key] ?? (alias == null ? null : json[alias]);
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected "$key" to be a string or null.');
}

int intValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? optionalDateTime(dynamic value, {String? field}) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.parse(value).toUtc();
  throw FormatException('Expected "${field ?? 'date'}" to be an ISO-8601 string or null.');
}

DateTime requiredDateTime(Map<String, dynamic> json, String key) {
  final value = optionalDateTime(json[key], field: key);
  if (value == null) {
    throw FormatException('Expected "$key" to be an ISO-8601 string.');
  }
  return value;
}

Map<String, dynamic> asJsonMap(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected $name to be a JSON object.');
}

List<Map<String, dynamic>> asJsonMapList(Object? value, String name) {
  if (value is! List) throw FormatException('Expected $name to be a JSON array.');
  return value.map((item) => asJsonMap(item, name)).toList(growable: false);
}

List<Map<String, dynamic>> readItems(Object? value, String name) {
  if (value is List) return asJsonMapList(value, name);
  final map = asJsonMap(value, name);
  final items = map['items'] ?? map['messages'] ?? map['conversations'] ?? map['forwardedMessages'] ?? map['data'];
  if (items is List) return asJsonMapList(items, name);
  throw FormatException('Expected $name to contain an items array.');
}
