import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_auth/mebabl_auth.dart';

void main() {
  group('MebablLoginResponse', () {
    test('parses the backend login response', () {
      final result = MebablLoginResponse.fromJson({
        'accountId': 'account-1',
        'userId': 'user-1',
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
      });

      expect(result.accountId, 'account-1');
      expect(result.userId, 'user-1');
      expect(result.accessToken, 'access-token');
      expect(result.refreshToken, 'refresh-token');
    });

    test('rejects a response missing a required token', () {
      expect(
        () => MebablLoginResponse.fromJson({
          'accountId': 'account-1',
          'userId': 'user-1',
          'accessToken': 'access-token',
        }),
        throwsFormatException,
      );
    });
  });

  test('register response uses the same token contract as login', () {
    final result = MebablRegisterResponse.fromJson({
      'accountId': 'account-1',
      'userId': 'user-1',
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
    });

    expect(result.userId, 'user-1');
    expect(result.refreshToken, 'refresh-token');
  });

  test('parses the complete backend refresh response', () {
    final result = MebablRefreshResponse.fromJson({
      'accountId': 'account-1',
      'userId': 'user-1',
      'accessToken': 'new-access',
      'refreshToken': 'new-refresh',
    });

    expect(result.accountId, 'account-1');
    expect(result.userId, 'user-1');
    expect(result.accessToken, 'new-access');
    expect(result.refreshToken, 'new-refresh');
  });

  test('serializes registration request using backend field names', () {
    const request = MebablRegisterRequest(
      email: ' user@example.com ',
      username: ' user ',
      password: 'secret',
    );

    expect(request.toJson(), {
      'email': 'user@example.com',
      'username': 'user',
      'password': 'secret',
    });
  });

  test('parses current user and defaults absent role lists', () {
    final user = AuthUser.fromJson(
      {
        'accountId': 'account-1',
        'userId': 'user-1',
        'email': 'user@example.com',
        'username': 'user',
      },
      fallbackApplicationId: 'application-1',
    );

    expect(user.applicationId, 'application-1');
    expect(user.roles, isEmpty);
    expect(user.permissions, isEmpty);
    expect(user.hasRole('Owner'), isFalse);
  });

  test('parses roles and permissions without empty entries', () {
    final user = AuthUser.fromJson({
      'accountId': 'account-1',
      'userId': 'user-1',
      'applicationId': 'application-1',
      'roles': ['Owner', '', null, 'Admin'],
      'permissions': ['live.view', '  ', 'live.publish'],
    });

    expect(user.roles, ['Owner', 'Admin']);
    expect(user.permissions, ['live.view', 'live.publish']);
    expect(user.hasPermission('live.publish'), isTrue);
  });
}
