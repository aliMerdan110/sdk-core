import 'json_helpers.dart';

class MebablChatReaction {
  final String userId;
  final String reaction;
  final DateTime? createdAtUtc;

  const MebablChatReaction({
    required this.userId,
    required this.reaction,
    this.createdAtUtc,
  });

  factory MebablChatReaction.fromJson(Map<String, dynamic> json) {
    return MebablChatReaction(
      userId: requiredString(json, 'userId'),
      reaction: requiredString(json, 'reaction'),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'reaction': reaction,
        'createdAtUtc': createdAtUtc?.toIso8601String(),
      };
}
