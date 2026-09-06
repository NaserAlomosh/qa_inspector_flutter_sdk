import 'package:flutter/material.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  runApp(
    const QaInspector(
      config: QaInspectorConfig(
        enabled: bool.fromEnvironment('QA_TOOLS'),
      ),
      child: ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QA Inspector Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('QA Inspector')),
        body: const Center(
          child: Text('QA Inspector example application'),
        ),
      ),
    );
  }
}
