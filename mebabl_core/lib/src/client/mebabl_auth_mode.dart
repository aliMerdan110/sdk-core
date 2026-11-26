/// Selects which credential, if any, is attached to an HTTP request.
///
/// The default is [none]. Use [application] for endpoints protected by the
/// `ApplicationPublic` policy and [user] for endpoints protected by the
/// `ApplicationUser` policy.
enum MebablAuthMode {
  none,
  application,
  user,
}
