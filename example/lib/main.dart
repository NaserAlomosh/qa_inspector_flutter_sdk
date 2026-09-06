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

  @override
  void dispose() {
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
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QA Inspector')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/details'),
                builder: (_) => const DetailsScreen(),
              ),
            );
          },
          child: const Text('Open details'),
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(child: Text('Observed route')),
    );
  }
}
