import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qa_inspector/qa_inspector.dart';

import 'data/example_api.dart';
import 'screens/users_screen.dart';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, this.dio});

  final Dio? dio;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final QaInspectorController _qaController = QaInspectorController(
    config: const QaInspectorConfig(enabled: bool.fromEnvironment('QA_TOOLS')),
  );

  late final QaRouteObserver _routeObserver = QaRouteObserver(
    controller: _qaController,
  );

  late final Dio _dio;
  late final bool _ownsDio;

  @override
  void initState() {
    super.initState();

    _ownsDio = widget.dio == null;

    _dio =
        widget.dio ??
        Dio(
          BaseOptions(
            baseUrl: 'https://jsonplaceholder.typicode.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: const <String, String>{
              'Authorization': 'Bearer example-secret-access-token',
            },
          ),
        );

    _dio.interceptors.add(QaNetworkInterceptor(controller: _qaController));
  }

  @override
  void dispose() {
    if (_ownsDio) {
      _dio.close(force: true);
    }

    _qaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = ExampleApi(_dio);

    return MaterialApp(
      title: 'QA Inspector Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      navigatorObservers: <NavigatorObserver>[_routeObserver],
      initialRoute: '/',
      home: UsersScreen(api: api),
      builder: (context, child) {
        return QaInspector(
          controller: _qaController,
          themeMode: QaInspectorThemeMode.dark,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
