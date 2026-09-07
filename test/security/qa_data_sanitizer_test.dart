import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';
import 'package:qa_inspector/src/security/qa_data_sanitizer.dart';

void main() {
  group('QaDataSanitizer bodies', () {
    test('masks every default sensitive key regardless of value type', () {
      final sanitizer = QaDataSanitizer();
      final input = <String, Object?>{
        'password': 'password-value',
        'passcode': 1234,
        'pin': 4321,
        'otp': true,
        'token': null,
        'accessToken': 'access-token-value',
        'access_token': 'access-token-snake-value',
        'refreshToken': 'refresh-token-value',
        'refresh_token': 'refresh-token-snake-value',
        'idToken': 'id-token-value',
        'id_token': 'id-token-snake-value',
        'secret': 'secret-value',
        'clientSecret': 'client-secret-value',
        'client_secret': 'client-secret-snake-value',
        'sessionId': 'session-value',
        'session_id': 'session-snake-value',
        'enabled': true,
        'empty': null,
      };

      final result = sanitizer.sanitizeBody(input) as Map<Object?, Object?>;

      for (final key in input.keys.where(
        (key) => key != 'enabled' && key != 'empty',
      )) {
        expect(result[key], QaDataSanitizer.mask, reason: key);
      }
      expect(result['enabled'], isTrue);
      expect(result['empty'], isNull);
    });

    test('merges custom keys with defaults', () {
      final sanitizer = QaDataSanitizer(
        config: QaDataSanitizationConfig(
          sensitiveKeys: const <String>{'accountNumber'},
        ),
      );

      expect(
        sanitizer.sanitizeBody(<String, String>{
          'password': 'password-value',
          'accountNumber': 'account-value',
        }),
        <Object?, Object?>{'password': '***', 'accountNumber': '***'},
      );
    });

    test('can disable default keys explicitly', () {
      final sanitizer = QaDataSanitizer(
        config: QaDataSanitizationConfig(
          sensitiveKeys: const <String>{'accountNumber'},
          includeDefaultSensitiveKeys: false,
        ),
      );

      expect(
        sanitizer.sanitizeBody(<String, String>{
          'password': 'visible-value',
          'accountNumber': 'account-value',
        }),
        <Object?, Object?>{'password': 'visible-value', 'accountNumber': '***'},
      );
    });

    test('matches case-insensitively but only by exact normalized key', () {
      final sanitizer = QaDataSanitizer();

      expect(
        sanitizer.sanitizeBody(<String, String>{
          ' PASSWORD ': 'password-value',
          'Pin': 'pin-value',
          'pinCodeEnabled': 'unchanged',
          'shippingAddress': 'unchanged',
          'spinnerValue': 'unchanged',
        }),
        <Object?, Object?>{
          ' PASSWORD ': '***',
          'Pin': '***',
          'pinCodeEnabled': 'unchanged',
          'shippingAddress': 'unchanged',
          'spinnerValue': 'unchanged',
        },
      );
    });

    test('sanitizes deeply nested request and response structures', () {
      final sanitizer = QaDataSanitizer(
        config: QaDataSanitizationConfig(
          sensitiveKeys: const <String>{'cardNumber'},
        ),
      );
      final request = <String, Object?>{
        'credentials': <String, Object?>{
          'password': 'password-value',
          'challenges': <Object?>[
            <String, Object?>{'otp': 123456},
          ],
        },
      };
      final response = <Object?>[
        <String, Object?>{
          'accounts': <Object?>[
            <String, Object?>{'cardNumber': 'card-value'},
          ],
        },
      ];

      expect(sanitizer.sanitizeBody(request), <Object?, Object?>{
        'credentials': <Object?, Object?>{
          'password': '***',
          'challenges': <Object?>[
            <Object?, Object?>{'otp': '***'},
          ],
        },
      });
      expect(sanitizer.sanitizeBody(response), <Object?>[
        <Object?, Object?>{
          'accounts': <Object?>[
            <Object?, Object?>{'cardNumber': '***'},
          ],
        },
      ]);
    });

    test('does not mutate original maps or lists', () {
      final sanitizer = QaDataSanitizer();
      final nested = <String, Object?>{'otp': 'otp-value'};
      final list = <Object?>[nested, 'unchanged'];
      final original = <String, Object?>{'items': list};

      final result = sanitizer.sanitizeBody(original) as Map<Object?, Object?>;

      expect(nested['otp'], 'otp-value');
      expect(list, <Object?>[nested, 'unchanged']);
      expect(original['items'], same(list));
      expect(result, isNot(same(original)));
      expect(result['items'], isNot(same(list)));
    });

    test('omits binary and unsupported values without string conversion', () {
      final sanitizer = QaDataSanitizer();
      final unsupported = _UnsupportedValue();

      expect(
        sanitizer.sanitizeBody(<String, Object?>{
          'bytes': Uint8List.fromList(<int>[1, 2, 3]),
          'unsupported': unsupported,
        }),
        <Object?, Object?>{
          'bytes': QaDataSanitizer.binaryContent,
          'unsupported': QaDataSanitizer.unsupportedContent,
        },
      );
      expect(unsupported.wasConvertedToString, isFalse);
    });

    test('fails closed when traversing malformed data throws', () {
      final result = QaDataSanitizer().sanitizeBody(_ThrowingMap());

      expect(result, QaDataSanitizer.sanitizationFailed);
      expect(result, isNot(contains('raw-secret-value')));
    });

    test('omits circular references', () {
      final circular = <String, Object?>{'name': 'safe'};
      circular['self'] = circular;

      expect(QaDataSanitizer().sanitizeBody(circular), <Object?, Object?>{
        'name': 'safe',
        'self': QaDataSanitizer.circularReference,
      });
    });

    test('limits excessive recursion', () {
      Object? value = 'leaf';
      for (var index = 0; index < 70; index++) {
        value = <Object?>[value];
      }

      expect(
        _containsValue(
          QaDataSanitizer().sanitizeBody(value),
          QaDataSanitizer.recursionLimit,
        ),
        isTrue,
      );
    });
  });

  group('QaDataSanitizer headers', () {
    test('masks default headers case-insensitively and preserves names', () {
      final headers = <String, Object?>{
        'Authorization': 'Bearer authorization-value',
        'PROXY-AUTHORIZATION': 'proxy-value',
        'Cookie': 'cookie-value',
        'Set-Cookie': <String>['first-cookie', 'second-cookie'],
        'X-API-KEY': 1234,
        'api-key': false,
        'Content-Type': 'application/json',
      };

      expect(QaDataSanitizer().sanitizeHeaders(headers), <Object?, Object?>{
        'Authorization': '***',
        'PROXY-AUTHORIZATION': '***',
        'Cookie': '***',
        'Set-Cookie': '***',
        'X-API-KEY': '***',
        'api-key': '***',
        'Content-Type': 'application/json',
      });
      expect(headers['Authorization'], 'Bearer authorization-value');
    });

    test('merges custom headers with defaults', () {
      final sanitizer = QaDataSanitizer(
        config: QaDataSanitizationConfig(
          sensitiveHeaders: const <String>{'x-device-token'},
        ),
      );

      expect(
        sanitizer.sanitizeHeaders(<String, String>{
          'Authorization': 'authorization-value',
          'X-Device-Token': 'device-value',
        }),
        <Object?, Object?>{'Authorization': '***', 'X-Device-Token': '***'},
      );
    });

    test('can disable default headers explicitly', () {
      final sanitizer = QaDataSanitizer(
        config: QaDataSanitizationConfig(
          sensitiveHeaders: const <String>{'x-device-token'},
          includeDefaultSensitiveHeaders: false,
        ),
      );

      expect(
        sanitizer.sanitizeHeaders(<String, String>{
          'Authorization': 'visible-value',
          'X-Device-Token': 'device-value',
        }),
        <Object?, Object?>{
          'Authorization': 'visible-value',
          'X-Device-Token': '***',
        },
      );
    });
  });

  group('QaDataSanitizer query data', () {
    test('sanitizes query parameter maps including lists', () {
      final query = <String, Object?>{
        'OTP': <String>['first-otp', 'second-otp'],
        'lang': 'en',
      };

      expect(
        QaDataSanitizer().sanitizeQueryParameters(query),
        <Object?, Object?>{'OTP': '***', 'lang': 'en'},
      );
      expect(query['OTP'], <String>['first-otp', 'second-otp']);
    });

    test('sanitizes URL query values including repeated parameters', () {
      final result = QaDataSanitizer().sanitizeUrl(
        'https://api.example.com/verify?otp=123456&otp=654321&lang=en',
      );
      final uri = Uri.parse(result);

      expect(uri.queryParametersAll['otp'], <String>['***', '***']);
      expect(uri.queryParameters['lang'], 'en');
      expect(result, isNot(contains('123456')));
      expect(result, isNot(contains('654321')));
    });

    test('returns URLs without query parameters unchanged', () {
      const url = 'https://api.example.com/verify#details';

      expect(QaDataSanitizer().sanitizeUrl(url), url);
    });
  });

  test('configuration defensively copies custom name sets', () {
    final keys = <String>{'accountNumber'};
    final headers = <String>{'x-device-token'};
    final config = QaDataSanitizationConfig(
      sensitiveKeys: keys,
      sensitiveHeaders: headers,
    );
    keys.add('laterKey');
    headers.add('later-header');

    expect(config.sensitiveKeys, <String>{'accountNumber'});
    expect(config.sensitiveHeaders, <String>{'x-device-token'});
    expect(() => config.sensitiveKeys.add('blocked'), throwsUnsupportedError);
  });
}

bool _containsValue(Object? value, Object expected) {
  if (value == expected) {
    return true;
  }
  if (value is Map) {
    return value.values.any((item) => _containsValue(item, expected));
  }
  if (value is List) {
    return value.any((item) => _containsValue(item, expected));
  }
  return false;
}

final class _UnsupportedValue {
  bool wasConvertedToString = false;

  @override
  String toString() {
    wasConvertedToString = true;
    return 'raw-unsupported-value';
  }
}

final class _ThrowingMap extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) => 'raw-secret-value';

  @override
  void operator []=(String key, Object? value) => throw UnsupportedError('');

  @override
  void clear() => throw UnsupportedError('');

  @override
  Iterable<String> get keys => throw StateError('malformed map');

  @override
  Object? remove(Object? key) => throw UnsupportedError('');
}
