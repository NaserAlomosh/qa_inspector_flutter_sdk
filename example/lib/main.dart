import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  runApp(const ExampleBootstrap());
}

class ExampleBootstrap extends StatefulWidget {
  const ExampleBootstrap({super.key});

  @override
  State<ExampleBootstrap> createState() => _ExampleBootstrapState();
}

class _ExampleBootstrapState extends State<ExampleBootstrap> {
  late final QaInspectorController _qaController = QaInspectorController(
    config: const QaInspectorConfig(
      enabled: bool.fromEnvironment('QA_TOOLS'),
    ),
  );
  late final QaRouteObserver _routeObserver = QaRouteObserver(
    controller: _qaController,
  );
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = Dio()
      ..interceptors.add(QaNetworkInterceptor(controller: _qaController))
      ..interceptors.add(_ExampleApiInterceptor());
  }

  @override
  void dispose() {
    _dio.close(force: true);
    _qaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QaInspector(
      controller: _qaController,
      child: MaterialApp(
        title: 'QA Inspector Example',
        navigatorObservers: <NavigatorObserver>[_routeObserver],
        home: HomeScreen(dio: _dio),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.dio, super.key});

  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QA Inspector')),
      body: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: '/details'),
                    builder: (_) => DetailsScreen(dio: dio),
                  ),
                );
              },
              child: const Text('Open details'),
            ),
            OutlinedButton(
              onPressed: () => dio.get<void>('/example/success'),
              child: const Text('Successful request'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({required this.dio, super.key});

  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Observed route'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await dio.post<void>(
                    '/example/failure',
                    data: <String, Object?>{'password': 'masked-by-sdk'},
                  );
                } on DioException {
                  // The failure is intentional for the local inspector example.
                }
              },
              child: const Text('Failed request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.endsWith('/failure')) {
      handler.reject(
        DioException.badResponse(
          statusCode: 422,
          requestOptions: options,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 422,
            data: <String, Object?>{'message': 'Deterministic example failure'},
          ),
        ),
      );
      return;
    }
    handler.resolve(
      Response<Object?>(
        requestOptions: options,
        statusCode: 200,
        data: <String, Object?>{'result': 'Deterministic example success'},
      ),
    );
  }
}
