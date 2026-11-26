import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_core/mebabl_core.dart';

void main() {
  group('MebablConfig', () {
    test('loads public application configuration', () {
      final config = MebablConfig.fromJson({
        'applicationId': 'app-id',
        'platformId': 'platform-id',
        'platform': 'android',
        'apiKey': 'public-key',
        'baseUrl': 'https://api.example.com/',
        'packageName': 'com.example.app',
      });

      expect(config.applicationId, 'app-id');
      expect(config.apiKey, 'public-key');
      expect(config.baseUrl, 'https://api.example.com');
      expect(config.packageName, 'com.example.app');
    });

    test('does not serialize a legacy apiSecret field', () {
      final config = MebablConfig.fromJson({
        'applicationId': 'app-id',
        'platformId': 'platform-id',
        'platform': 'android',
        'apiKey': 'public-key',
        'apiSecret': 'legacy-secret',
        'baseUrl': 'https://api.example.com',
      });

      expect(config.toJson().containsKey('apiSecret'), isFalse);
    });

    test('rejects a non-HTTP base URL', () {
      expect(
        () => MebablConfig.fromJson({
          'applicationId': 'app-id',
          'platformId': 'platform-id',
          'platform': 'android',
          'apiKey': 'public-key',
          'baseUrl': 'file:///tmp/api',
        }),
        throwsFormatException,
      );
    });

    test('rejects base URLs containing query strings', () {
      expect(
        () => MebablConfig.fromJson({
          'applicationId': 'app-id',
          'platformId': 'platform-id',
          'platform': 'android',
          'apiKey': 'public-key',
          'baseUrl': 'https://api.example.com?tenant=one',
        }),
        throwsFormatException,
      );
    });
  });
}
