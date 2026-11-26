/// Contract implemented by `mebabl_auth` to provide a valid user access token.
///
/// The provider may refresh the user session before returning a token. Core
/// only attaches the returned token; it does not own user authentication.
abstract interface class MebablAuthProvider {
  Future<String?> getValidAccessToken();
}
