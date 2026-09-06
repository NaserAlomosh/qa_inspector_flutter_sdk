# Performance and Safety Skill

## Purpose

The Performance and Safety module defines the runtime guarantees that every part of the QA SDK must follow.

The SDK is intended to run inside real applications, including large production-like QA builds.

Therefore, the QA SDK must never become a meaningful source of:

- UI jank
- Memory leaks
- Network delays
- Navigation problems
- Application crashes
- Excessive allocations
- Large memory growth
- Blocking work on the UI thread

The SDK must remain lightweight when enabled and close to zero-cost when disabled.

---

## Core Principles

When implementing or modifying any SDK feature:

1. Never break the host application.
2. Never change host application behavior.
3. Keep disabled-mode overhead extremely small.
4. Keep event history bounded.
5. Avoid unnecessary deep copies.
6. Avoid expensive work on the hot path.
7. Avoid synchronous heavy formatting.
8. Dispose all listeners and controllers.
9. Treat SDK failures as non-fatal.
10. Prefer losing diagnostic data over crashing the host app.

---

## Safety Priority

The priority order is:

    Host Application Stability
        ↓
    Data Privacy
        ↓
    SDK Performance
        ↓
    Diagnostic Completeness

If the SDK must choose between:

    keeping complete debug data

and:

    protecting application stability

always protect the host application.

---

## Disabled Mode

Disabled mode is a critical requirement.

Conceptually:

    const qaEnabled = bool.fromEnvironment(
      'QA_TOOLS',
      defaultValue: false,
    );

When disabled:

- Do not collect events.
- Do not sanitize payloads.
- Do not format data.
- Do not build QA widgets.
- Do not notify listeners.
- Do not allocate large internal structures.
- Do not generate reports.
- Do not retain navigation history.
- Do not perform unnecessary string conversions.

The disabled path should return as early as possible.

Example:

    if (!enabled) {
      handler.next(options);
      return;
    }

Do not perform work first and check enabled afterward.

---

## Near-Zero Disabled Overhead

The host application may permanently include the SDK integration.

Example:

    QaInspector(
      enabled: const bool.fromEnvironment('QA_TOOLS'),
      child: const MyApp(),
    );

This must remain safe even in release builds where QA tools are disabled.

The SDK should not require developers to remove code before production builds.

---

## Event Buffer Limits

The Event Timeline must have a bounded history.

Example:

    maxEvents = 200

When the limit is reached:

    remove oldest event
        ↓
    add newest event

Never allow unlimited event accumulation.

A long QA session must not continuously increase memory usage.

---

## Configurable Limits

Important limits should be configurable.

Conceptually:

    QaInspectorConfig(
      maxEvents: 200,
      network: QaNetworkConfig(
        maxRequestBodyBytes: 50 * 1024,
        maxResponseBodyBytes: 50 * 1024,
      ),
    )

Provide safe defaults.

Do not require configuration for normal usage.

---

## Network Payload Limits

Large request and response payloads can consume significant memory.

The Network Inspector must truncate payloads before storing them in the Event Timeline.

Recommended initial defaults:

    Request body:
    50 KB

    Response body:
    50 KB

The exact defaults may evolve.

---

## Truncation Metadata

When content is truncated, preserve useful metadata.

Example:

    truncated: true

    originalSize:
    148320

    capturedSize:
    51200

The QA UI and report may display:

    Response truncated

Do not silently cut content without indication.

---

## Binary Payloads

Do not store raw large binary payloads.

Examples:

- Images
- PDFs
- Videos
- ZIP files
- Audio files
- Byte streams

Store metadata only when useful.

Example:

    contentType: image/jpeg
    size: 284120
    body: [binary omitted]

Do not convert binary data into Base64 for the QA timeline.

---

## Network Hot Path

The Network Inspector runs inside the host application's network flow.

Therefore:

- Keep interception logic lightweight.
- Avoid expensive serialization.
- Avoid UI work.
- Avoid image processing.
- Avoid disk writes.
- Avoid synchronous report generation.
- Avoid heavy logs.

The interceptor should capture only the data needed for the event.

---

## Never Delay Networking

Inspection must not intentionally delay request forwarding.

Unsafe pattern:

    await expensiveSanitization();
    handler.next(options);

Avoid unnecessary asynchronous delays before continuing the request.

Prefer:

    capture lightweight metadata
        ↓
    continue request

