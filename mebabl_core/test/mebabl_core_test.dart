import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_core/mebabl_core.dart';

void main() {
  group('MebablConfig', () {
    test('creates configuration from valid JSON', () {
      final config = MebablConfig.fromJson({
        'applicationId': 'application-id',
        'platformId': 'platform-id',
        'platform': 'flutter',
        'apiKey': 'api-key',
        'apiSecret': 'api-secret',
        'baseUrl': 'https://api.example.com',
      });

      expect(config.applicationId, 'application-id');
      expect(config.platformId, 'platform-id');
      expect(config.platform, 'flutter');
      expect(config.apiKey, 'api-key');
      expect(config.apiSecret, 'api-secret');
      expect(config.baseUrl, 'https://api.example.com');
    });

    test('throws when apiSecret is missing', () {
      expect(
        () => MebablConfig.fromJson({
          'applicationId': 'application-id',
          'platformId': 'platform-id',
          'platform': 'flutter',
          'apiKey': 'api-key',
          'baseUrl': 'https://api.example.com',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('serializes apiSecret correctly', () {
      const config = MebablConfig(
        applicationId: 'application-id',
        platformId: 'platform-id',
        platform: 'flutter',
        apiKey: 'api-key',
        apiSecret: 'api-secret',
        baseUrl: 'https://api.example.com',
      );

      final json = config.toJson();

      expect(json['applicationId'], 'application-id');
      expect(json['platformId'], 'platform-id');
      expect(json['platform'], 'flutter');
      expect(json['apiKey'], 'api-key');
      expect(json['apiSecret'], 'api-secret');
      expect(json['baseUrl'], 'https://api.example.com');
    });

    test('copyWith preserves existing values', () {
      const config = MebablConfig(
        applicationId: 'application-id',
        platformId: 'platform-id',
        platform: 'flutter',
        apiKey: 'api-key',
        apiSecret: 'api-secret',
        baseUrl: 'https://api.example.com',
      );

      final updated = config.copyWith(
        platform: 'android',
      );

      expect(updated.applicationId, 'application-id');
      expect(updated.platformId, 'platform-id');
      expect(updated.platform, 'android');
      expect(updated.apiKey, 'api-key');
      expect(updated.apiSecret, 'api-secret');
      expect(updated.baseUrl, 'https://api.example.com');
    });
  });

  group('MebablException', () {
    test('returns readable message without status code', () {
      const exception = MebablException(
        message: 'Authentication failed.',
      );

      expect(
        exception.toString(),
        'MebablException: Authentication failed.',
      );
    });

    test('returns readable message with status code', () {
      const exception = MebablException(
        message: 'Unauthorized.',
        statusCode: 401,
      );

      expect(
        exception.toString(),
        'MebablException [401]: Unauthorized.',
      );
    });

    test('identifies common HTTP status codes', () {
      const unauthorized = MebablException(
        message: 'Unauthorized.',
        statusCode: 401,
      );

      const forbidden = MebablException(
        message: 'Forbidden.',
        statusCode: 403,
      );

      const notFound = MebablException(
        message: 'Not found.',
        statusCode: 404,
      );

      const serverError = MebablException(
        message: 'Server error.',
        statusCode: 500,
      );

      expect(unauthorized.isUnauthorized, isTrue);
      expect(unauthorized.isValidationError, isFalse);

      expect(forbidden.isForbidden, isTrue);
      expect(notFound.isNotFound, isTrue);
      expect(serverError.isServerError, isTrue);
    });

    test('identifies network errors', () {
      const exception = MebablException(
        message: 'Network connection failed.',
      );

      expect(exception.isNetworkError, isTrue);
    });
  });
}
