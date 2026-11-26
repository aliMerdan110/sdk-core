import 'json_helpers.dart';

class MebablNotificationQuietHours {
  final bool isEnabled;
  final String timeZoneId;
  final String startTime;
  final String endTime;
  final int daysOfWeekMask;
  final bool allowHighPriority;

  const MebablNotificationQuietHours({
    required this.isEnabled,
    required this.timeZoneId,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeekMask,
    required this.allowHighPriority,
  });

  factory MebablNotificationQuietHours.fromJson(Map<String, dynamic> json) {
    return MebablNotificationQuietHours(
      isEnabled: json['isEnabled'] == true,
      timeZoneId: requiredString(json, 'timeZoneId'),
      startTime: requiredString(json, 'startTime'),
      endTime: requiredString(json, 'endTime'),
      daysOfWeekMask: intValue(json['daysOfWeekMask']),
      allowHighPriority: json['allowHighPriority'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'timeZoneId': timeZoneId,
        'startTime': startTime,
        'endTime': endTime,
        'daysOfWeekMask': daysOfWeekMask,
        'allowHighPriority': allowHighPriority,
      };
}
