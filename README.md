# QA Inspector

QA Inspector is an under-development Flutter SDK intended to give quality
assurance teams lightweight, in-app visibility into application behavior.

## Planned MVP

The MVP is planned to provide a unified, bounded event timeline for navigation,
network, and application log events; an in-app QA inspector overlay; QA notes;
and sanitized report copy and image export.

## Compatibility

The minimum supported Flutter version is **3.35.7**. The package is designed to
remain compatible with newer stable Flutter releases.

## Current status

The SDK is under development. It currently provides an in-memory bounded event
timeline, sensitive-data sanitization, Dio network inspection, Flutter
Navigator route observation, an in-app QA overlay, and session-only QA notes.
Persistence and report export are not implemented yet.

## Integration

Create one controller and share it with QA Inspector and every collector:

```dart
final qaController = QaInspectorController(
  config: const QaInspectorConfig(enabled: true),
);

MaterialApp(
  navigatorObservers: [
    QaRouteObserver(controller: qaController),
  ],
  builder: (context, child) => QaInspector(
    controller: qaController,
    child: child ?? const SizedBox.shrink(),
  ),
);
```

The application that creates `QaInspectorController` owns its lifecycle and
must call `dispose` when the controller is no longer needed. `QaInspector` and
collectors never dispose an externally supplied controller.