For response handling, processing must still remain bounded and fast.

---

## Inspection Failure

Every interception path must fail safely.

Conceptually:

    try {
      captureEvent();
    } catch (_) {
      // Ignore inspection failure.
    }

    handler.next(response);

The host network response must continue normally.

Do not convert an SDK exception into a DioException.

---

## Original Network Objects

Do not modify original:

- RequestOptions.data
- Response.data
- Headers
- Query parameters
- DioException
- FormData
- MultipartFile

Only inspect and create sanitized representations.

---

## Navigation Safety

QaRouteObserver must only observe navigation.

It must never:

- Push routes.
- Pop routes.
- Replace routes.
- Change RouteSettings.
- Modify Navigator state.
- Delay Navigator callbacks.

If route inspection fails, navigation continues normally.

---

## Route Resolver Safety

Custom route resolvers are application-provided code.

Example:

    routeNameResolver: (route) {
      return resolveRoute(route);
    }

Wrap custom resolvers safely.

If the resolver throws:

    use fallback route representation

Do not allow a resolver exception to break navigation.

---

## UI Isolation

The QA Overlay must not rebuild the host application when timeline data changes.

Conceptually:

    Host App
        │
        └── independent QA overlay

QA state changes should affect QA widgets only.

Do not place timeline listeners around the entire host application tree.

---

## Rebuild Scope

Prefer small rebuild regions.

Example:

    Timeline listener
        ↓
    Timeline list only

instead of:

    Timeline listener
        ↓
    QaInspector
        ↓
    Host MyApp
        ↓
    entire application rebuild

The host application's widget tree should remain isolated.

---

## Lazy Rendering

Large lists must use lazy rendering.

Use patterns such as:

    ListView.builder

Avoid:

    Column(
      children: allEvents.map(buildEvent).toList(),
    )

for large histories.

---

## JSON Formatting

Do not pretty-print JSON during network capture.

Store sanitized structured data or lightweight representations.

Format JSON only when:

- API details are opened.
- Report generation requires it.
- Copy action requires it.

Presentation-time formatting is preferable.

---

## Expensive Computation

Do not perform expensive operations synchronously on every event.

Examples to avoid:

- Sorting the full timeline after every insert.
- Regenerating a full report after every request.
- Pretty-printing every response immediately.
- Recomputing all screen groups repeatedly.
- Rebuilding large summaries for each event.

Prefer incremental or on-demand computation.

---

## Timeline Ordering

Use insertion order as the main source of chronological order.

Do not sort the entire event list every time an event is added.

Timestamps remain useful for display and diagnostics.

---

## Snapshots

Consumers that need stable data should request snapshots.

Examples:

- Export
- Copy report
- Complex filtering

Conceptually:

    final events = timeline.snapshot();

Do not expose internal mutable collections.

---

## Immutable Events

Prefer immutable event models.

Once a QaEvent is added to the timeline, it should not normally change.

This reduces unexpected UI behavior and synchronization problems.

---

## Listener Management

Every listener must have a defined lifecycle.

Examples:

- Timeline listeners
- Streams
- ChangeNotifier listeners
- Overlay listeners
- Route-context listeners

Always remove listeners when no longer needed.

---

## Controller Disposal

Dispose all owned resources.

Examples:

- TextEditingController
- AnimationController
- ScrollController
- StreamController
- FocusNode
- ValueNotifier when owned

Do not leak controllers when the QA Inspector opens and closes repeatedly.

---

## Overlay Lifecycle

Opening and closing the QA overlay repeatedly must not create duplicate overlays.

There should never be multiple floating QA buttons or multiple inspector overlays caused by lifecycle mistakes.

Ensure:

    open
    close
    open
    close

remains stable.

---

## Multiple Dio Instances

The host application may use multiple Dio clients.

The SDK must support this without creating conflicting global state.

Example:

    authDio.interceptors.add(qaInterceptor);

    paymentsDio.interceptors.add(qaInterceptor);

Both may publish to the same timeline.

---

## Duplicate Interceptor Registration

Applications may accidentally register the same QA interceptor more than once.

The SDK should avoid catastrophic duplication.

Reasonable options include:

- Documenting one registration per Dio instance.
- Detecting duplicate QA interceptors where practical.

Do not build overly complex global deduplication for the MVP.

---

## Thread and Async Safety

