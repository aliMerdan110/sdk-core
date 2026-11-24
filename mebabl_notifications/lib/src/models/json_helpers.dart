String requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Expected "$key" to be a non-empty string.');
}

String? optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
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

DateTime? optionalDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.parse(value).toUtc();
  throw const FormatException('Expected a date-time string or null.');
}

Map<String, dynamic> asJsonMap(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected $name to be a JSON object.');
}

List<Map<String, dynamic>> readItems(Object? value, String name) {
  if (value is List) {
    return value.map((item) => asJsonMap(item, name)).toList(growable: false);
  }
  final json = asJsonMap(value, name);
  final raw = json['items'] ?? json['notifications'] ?? json['data'];
  if (raw is! List) throw FormatException('Expected $name to contain an items array.');
  return raw.map((item) => asJsonMap(item, name)).toList(growable: false);
}
