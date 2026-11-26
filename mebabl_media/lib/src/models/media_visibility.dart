/// Visibility requested when uploading or updating a media asset.
enum MebablMediaVisibility { private, public, unlisted }

extension MebablMediaVisibilityValue on MebablMediaVisibility {
  /// Text value expected by the multipart upload form field.
  String get formValue => switch (this) {
    MebablMediaVisibility.private => 'Private',
    MebablMediaVisibility.public => 'Public',
    MebablMediaVisibility.unlisted => 'Unlisted',
  };

  /// Numeric JSON value expected by ASP.NET Core's default enum serializer.
  /// These values are fixed by the backend's persisted MediaVisibility enum.
  int get jsonValue => switch (this) {
    MebablMediaVisibility.private => 1,
    MebablMediaVisibility.public => 2,
    MebablMediaVisibility.unlisted => 3,
  };

  /// Backwards-compatible alias for [formValue].
  @Deprecated('Use formValue for multipart requests or jsonValue for JSON.')
  String get apiValue => formValue;
}
