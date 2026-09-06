import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  group('QaNetworkInterceptor', () {
    test('captures a successful GET with sanitized request and response data', () async {
      final controller = _controller();
      final adapter = _FakeAdapter((options) {
        expect(options.extra['application-value'], 'preserved');
        return _jsonResponse(
          <String, Object?>{
            'accessToken': 'response-token',
            'result': true,
          },
          headers: <String, List<String>>{
            'content-type': <String>['application/json'],
            'set-cookie': <String>['response-cookie'],
          },
        );
      });
      final dio = _dio(controller, adapter: adapter);

      final response = await dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: <String, Object?>{
          'otp': 'query-secret',
          'page': 2,
        },
        options: Options(
          headers: <String, Object?>{
            'Authorization': 'Bearer request-token',
            'X-Trace': 'trace-value',
          },
          extra: <String, Object?>{'application-value': 'preserved'},
        ),
      );

      expect(response.data?['accessToken'], 'response-token');
      final event = controller.events.single as QaNetworkEvent;
      expect(event.method, 'GET');
      expect(event.path, '/users');
      expect(event.statusCode, 200);
      expect(event.outcome, QaNetworkOutcome.success);
      expect(event.error, isNull);
      expect(event.timestamp, event.startedAt);
      expect(event.completedAt.isBefore(event.startedAt), isFalse);
      expect(event.duration, event.completedAt.difference(event.startedAt));
      expect(event.url, isNot(contains('query-secret')));
      expect(_map(event.queryParameters)['otp'], '***');
      expect(_map(event.requestHeaders)['Authorization'], '***');
      expect(_map(event.requestHeaders)['X-Trace'], 'trace-value');
      expect(_map(event.responseHeaders)['set-cookie'], '***');
      expect(_map(event.responseBody.data)['accessToken'], '***');
      controller.dispose();
    });

    test('captures POST bodies without mutating application values', () async {
      final controller = _controller();
      final request = <String, Object?>{
        'name': 'QA',
        'password': 'request-password',
        'nested': <String, Object?>{'pin': 1234},
      };
      final backendBody = <String, Object?>{
        'ok': true,
        'refresh_token': 'response-refresh-token',
      };
      final dio = _dio(
        controller,
        adapter: _FakeAdapter((_) => _jsonResponse(backendBody)),
      );

      final response = await dio.post<Map<String, dynamic>>('/submit', data: request);

      expect(request['password'], 'request-password');
      expect((request['nested'] as Map<String, Object?>)['pin'], 1234);
      expect(response.data?['refresh_token'], 'response-refresh-token');
      final event = controller.events.single as QaNetworkEvent;
      expect(_map(event.requestBody.data)['password'], '***');
      expect(_map(_map(event.requestBody.data)['nested'])['pin'], '***');
      expect(_map(event.responseBody.data)['refresh_token'], '***');
      controller.dispose();
    });

    test('uses custom sensitive keys everywhere and stores no raw secrets', () async {
      final controller = _controller();
      final dio = _dio(
        controller,
        config: QaDataSanitizationConfig(
          sensitiveKeys: const <String>{'cardNumber'},
          sensitiveHeaders: const <String>{'x-customer-token'},
        ),
        adapter: _FakeAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'cardNumber': 'response-card-secret',
            'password': 'response-password-secret',
          }),
        ),
      );

      await dio.post<Map<String, dynamic>>(
        '/secure',
        queryParameters: <String, Object?>{'cardNumber': 'query-card-secret'},
        data: <String, Object?>{
          'cardNumber': 'request-card-secret',
          'otp': 'request-otp-secret',
        },
        options: Options(
          headers: <String, Object?>{
            'Authorization': 'authorization-secret',
            'x-customer-token': 'customer-header-secret',
          },
        ),
      );

      final event = controller.events.single as QaNetworkEvent;
      final representation = <Object?>[
        event.url,
        event.queryParameters,
        event.requestHeaders,
        event.requestBody.data,
        event.responseHeaders,
        event.responseBody.data,
        event.error?.message,
      ].toString();
      for (final secret in <String>[
        'response-card-secret',
        'response-password-secret',
        'query-card-secret',
        'request-card-secret',
        'request-otp-secret',
        'authorization-secret',
        'customer-header-secret',
      ]) {
        expect(representation, isNot(contains(secret)), reason: secret);
      }
      controller.dispose();
    });

    test('captures failed response data and preserves original DioException', () async {
      final controller = _controller();
      final dio = _dio(
        controller,
        adapter: _FakeAdapter(
          (_) => _jsonResponse(
            <String, Object?>{
              'error': 'invalid',
              'token': 'failure-token',
            },
            statusCode: 422,
            headers: <String, List<String>>{
              'content-type': <String>['application/json'],
            },
          ),
        ),
      );

      DioException? caught;
      try {
        await dio.get<void>('/failure');
      } on DioException catch (error) {
        caught = error;
      }

      expect(caught, isNotNull);
      expect(caught?.response?.statusCode, 422);
      final event = controller.events.single as QaNetworkEvent;
      expect(event.statusCode, 422);
      expect(event.outcome, QaNetworkOutcome.failure);
      expect(event.error?.type, DioExceptionType.badResponse.name);
      expect(_map(event.responseBody.data)['error'], 'invalid');
      expect(_map(event.responseBody.data)['token'], '***');
      controller.dispose();
    });

    test('marks cancellation and leaves cancellation behavior unchanged', () async {
      final controller = _controller();
      final completer = Completer<ResponseBody>();
      final dio = _dio(
        controller,
        adapter: _FakeAdapter((_) => completer.future),
      );
      final token = CancelToken();
      final request = dio.get<void>('/cancel', cancelToken: token);
      token.cancel('host cancellation');

      await expectLater(
        request,
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      final event = controller.events.single as QaNetworkEvent;
      expect(event.outcome, QaNetworkOutcome.cancelled);
      expect(event.error?.message, 'Request cancelled');
      controller.dispose();
    });

    test('retains the request-start route across navigation changes', () async {
      final controller = _controller();
      final observer = QaRouteObserver(controller: controller);
      observer.didPush(_route('/transfer'), null);
      controller.clearEvents();
      final completer = Completer<ResponseBody>();
      final dio = _dio(controller, adapter: _FakeAdapter((_) => completer.future));

      final request = dio.post<void>('/validate');
      await Future<void>.delayed(Duration.zero);
      observer.didPush(_route('/confirm'), _route('/transfer'));
      completer.complete(_jsonResponse(<String, Object?>{'ok': true}));
      await request;

      final event = controller.events.whereType<QaNetworkEvent>().single;
      expect(controller.currentRoute, '/confirm');
      expect(event.route, '/transfer');
      controller.dispose();
    });

    test('handles parallel requests and identifies request-start chronology', () async {
      final controller = _controller();
      final first = Completer<ResponseBody>();
      final second = Completer<ResponseBody>();
      final dio = _dio(
        controller,
        adapter: _FakeAdapter(
          (options) => options.path.endsWith('/first') ? first.future : second.future,
        ),
      );

      final firstRequest = dio.get<void>('/first');
      await Future<void>.delayed(Duration.zero);
      final secondRequest = dio.get<void>('/second');
      second.complete(_jsonResponse(<String, Object?>{'order': 2}));
      await secondRequest;
      first.complete(_jsonResponse(<String, Object?>{'order': 1}));
      await firstRequest;

      final events = controller.events.whereType<QaNetworkEvent>().toList();
      expect(events.map((event) => event.path), <String>['/second', '/first']);
      final firstEvent = events.singleWhere((event) => event.path == '/first');
      final secondEvent = events.singleWhere((event) => event.path == '/second');
      expect(firstEvent.startedAt.isAfter(secondEvent.startedAt), isFalse);
      controller.dispose();
    });

    test('bounds payloads and omits binary content', () async {
      final controller = _controller();
      final dio = _dio(
        controller,
        requestLimit: 20,
        responseLimit: 20,
        adapter: _FakeAdapter((options) {
          if (options.path.endsWith('/binary')) {
            return ResponseBody.fromBytes(
              <int>[1, 2, 3],
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/octet-stream'],
              },
            );
          }
          return _jsonResponse(<String, Object?>{
            'large': List<String>.filled(100, 'y').join(),
          });
        }),
      );

      await dio.post<void>(
        '/large',
        data: <String, Object?>{
          'large': List<String>.filled(100, 'x').join(),
        },
      );
      await dio.post<Uint8List>('/binary', data: Uint8List.fromList(<int>[4, 5]));

      final events = controller.events.whereType<QaNetworkEvent>().toList();
      expect(events.first.requestBody.isTruncated, isTrue);
      expect(events.first.responseBody.isTruncated, isTrue);
      expect(
        events.first.requestBody.originalSize,
        greaterThan(events.first.requestBody.capturedSize!),
      );
      expect(events.last.requestBody.data, contains('binary content omitted'));
      expect(events.last.responseBody.data, contains('binary content omitted'));
      controller.dispose();
    });

    test('captures FormData and MultipartFile metadata without finalizing it', () async {
      final controller = _controller();
      final formData = FormData.fromMap(<String, Object?>{
        'username': 'tester',
        'password': 'form-password',
        'document': MultipartFile.fromBytes(
          <int>[1, 2, 3],
          filename: 'document.txt',
        ),
      });
      final dio = _dio(
        controller,
        adapter: _FakeAdapter((_) => _jsonResponse(<String, Object?>{'ok': true})),
      );

      await dio.post<void>('/upload', data: formData);

      final event = controller.events.single as QaNetworkEvent;
      final body = _map(event.requestBody.data);
      expect(_map(body['fields'])['password'], '***');
      final files = body['files'] as List<Object?>;
      expect(_map(files.single)['filename'], 'document.txt');
      expect(_map(files.single)['length'], 3);
      expect(_map(files.single)['content'], contains('binary content omitted'));
      expect(formData.isFinalized, isTrue, reason: 'Dio alone finalizes FormData');
      controller.dispose();
    });

    test('supports multiple Dio instances and prevents duplicate registration', () async {
      final controller = _controller();
      final interceptor = QaNetworkInterceptor(controller: controller);
      final first = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _FakeAdapter((_) => _jsonResponse(<String, Object?>{}))
        ..interceptors.add(interceptor)
        ..interceptors.add(interceptor);
      final second = _dio(
        controller,
        adapter: _FakeAdapter((_) => _jsonResponse(<String, Object?>{})),
      );

      await first.get<void>('/first');
      await second.get<void>('/second');

      expect(controller.events.whereType<QaNetworkEvent>(), hasLength(2));
      controller.dispose();
    });

    test('disabled mode creates no event', () async {
      final controller = QaInspectorController();
      final body = <String, Object?>{'password': 'unchanged'};
      final dio = _dio(
        controller,
        adapter: _FakeAdapter((_) => _jsonResponse(<String, Object?>{'ok': true})),
      );

      await dio.post<void>('/disabled', data: body);

      expect(controller.events, isEmpty);
      expect(body['password'], 'unchanged');
      controller.dispose();
    });

    test('malformed inspection metadata does not affect host outcomes', () async {
      final controller = _controller();
      final successful = _dio(
        controller,
        adapter: _FakeAdapter((_) => _jsonResponse(<String, Object?>{'ok': true})),
      )..interceptors.insert(0, _MetadataInterceptor());

      final response = await successful.get<Map<String, dynamic>>('/success');

      expect(response.data?['ok'], isTrue);
      expect(controller.events, isEmpty);

      final failing = _dio(
        controller,
        adapter: _FakeAdapter(
          (_) => _jsonResponse(<String, Object?>{'error': true}, statusCode: 500),
        ),
      )..interceptors.insert(0, _MetadataInterceptor());
      DioException? original;
      try {
        await failing.get<void>('/failure');
      } on DioException catch (error) {
        original = error;
      }
      expect(original?.type, DioExceptionType.badResponse);
      expect(original?.response?.statusCode, 500);
      expect(controller.events, isEmpty);
      controller.dispose();
    });

    test('clear prevents an in-flight ghost event and permits new requests', () async {
      final controller = _controller();
      final oldResponse = Completer<ResponseBody>();
      final dio = _dio(
        controller,
        adapter: _FakeAdapter(
          (options) => options.path.endsWith('/old')
              ? oldResponse.future
              : _jsonResponse(<String, Object?>{'new': true}),
        ),
      );

      final oldRequest = dio.get<void>('/old');
      await Future<void>.delayed(Duration.zero);
      controller.clearEvents();
      oldResponse.complete(_jsonResponse(<String, Object?>{'old': true}));
      await oldRequest;
      expect(controller.events, isEmpty);

      await dio.get<void>('/new');
      expect(controller.events.whereType<QaNetworkEvent>().single.path, '/new');
      controller.dispose();
    });
  });
}

