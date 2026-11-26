/// Preserves an enum value exactly as returned by the API.
///
/// ASP.NET Core's default JSON configuration serializes enums as integers.
/// This wrapper also accepts string values for compatibility with APIs that
/// opt into JsonStringEnumConverter. Use the typed model getters for known
/// MediaKind, MediaVisibility, MediaProcessingStatus, and MediaVariantKind
/// values because each enum has its own numeric mapping.
class MebablMediaEnumValue {
  final Object? rawValue;

  const MebablMediaEnumValue._(this.rawValue);

  factory MebablMediaEnumValue.fromJson(Object? value) {
    if (value is String || value is num) {
      return MebablMediaEnumValue._(value);
    }
    return MebablMediaEnumValue._(value?.toString());
  }

  /// Returns the enum name when the server uses string enum serialization.
  String? get name => rawValue is String ? rawValue as String : null;

  /// Returns the numeric enum value when the server uses numeric serialization.
  int? get numericValue {
    if (rawValue is num) return (rawValue as num).toInt();
    return int.tryParse(rawValue?.toString() ?? '');
  }

  /// Compares a string enum name without depending on letter casing.
  bool isNamed(String expectedName) {
    final current = name;
    return current != null &&
        current.toLowerCase() == expectedName.toLowerCase();
  }

  /// Matches either a named JSON enum or the backend's numeric enum value.
  bool matches(String expectedName, int expectedNumericValue) =>
      isNamed(expectedName) || numericValue == expectedNumericValue;

  @override
  String toString() => rawValue?.toString() ?? '';
}
