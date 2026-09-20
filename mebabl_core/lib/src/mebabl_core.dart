// lib/src/mebabl_core.dart

import 'dart:convert';

import 'package:flutter/services.dart';

import 'auth/token_storage.dart';
import 'client/interceptors/mebabl_auth_interceptor.dart';
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

  static Future<MebablCore> initialize({
    String assetPath = 'assets/mebabl.json',
  }) async {
    final existing = _instance;

    if (existing != null) {
      return existing;
    }

    final jsonString = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid mebabl.json format.',
      );
    }

    final config = MebablConfig.fromJson(decoded);
    final tokenStorage = MebablTokenStorage();

    final http = MebablHttpClient(
      config: config,
      tokenStorage: tokenStorage,
    );

    final instance = MebablCore._(
      config: config,
      tokenStorage: tokenStorage,
      http: http,
    );

    _instance = instance;

    return instance;
  }

  static void reset() {
    _instance = null;
  }

  void addAuthInterceptor({
    required Future<String?> Function() getValidAccessToken,
  }) {
    http.addInterceptor(
      MebablAuthInterceptor(
        getValidAccessToken: getValidAccessToken,
      ),
    );
  }
}