QaInspectorController _controller() => QaInspectorController(
  config: const QaInspectorConfig(enabled: true),
);

Dio _dio(
  QaInspectorController controller, {
  required HttpClientAdapter adapter,
  QaDataSanitizationConfig? config,
  int requestLimit = QaNetworkInterceptor.defaultPayloadLimit,
  int responseLimit = QaNetworkInterceptor.defaultPayloadLimit,
}) => Dio(BaseOptions(baseUrl: 'https://example.test'))
  ..httpClientAdapter = adapter
  ..interceptors.add(
    QaNetworkInterceptor(
      controller: controller,
      sanitizationConfig: config,
      requestBodyLimit: requestLimit,
      responseBodyLimit: responseLimit,
    ),
  );

ResponseBody _jsonResponse(
  Object? body, {
  int statusCode = 200,
  Map<String, List<String>>? headers,
}) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: headers ??
      <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
);

Map<Object?, Object?> _map(Object? value) => value as Map<Object?, Object?>;

MaterialPageRoute<void> _route(String name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox(),
);

final class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = Future<ResponseBody>.sync(() => _handler(options));
    if (cancelFuture == null) {
      return response;
    }
    return Future<ResponseBody>.any(<Future<ResponseBody>>[
      response,
      cancelFuture.then<ResponseBody>(
        (_) => throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'cancelled',
        ),
      ),
    ]);
  }

  @override
  void close({bool force = false}) {}
}

final class _MetadataInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['qa_inspector.request_context'] = 'application-owned';
    handler.next(options);
  }
}
