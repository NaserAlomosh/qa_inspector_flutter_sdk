import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector_example/app.dart';

void main() {
  testWidgets('loads users and opens their posts', (tester) async {
    final dio = Dio()..interceptors.add(_FixtureInterceptor());
    addTearDown(dio.close);

    await tester.pumpWidget(ExampleApp(dio: dio));
    await tester.pumpAndSettle();

    expect(find.text('QA Journey · Users'), findsOneWidget);
    expect(find.text('Leanne Graham'), findsOneWidget);

    await tester.tap(find.text('Leanne Graham'));
    await tester.pumpAndSettle();

    expect(find.text('Leanne Graham · Posts'), findsOneWidget);
    expect(find.text('A test post'), findsOneWidget);
    expect(find.text('Create post'), findsOneWidget);
  });
}

class _FixtureInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.path == '/users'
        ? <Object?>[
            <String, Object?>{
              'id': 1,
              'name': 'Leanne Graham',
              'email': 'leanne@example.com',
            },
          ]
        : <Object?>[
            <String, Object?>{
              'id': 1,
              'userId': 1,
              'title': 'A test post',
              'body': 'Deterministic fixture body',
            },
          ];
    handler.resolve(Response<Object?>(requestOptions: options, data: data));
  }
}
