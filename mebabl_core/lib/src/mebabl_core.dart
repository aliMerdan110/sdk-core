import 'dart:convert';

import 'package:flutter/services.dart';

import 'auth/token_storage.dart';
import 'client/mebabl_http_client.dart';
import 'config/mebabl_config.dart';

class MebablCore {
  static MebablCore? _instance;

  final MebablConfig config;
  final MebablTokenStorage tokenStorage;
  final MebablHttpClient http;

  MebablCore._({
    required this.config,
    required this.tokenStorage,
    required this.http,
  });

  static MebablCore get instance {
    final instance = _instance;

    if (instance == null) {
      throw StateError(
        'MebablCore has not been initialized. '
        'Call await MebablCore.initialize() first.',
      );
    }

    return instance;
  }

  static bool get isInitialized => _instance != null;

  static Future<void> initialize({
    String assetPath = 'assets/mebabl.json',
  }) async {
    if (_instance != null) {
      return;
    }

    // ------------------------------------------------------------
    // 1. Load mebabl.json
    // ------------------------------------------------------------

    final jsonString = await rootBundle.loadString(assetPath);

    final jsonMap = jsonDecode(jsonString);

    if (jsonMap is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid mebabl.json format.',
      );
    }

    // ------------------------------------------------------------
    // 2. Validate required configuration
    // ------------------------------------------------------------

    const requiredFields = [
      'applicationId',
      'platformId',
      'platform',
      'apiKey',
      'baseUrl',
    ];

    for (final field in requiredFields) {
      final value = jsonMap[field];

      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Invalid configuration: "$field" is missing.',
        );
      }
    }

    // ------------------------------------------------------------
    // 3. Create MebablConfig
    // ------------------------------------------------------------

    final config = MebablConfig.fromJson(jsonMap);

    // ------------------------------------------------------------
    // 4. Create token storage
    // ------------------------------------------------------------

    final tokenStorage = MebablTokenStorage();

    // ------------------------------------------------------------
    // 5. Create HTTP client
    // ------------------------------------------------------------

    final http = MebablHttpClient(
      config: config,
      tokenStorage: tokenStorage,
    );

    // ------------------------------------------------------------
    // 6. Create Core instance
    // ------------------------------------------------------------

    _instance = MebablCore._(
      config: config,
      tokenStorage: tokenStorage,
      http: http,
    );
  }
}
