import 'json_helpers.dart';

String _preferenceString(Object? value) => value is String ? value : '';

/// One category-specific push notification preference returned by the API.
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
    final muted = json['mutedUntilUtc'] ?? json['mutedUntil'];
    return MebablNotificationPreference(
      category: _preferenceString(json['category']),
      pushEnabled: json['pushEnabled'] == true,
      mutedUntilUtc: muted is String && muted.trim().isNotEmpty
          ? DateTime.tryParse(muted)?.toUtc()
          : null,
      isCustomized: json['isCustomized'] == true,
    );
  }

  /// The API update contract calls the timestamp field `mutedUntil`.
  Map<String, dynamic> toJson() => {
        'category': category,
        'pushEnabled': pushEnabled,
        'mutedUntil': mutedUntilUtc?.toUtc().toIso8601String(),
      };
}

/// User notification preferences grouped by backend-defined categories.
///
/// The model also retains the original global fields for backwards
/// compatibility with older SDK versions.
class MebablNotificationPreferences {
  final List<MebablNotificationPreference> categories;
  final bool? inAppEnabled;
  final bool? pushEnabled;
  final bool? emailEnabled;
  final List<String> mutedTypes;
  final Map<String, dynamic> additionalSettings;

  const MebablNotificationPreferences({
    this.categories = const [],
    this.inAppEnabled,
    this.pushEnabled,
    this.emailEnabled,
    this.mutedTypes = const [],
    this.additionalSettings = const {},
  });

  factory MebablNotificationPreferences.fromJson(Object? value) {
    if (value is List) {
      return MebablNotificationPreferences(
        categories: value
            .whereType<Map>()
            .map((item) => MebablNotificationPreference.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
      );
    }

    final json = asJsonMap(value, 'notification preferences');
    final nested = json['preferences'] ?? json['data'];
    if (nested is List) return MebablNotificationPreferences.fromJson(nested);

    final muted = json['mutedTypes'];
    const known = <String>{
      'inAppEnabled',
      'pushEnabled',
      'emailEnabled',
      'mutedTypes',
      'categories',
      'preferences',
      'data',
    };
    final rawCategories = json['categories'];
    return MebablNotificationPreferences(
      categories: rawCategories is List
          ? rawCategories
              .whereType<Map>()
              .map((item) => MebablNotificationPreference.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      inAppEnabled: json['inAppEnabled'] is bool ? json['inAppEnabled'] as bool : null,
      pushEnabled: json['pushEnabled'] is bool ? json['pushEnabled'] as bool : null,
      emailEnabled: json['emailEnabled'] is bool ? json['emailEnabled'] as bool : null,
      mutedTypes: muted is List ? muted.whereType<String>().toList(growable: false) : const [],
      additionalSettings: Map<String, dynamic>.fromEntries(
        json.entries.where((entry) => !known.contains(entry.key)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'preferences': categories.map((item) => item.toJson()).toList(growable: false),
        ...additionalSettings,
        if (inAppEnabled != null) 'inAppEnabled': inAppEnabled,
        if (pushEnabled != null) 'pushEnabled': pushEnabled,
        if (emailEnabled != null) 'emailEnabled': emailEnabled,
        if (categories.isEmpty) 'mutedTypes': mutedTypes,
      };
}