Flutter code may receive asynchronous callbacks very close together.

The Event Timeline must remain consistent when events are added from multiple async operations.

Avoid patterns that depend on unsafe read-modify-write sequences.

Example unsafe conceptual pattern:

    events = [...events, newEvent];

when concurrent paths could overwrite each other.

Use simple synchronous mutation within Dart's event loop where appropriate.

---

## Event IDs

Event ID generation must remain lightweight.

Do not add a large UUID dependency solely for event IDs.

A combination of:

- Monotonic counter
- Timestamp
- Session prefix

is sufficient for the MVP.

---

## Memory Safety

Avoid retaining references to large original application objects.

Example:

Do not store:

    Response<dynamic>

inside QaNetworkEvent.

Instead extract only necessary sanitized fields.

This allows Dio response objects and other application data to be garbage collected normally.

---

## Object Retention

Do not store:

- BuildContext
- Widget
- Element
- NavigatorState
- Dio Response objects
- RequestOptions
- Route objects

inside long-lived timeline events.

Extract primitive or lightweight values.

Example:

Store:

    routeName: "/transfer"

not:

    Route<dynamic> route

---

## BuildContext Safety

Do not retain BuildContext longer than necessary.

The QA Overlay may use context while opening UI, but long-lived services should not store arbitrary BuildContext references.

This avoids memory leaks and stale-context problems.

---

## Report Generation

Report generation can be expensive.

It must happen only when explicitly requested by the QA engineer.

Do not continuously pre-render report images.

---

## Report Snapshot Safety

When report generation starts:

    capture stable timeline snapshot
        ↓
    generate report

Do not keep live listeners active inside report rendering logic.

---

## Large Image Protection

PNG export may produce tall images.

Set reasonable safeguards.

Examples:

- Maximum exported steps.
- Maximum API count.
- Maximum payload preview size.
- Maximum rendered height.

If limits are exceeded:

    reduce detail

or:

    indicate omitted content

Do not attempt unlimited-size image allocation.

---

## Out-of-Memory Protection

If report rendering fails due to resource limitations:

- Catch the failure.
- Clean up temporary resources.
- Return a safe export failure.
- Keep the host application running.

Do not retry repeatedly with the same dangerous configuration.

---

## Clipboard Safety

Copy operations can generate large strings.

Apply reasonable report limits before building clipboard text.

Do not concatenate unlimited payload history into one massive String.

---

## Notes Limits

QA Notes should have a reasonable maximum length.

Example:

    5000 characters

The exact limit may be configurable later.

This prevents accidental massive input from bloating reports.

---

## Logging

Internal QA SDK logs should be minimal.

Avoid noisy logs on every event.

If internal debug logging exists:

- Keep it disabled by default.
- Never log sensitive data.
- Use a consistent prefix.

Example:

    [QaInspector]

Do not spam the host application's logs.

---

## Error Isolation

SDK modules should fail independently.

Example:

If Export fails:

    Network Inspector continues.

If UI fails:

    Event collection continues if safe.

If route resolution fails:

    Network inspection continues.

Avoid tightly coupling failures across modules.

---

## Defensive Boundaries

Each major module should protect its boundary.

Examples:

    Network Inspector
        safely publishes event

    Routing Observer
        safely publishes event

    Overlay UI
        safely reads snapshot/listener state

    Exporter
        safely consumes snapshot

A failure in one module should not cascade through the SDK.

---

## Configuration Validation

Validate invalid configuration safely.

Example:

    maxEvents <= 0

Do not create undefined behavior.

Possible approaches:

- Clamp to a safe minimum.
- Assert in debug and fallback safely.
- Throw only during explicit SDK initialization if appropriate.

Do not throw runtime exceptions during unrelated application flows.

---

## Safe Defaults

The SDK should work safely without advanced configuration.

Recommended defaults should prioritize:

- Bounded memory.
- Sensitive data protection.
- Low overhead.
- Readable reports.
- Predictable behavior.

---

## Startup Cost

QaInspector initialization should remain lightweight.

Do not perform:

- File scans
- Large allocations
- Platform queries
- Report rendering
- JSON processing

during application startup unless explicitly required.

---

## No Background Work

The MVP should not create unnecessary timers or background loops.

Do not poll the Event Timeline.

Do not continuously scan application state.

Events should be pushed by collectors.

---

## No Persistence by Default

