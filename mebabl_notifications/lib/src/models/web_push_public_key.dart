import 'json_helpers.dart';

class MebablWebPushPublicKey {
  final String publicKey;
  final String subject;

  const MebablWebPushPublicKey({required this.publicKey, required this.subject});

  factory MebablWebPushPublicKey.fromJson(Map<String, dynamic> json) =>
      MebablWebPushPublicKey(
        publicKey: requiredString(json, 'publicKey'),
        subject: requiredString(json, 'subject'),
      );
}
