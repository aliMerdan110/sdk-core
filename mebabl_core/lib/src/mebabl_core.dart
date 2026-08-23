import 'auth/token_storage.dart';
import 'client/mebabl_http_client.dart';
import 'config/mebabl_config.dart';

class MebablCore {
  final MebablConfig config;
  final MebablTokenStorage tokenStorage;
  final MebablHttpClient http;

  MebablCore({
    required this.config,
    MebablTokenStorage? tokenStorage,
  })  : tokenStorage = tokenStorage ?? MebablTokenStorage(),
        http = _createHttpClient(
          config,
          tokenStorage,
        );

  static MebablHttpClient _createHttpClient(
    MebablConfig config,
    MebablTokenStorage? tokenStorage,
  ) {
    final storage = tokenStorage ?? MebablTokenStorage();

    return MebablHttpClient(
      config: config,
      tokenStorage: storage,
    );
  }
}