The MVP keeps session data in memory.

Do not automatically persist:

- API payloads
- Route history
- Notes
- Reports

to local storage.

Persistence introduces privacy, disk usage, and lifecycle complexity.

---

## App Lifecycle

The SDK should tolerate application lifecycle changes.

Examples:

- Background
- Foreground
- Temporary inactivity

Do not assume the app remains continuously active.

The MVP does not need complex lifecycle analytics.

---

## Session Reset

Clearing a session must release references to old events.

After:

    timeline.clear()

old event data should become eligible for garbage collection.

Do not maintain hidden secondary histories.

---

## Performance Measurement

When evaluating performance, focus on:

- Network interception overhead
- Event insertion cost
- UI rebuild scope
- Memory growth
- Large payload handling
- Report generation

Do not optimize meaningless micro-details while ignoring large allocations.

---

## Reasonable Performance Goals

The SDK should aim for:

- Constant-time or near constant-time event insertion.
- Bounded memory based on configured limits.
- No visible UI jank during ordinary request collection.
- No meaningful network latency introduced by inspection.
- Smooth inspector scrolling for normal event limits.

Do not claim hard millisecond guarantees without benchmarks.

---

## Benchmarking

Optional benchmarks may be added for:

- Adding 1,000 events.
- Sanitizing large nested JSON.
- Timeline snapshot creation.
- Rendering event lists.
- Report generation.

Benchmarks should support engineering decisions, not become part of MVP complexity.

---

## Failure Policy

Prefer safe omission.

Example:

If a response cannot be safely inspected:

    responseBody:
    [content omitted]

not:

    crash

and not:

    store raw response

---

## Do Not

Do not:

- Allow unlimited timeline growth.
- Store large original Dio objects.
- Store Route objects in events.
- Retain BuildContext in long-lived services.
- Pretty-print every payload during interception.
- Render reports continuously.
- Poll for events.
- Create unnecessary background timers.
- Modify application requests or responses.
- Delay network requests for inspection.
- Let route inspection affect Navigator behavior.
- Rebuild the host application for QA updates.
- Keep duplicate hidden event histories.
- Persist sensitive QA data automatically.
- Retry dangerous export operations indefinitely.
- Fall back to unsafe raw data.
- Allow SDK exceptions to crash the host application.

---

## Testing Requirements

Add tests covering at least:

1. Disabled interceptor returns immediately.
2. Disabled routing observer performs minimal work.
3. Disabled UI does not create overlay widgets.
4. Timeline respects maxEvents.
5. Oldest events are removed first.
6. Timeline clear releases stored events.
7. Large response payload is truncated.
8. Large request payload is truncated.
9. Binary payload is omitted.
10. Truncation metadata is correct.
11. Network inspection failure does not affect response.
12. Network inspection failure does not affect error handling.
13. Route resolver failure does not affect navigation.
14. Timeline publishing failure does not affect host behavior.
15. UI failure does not modify host state.
16. Repeated overlay open/close does not duplicate overlays.
17. Controllers are disposed.
18. Listeners are removed.
19. Multiple Dio instances work.
20. Multiple simultaneous requests preserve event consistency.
21. Event insertion order remains correct.
22. Snapshot does not expose mutable internal state.
23. Events do not retain Dio Response objects.
24. Events do not retain Route objects.
25. Large report limits are enforced.
26. Export failure is handled safely.
27. Clipboard generation respects limits.
28. Clear session continues collecting afterward.
29. Notes length limits behave safely if implemented.
30. Large event list uses lazy rendering.

---

## Definition of Done

Performance and Safety work is complete only when:

1. Disabled mode has near-zero practical overhead.
2. Timeline memory is bounded.
3. Payload sizes are bounded.
4. Binary content is safely omitted.
5. Network inspection cannot break networking.
6. Routing inspection cannot break navigation.
7. QA UI does not rebuild the host application unnecessarily.
8. Long-lived services do not retain BuildContext.
9. Timeline events do not retain large framework/network objects.
10. Listeners and controllers are disposed.
11. Report generation is on-demand only.
12. Large export operations have safeguards.
13. SDK failures remain isolated.
14. Session clearing releases old data.
15. No automatic persistence exists in the MVP.
16. Tests cover failure isolation and memory boundaries.
17. Flutter 3.35.7 compatibility is preserved.
18. Static analysis and tests pass.