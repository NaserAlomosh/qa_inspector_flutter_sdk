# Event Timeline Skill

## Purpose

The Event Timeline is the central source of truth for all runtime inspection data collected by the Flutter QA SDK.

All inspectable activities such as navigation events, network events, logs, SDK events, and future diagnostic events should be represented through a unified event timeline.

The timeline must preserve the exact chronological order of events and make it easy for the QA inspector UI and report exporter to consume the same data.

---

## Core Principles

When implementing or modifying timeline-related functionality:

1. All runtime inspection data should be represented as events.
2. Events must be immutable whenever practical.
3. Every event must contain a timestamp.
4. Events must preserve chronological order.
5. Event storage must be bounded.
6. The timeline must not grow indefinitely.
7. Event collection must remain lightweight.
8. Event collectors must not depend directly on UI components.
9. UI components must consume timeline data instead of collecting events themselves.
10. The timeline must support future event types without requiring major architectural changes.

---

## Base Event Model

Create a common base event abstraction.

Conceptually:

    abstract class QaEvent {
      const QaEvent({
        required this.id,
        required this.timestamp,
        required this.type,
      });

      final String id;
      final DateTime timestamp;
      final QaEventType type;
    }

The exact implementation may differ, but every event must provide at least:

- Unique identifier
- Timestamp
- Event type

Optional common metadata may include:

- Current route name
- Previous route name
- Session identifier
- Event source
- Additional metadata

Do not put feature-specific fields directly into the base event unless they are genuinely shared by all event types.

---

## Event Types

The timeline should be designed to support event types such as:

    enum QaEventType {
      route,
      network,
      log,
      sdk,
    }

Additional types may be added in the future.

Do not create a single giant event model with dozens of nullable fields.

Prefer dedicated event models.

Example:

    class QaRouteEvent extends QaEvent {
      const QaRouteEvent({
        required super.id,
        required super.timestamp,
        required this.action,
        this.routeName,
        this.previousRouteName,
      }) : super(type: QaEventType.route);

      final QaRouteAction action;
      final String? routeName;
      final String? previousRouteName;
    }

Example:

    class QaNetworkEvent extends QaEvent {
      const QaNetworkEvent({
        required super.id,
        required super.timestamp,
        required this.method,
        required this.url,
        this.statusCode,
        this.duration,
      }) : super(type: QaEventType.network);

      final String method;
      final String url;
      final int? statusCode;
      final Duration? duration;
    }

---

## Timeline Store

The SDK must have one central timeline store responsible for:

- Adding events
- Preserving event order
- Enforcing the maximum event limit
- Providing read access to the current events
- Clearing the timeline when requested
- Notifying interested listeners when the timeline changes

The timeline store must not depend on Flutter widgets.

Prefer a lightweight Dart implementation.

Conceptually:

    class QaEventTimeline {
      QaEventTimeline({
        this.maxEvents = 200,
      });

      final int maxEvents;

      void add(QaEvent event);

      List<QaEvent> get events;

      void clear();
    }

The exact API may evolve, but responsibilities must remain centralized.

---

## Bounded Event Buffer

The timeline must never grow indefinitely.

Default maximum event count:

    200 events

This value should be configurable.

When a new event is added and the maximum size is exceeded:

1. Remove the oldest event.
2. Keep the newest events.
3. Preserve chronological ordering.

Example:

    maxEvents = 200

    Current events = 200
    New event arrives

    Remove oldest event
    Add new event

Never allow unbounded memory growth.

---

## Event Ordering

Events must appear in the same logical order in which they occurred.

Use timestamps for presentation, but event insertion order should remain authoritative when timestamps are equal.

Do not sort the entire timeline after every insertion unless there is a real requirement.

Prefer appending events in runtime order.

---

## Current Route Context

When practical, events should know the route or screen context where they occurred.

Example timeline:

    12:30:01  ROUTE    PUSH      /login
    12:30:02  API      POST      /login        200
    12:30:03  ROUTE    PUSH      /home
    12:30:04  API      GET       /accounts     200
    12:30:05  API      GET       /cards        500
    12:30:07  ROUTE    POP       /home

Network events should be able to capture the active route name at the time the request was created when possible.

Do not introduce a hard dependency between the network module and UI widgets.

Route context should be provided through shared core state or an abstraction.

---

## Route Grouping

The UI may group events by screen, but the underlying timeline must remain chronological.

Example:

    /home

      GET /accounts       200
      GET /cards          500

    /transfer

      POST /validate      200
      POST /transfer      400

This grouping is a presentation concern.

Do not store duplicated event collections per screen unless there is a strong performance requirement.

The central timeline remains the source of truth.

---

## Network Event Lifecycle

A network request may have multiple lifecycle stages.

Prefer representing a completed request as a single final network event when practical.

The event should be capable of containing:

- HTTP method
- URL
- Request timestamp
- Completion timestamp
- Duration
- Status code
- Request headers
- Request body
- Response headers
- Response body
- Error details
- Current route context

If a request has not completed yet, the architecture may internally track pending requests.

Do not expose partially duplicated timeline events unless the UI explicitly requires live request state.

