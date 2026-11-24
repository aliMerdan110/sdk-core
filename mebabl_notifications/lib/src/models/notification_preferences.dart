import 'json_helpers.dart';

/// One server-defined notification category preference.
class MebablNotificationPreference {
  final String category;
  final bool pushEnabled;
  final DateTime? mutedUntilUtc;
  final bool isCustomized;

  const MebablNotificationPreference({
    required this.category,
    required this.pushEnabled,
    this.mutedUntilUtc,
    this.isCustomized = false,
  });

  factory MebablNotificationPreference.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    if (category is! String || category.trim().isEmpty) {
      throw const FormatException('Expected a notification preference category.');
    }
    final pushEnabled = json['pushEnabled'];
    if (pushEnabled is! bool) {
      throw const FormatException('Expected pushEnabled to be a boolean.');
    }
    return MebablNotificationPreference(
      category: category,
      pushEnabled: pushEnabled,
      mutedUntilUtc: optionalDateTime(json['mutedUntilUtc'] ?? json['mutedUntil']),
      isCustomized: json['isCustomized'] == true,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'category': category,
        'pushEnabled': pushEnabled,
        'mutedUntil': mutedUntilUtc?.toUtc().toIso8601String(),
      };
}

/// Collection returned by GET/PUT `/api/sdk/notifications/preferences`.
class MebablNotificationPreferences {
  final List<MebablNotificationPreference> categories;

  MebablNotificationPreferences({
    required Iterable<MebablNotificationPreference> categories,
  }) : categories = List.unmodifiable(categories);

  factory MebablNotificationPreferences.fromJson(Object? value) {
    Object? raw = value;
    if (value is Map) {
      raw = value['preferences'] ?? value['items'] ?? value['data'];
    }
    if (raw is! List) {
      throw const FormatException('Expected notification preferences to be an array.');
    }
    return MebablNotificationPreferences(
      categories: raw
          .map((item) => MebablNotificationPreference.fromJson(asJsonMap(item, 'notification preference')))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'preferences': categories.map((item) => item.toUpdateJson()).toList(growable: false),
      };

  MebablNotificationPreferences copyWith({
    Iterable<MebablNotificationPreference>? categories,
  }) =>
      MebablNotificationPreferences(categories: categories ?? this.categories);
}
