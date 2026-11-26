import 'json_helpers.dart';

class MebablChatParticipant {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final DateTime? joinedAtUtc;
  final DateTime? leftAtUtc;
  final int lastDeliveredSequence;
  final int lastReadSequence;
  final bool? isOnline;

  const MebablChatParticipant({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.role = 'member',
    this.joinedAtUtc,
    this.leftAtUtc,
    this.lastDeliveredSequence = 0,
    this.lastReadSequence = 0,
    this.isOnline,
  });

  factory MebablChatParticipant.fromJson(Map<String, dynamic> json) {
    final isAdmin = json['isAdmin'] == true;
    return MebablChatParticipant(
      userId: requiredString(json, 'userId'),
      displayName: optionalString(json, 'displayName') ?? optionalString(json, 'name'),
      avatarUrl: optionalString(json, 'avatarUrl'),
      role: optionalString(json, 'role') ?? (isAdmin ? 'admin' : 'member'),
      joinedAtUtc: optionalDateTime(json['joinedAtUtc'] ?? json['joinedAt']),
      leftAtUtc: optionalDateTime(json['leftAtUtc'] ?? json['leftAt']),
      lastDeliveredSequence: intValue(json['lastDeliveredSequence']),
      lastReadSequence: intValue(json['lastReadSequence']),
      isOnline: json['isOnline'] is bool ? json['isOnline'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'role': role,
        'joinedAtUtc': joinedAtUtc?.toIso8601String(),
        'leftAtUtc': leftAtUtc?.toIso8601String(),
        'lastDeliveredSequence': lastDeliveredSequence,
        'lastReadSequence': lastReadSequence,
        'isOnline': isOnline,
      };
}
