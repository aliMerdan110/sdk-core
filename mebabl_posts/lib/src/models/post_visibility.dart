/// Audience values accepted by the Babilo Content API.
///
/// The backend serializes `PostVisibility` as its enum name, not its numeric
/// database value. Keep these wire strings stable.
abstract final class MebablPostVisibility {
  static const String public = 'Public';
  static const String followers = 'Followers';
  static const String private = 'Private';

  static const Set<String> values = {public, followers, private};

  static String validate(String value) {
    final normalized = value.trim();
    if (!values.contains(normalized)) {
      throw ArgumentError.value(
        value,
        'visibility',
        'Visibility must be Public, Followers, or Private.',
      );
    }
    return normalized;
  }
}
