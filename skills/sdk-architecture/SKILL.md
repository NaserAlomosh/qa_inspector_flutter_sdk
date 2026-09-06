# Flutter QA SDK Architecture

## Purpose

This project is a reusable Flutter QA/debugging SDK designed to help Quality Assurance teams inspect application behavior directly from a running Flutter application.

The SDK must remain lightweight, modular, easy to integrate into existing large Flutter applications, and safe to disable in production builds.

The minimum supported Flutter version is Flutter 3.35.7.

---

## Core Principles

When modifying this project:

1. Treat this project as a reusable SDK/package, not as an application.
2. Keep the public API small, simple, and stable.
3. Do not introduce unnecessary dependencies.
4. Do not depend on any specific state-management solution.
5. Do not require the host application to use Bloc, Cubit, Riverpod, Provider, GetX, or any other state-management package.
6. Do not require a specific routing package.
7. Prefer Flutter/Dart APIs over third-party packages when practical.
8. Features must be independently maintainable.
9. Avoid changes that require large modifications in the host application.
10. Do not introduce breaking public API changes unless explicitly requested.

---

## Architecture

Organize the SDK around these modules:

lib/
├── src/
│   ├── core/
│   ├── events/
│   ├── network/
│   ├── routing/
│   ├── logs/
│   ├── ui/
│   ├── export/
│   └── utils/
│
└── qa_inspector.dart

### core

Contains SDK lifecycle, configuration, initialization, shared services, and internal coordination.

### events

Contains the unified event model and event timeline infrastructure.

Examples:

- Network events
- Route events
- Log events
- SDK events

All inspectable activity should eventually be represented as events.

### network

Contains network inspection functionality.

The initial implementation should support Dio through an interceptor without coupling the entire SDK to Dio.

### routing

Contains Flutter navigation observation and route tracking.

It should support events such as:

- push
- pop
- replace
- remove

Do not assume that the host application uses a particular routing package.

### logs

Contains application/debug log collection functionality.

### ui

Contains the QA inspector interface, floating entry point, overlays, sheets, timeline UI, API viewer, route viewer, and notes UI.

UI code must not contain event collection business logic.

### export

Contains report generation and export functionality.

Export implementations must consume existing collected data instead of collecting data themselves.

### utils

Contains small internal reusable utilities only.

Do not turn `utils` into a dumping ground for unrelated logic.

---

## Unified Event Architecture

The event timeline is the central source of truth for inspection data.

Features should publish events instead of communicating directly with the UI.

Conceptually:

Route Observer
      │
      ▼
   RouteEvent
      │
      │
Dio Interceptor
      │
      ▼
  NetworkEvent
      │
      │
Log Collector
      │
      ▼
    LogEvent
      │
      ▼
────────────────
 Event Timeline
────────────────
      │
      ├── Inspector UI
      ├── API Viewer
      ├── Route Viewer
      └── Report Export

Do not tightly couple collectors to UI components.

---

## Host Application Integration

Integration into an existing Flutter project must require as little host code modification as reasonably possible.

Target developer experience:

```dart
QaInspector(
  enabled: const bool.fromEnvironment(
    'QA_TOOLS',
    defaultValue: false,
  ),
  child: const MyApp(),
);
```

Network integration should be simple:

```dart
dio.interceptors.add(
  QaNetworkInterceptor(),
);
```

Navigation integration should be simple:

```dart
navigatorObservers: [
  QaRouteObserver(),
],
```

These examples describe the desired developer experience.

Do not implement placeholder APIs only to match these examples if the underlying feature has not been implemented yet.

---

## Public API

Only intentionally supported APIs should be exported from:

lib/qa_inspector.dart

Do not expose internal implementation classes unnecessarily.

Prefer:

```dart
import 'package:qa_inspector/qa_inspector.dart';
```

instead of requiring consumers to import files from `src`.

Host applications should never need imports such as:

```dart
import 'package:qa_inspector/src/...';
```

---

## Production Safety

The SDK must support being disabled.

Example:

```dart
const bool qaToolsEnabled = bool.fromEnvironment(
  'QA_TOOLS',
  defaultValue: false,
);
```

When disabled:

- Do not display QA UI.
- Do not collect network events.
- Do not collect route events.
- Do not collect logs.
- Do not perform export work.
- Avoid unnecessary listeners.
- Avoid unnecessary memory allocation.
- Runtime overhead should be minimal.

Do not rely on `kDebugMode` as the only activation mechanism.

The SDK may be used in QA release builds.

---

## Performance

This SDK runs inside potentially large production-grade applications.

Therefore:

- Never allow event history to grow indefinitely.
- Use bounded buffers for collected events.
- Avoid retaining large request or response payloads.
- Avoid unnecessary widget rebuilds.
- Dispose streams, controllers, listeners, and subscriptions correctly.
- Avoid expensive synchronous operations on the UI thread.
- Keep disabled-mode overhead close to zero.

---

## Privacy and Security

Debugging information can contain sensitive information.

Never assume network payloads are safe to display or export.

The architecture must allow sensitive data masking for values such as:

- Authorization headers
- Access tokens
- Refresh tokens
- Passwords
- PINs
- OTPs
- Session identifiers
- Cookies

Sensitive-data masking will have its own implementation rules.

Do not log secrets merely because this is a QA SDK.

---

## Flutter Compatibility

Minimum supported Flutter version:

Flutter 3.35.7

Code must remain compatible with this version unless the minimum supported version is intentionally changed.

Before using a newer Flutter or Dart API:

1. Verify that it exists in the minimum supported version.
2. Prefer APIs available in Flutter 3.35.7.
3. Do not increase the minimum version merely for convenience.

The SDK should also remain compatible with current stable Flutter versions whenever practical.

---

## Dependencies

Before adding a dependency:

1. Determine whether Flutter or Dart already provides the required functionality.
2. Evaluate the maintenance cost of the dependency.
3. Avoid dependencies for trivial functionality.
4. Avoid introducing a dependency that forces architectural decisions onto host applications.

Never add a package solely to save a few lines of straightforward Dart code.

---

## Testing

Architecture changes must remain testable.

Business logic should not depend directly on widgets where avoidable.

Prefer abstractions that allow:

- Unit testing event collection
- Unit testing event ordering
- Unit testing configuration
- Unit testing bounded buffers
- Widget testing inspector UI

New core behavior should include appropriate tests.

---

## Change Discipline

When implementing a task:

1. Inspect the existing architecture first.
2. Reuse existing abstractions when appropriate.
3. Make the smallest coherent change.
4. Avoid unrelated refactoring.
5. Preserve backward compatibility.
6. Add or update tests.
7. Run formatting.
8. Run static analysis.
9. Run relevant tests.
10. Report any architectural concern instead of silently working around it.

Do not over-engineer features that are not currently required.

---

## MVP Scope

The initial SDK is focused on:

- QA inspector overlay
- Unified event timeline
- API inspection
- Route/navigation inspection
- QA notes
- Report generation
- Image export
- Copyable report information

Do not introduce unrelated features unless explicitly requested.

The goal is not to replace Flutter DevTools.

The goal is to provide QA engineers with useful runtime diagnostic information directly inside the application.