---

## Sensitive Data

The timeline must only receive sanitized network data.

Sensitive-data masking must happen before sensitive content is stored in the timeline.

Do not store raw:

- Authorization headers
- Access tokens
- Refresh tokens
- Passwords
- PIN values
- OTP values
- Cookies
- Session identifiers
- Sensitive personal information

The timeline should consume already-sanitized data from the relevant collector.

---

## Large Payload Handling

Network bodies may be extremely large.

The timeline must not keep unlimited payload sizes.

The SDK should support payload truncation.

Recommended initial limit:

    50 KB per request/response body

The exact limit should be configurable later.

When truncating content, clearly indicate that truncation occurred.

Do not perform expensive serialization repeatedly.

---

## Event IDs

Each event must have a unique identifier.

The implementation should not require a heavy dependency solely to generate IDs.

Acceptable approaches include:

- Incrementing internal sequence
- Timestamp plus sequence
- Lightweight internal ID generator

Avoid adding a UUID dependency unless there is a meaningful need.

---

## Event Notifications

The inspector UI needs to react when new events arrive.

The timeline should expose a lightweight notification mechanism.

Possible options include:

- ChangeNotifier
- ValueNotifier
- Stream
- Custom listener abstraction

Choose the simplest solution that fits the existing architecture.

Do not introduce a state-management framework for the timeline.

Do not depend on Bloc, Riverpod, Provider, GetX, or similar packages.

---

## Timeline Snapshot

Consumers should be able to request an immutable snapshot of current events.

Example concept:

    final events = timeline.snapshot();

A snapshot should not allow external callers to mutate the internal event collection.

Never expose the mutable internal list directly.

---

## Clearing Events

The SDK should support clearing the current timeline.

Example use cases:

- QA starts testing a new scenario
- QA wants a clean report
- SDK session reset

Clearing the timeline must not break active collectors.

After clearing, new events should continue to be collected normally.

---

## Session Concept

The MVP does not require complex session persistence.

A runtime session may simply represent the current SDK lifetime.

For the MVP:

    App starts
        ↓
    QA SDK starts
        ↓
    Timeline begins
        ↓
    App closes
        ↓
    Timeline is lost

This is acceptable.

Do not introduce database persistence, local storage, or cross-launch history unless explicitly requested.

---

## Persistence

Do not persist timeline events to disk in the MVP unless explicitly requested.

Reasons:

- Sensitive data risk
- Increased complexity
- Storage management
- Encryption requirements
- Cleanup concerns

The initial timeline should be memory-only.

---

## Performance Requirements

Timeline operations should be inexpensive.

Adding an event should not perform heavy work.

Avoid:

- Expensive JSON formatting during collection
- Image generation during collection
- Disk operations
- Large deep copies
- Rebuilding unrelated UI
- Sorting large collections after every event

Heavy formatting should happen only when needed by the UI or exporter.

---

## Thread and Async Safety

Flutter runtime events may arrive asynchronously.

The timeline must not corrupt event ordering or throw concurrent modification errors.

Do not mutate event collections while exposing them directly to listeners.

Use safe snapshots for consumers.

---

## Testing Requirements

Add tests for at least:

### Event Addition

Verify that events are added successfully.

### Ordering

Verify that events remain in insertion order.

### Maximum Size

Given:

    maxEvents = 3

Adding:

    event1
    event2
    event3
    event4

Must result in:

    event2
    event3
    event4

### Clear

Verify that clear removes existing events.

### Immutable Snapshot

Verify that consumers cannot mutate the internal timeline.

### Multiple Event Types

Verify that route and network events can exist together in chronological order.

---

## Example Expected Timeline

The SDK should eventually be able to produce a timeline similar to:

    14:10:01.230  ROUTE
    PUSH
    from: /
    to: /login

    14:10:02.012  NETWORK
    POST /api/login
    status: 200
    duration: 421ms
    screen: /login

    14:10:02.510  ROUTE
    REPLACE
    from: /login
    to: /home

    14:10:02.740  NETWORK
    GET /api/accounts
    status: 200
    duration: 180ms
    screen: /home

    14:10:03.050  NETWORK
    GET /api/cards
    status: 500
    duration: 260ms
    screen: /home

    14:10:05.000  ROUTE
    PUSH
    from: /home
    to: /transfer

This ordered history is one of the main outputs of the SDK.

---

## Do Not

Do not:

- Store unlimited events
- Couple events directly to widgets
- Couple timeline logic to Dio
- Couple timeline logic to Navigator
- Introduce a state-management framework
- Persist sensitive data by default
- Create separate competing timelines for each feature
- Store raw secrets
- Perform expensive formatting during collection
- Add dependencies without clear value

---

## Definition of Done

Timeline-related work is complete only when:

1. Events use a common architecture.
2. Events include timestamps and unique IDs.
3. The central timeline stores different event types.
4. Event order is preserved.
5. The maximum buffer size is enforced.
6. Consumers cannot mutate internal timeline state.
7. Events can be cleared safely.
8. The implementation has tests.
9. Flutter 3.35.7 compatibility is preserved.
10. Static analysis and tests pass.