import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_core/mebabl_core.dart';

void main() {
  group('MebablException', () {
    test('classifies HTTP errors by status code', () {
      expect(
        const MebablException(message: 'Unauthorized', statusCode: 401)
            .isUnauthorized,
        isTrue,
      );
      expect(
        const MebablException(message: 'Conflict', statusCode: 409).isConflict,
        isTrue,
      );
      expect(
        const MebablException(message: 'Rate limited', statusCode: 429)
            .isRateLimited,
        isTrue,
      );
    });

    test('classifies timeouts independently of message text', () {
      const exception = MebablException(
        message: 'Request timed out',
        code: 'connectionTimeout',
      );

      expect(exception.isTimeout, isTrue);
      expect(exception.isNetworkError, isTrue);
    });
  });
}
