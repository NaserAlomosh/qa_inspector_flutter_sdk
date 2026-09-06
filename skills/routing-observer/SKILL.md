# Routing Observer Skill

## Purpose

The Routing Observer tracks navigation activity inside the host Flutter application and publishes route events to the central Event Timeline.

The goal is to allow QA engineers to understand exactly how the user navigated through the application before an issue occurred.

The Routing Observer must identify:

- Which screen the user entered
- Which screen the user left
- The navigation action that occurred
- The previous route
- The destination route
- The exact time of the navigation event

The Routing Observer must remain lightweight and must not change the navigation behavior of the host application.

---

## Core Principles

When implementing or modifying routing inspection:

1. Observe navigation without controlling it.
2. Never modify the host application's navigation behavior.
3. Publish navigation activity as QaRouteEvent objects.
4. Send route events to the central Event Timeline.
5. Preserve the chronological relationship between route events and network events.
6. Keep track of the currently active route.
7. Do not depend on a specific state-management package.
8. Do not require the host application to rewrite its navigation architecture.
9. Fail safely when route names are unavailable.
10. Keep integration minimal.

---

## Initial Navigation Support

The MVP must support Flutter Navigator through NavigatorObserver.

The Routing Observer should detect:

- push
- pop
- replace
- remove

Conceptual mapping:

    NavigatorObserver.didPush
        ↓
    QaRouteAction.push

    NavigatorObserver.didPop
        ↓
    QaRouteAction.pop

    NavigatorObserver.didReplace
        ↓
    QaRouteAction.replace

    NavigatorObserver.didRemove
        ↓
    QaRouteAction.remove

---

## Route Action Model

Use a clear navigation action model.

Conceptually:

    enum QaRouteAction {
      push,
      pop,
      replace,
      remove,
    }

Do not represent navigation actions using arbitrary strings internally.

The UI or exporter may convert the enum to readable text later.

---

## Route Event

A route event should contain information such as:

    class QaRouteEvent extends QaEvent {
      final QaRouteAction action;

      final String? fromRoute;
      final String? toRoute;

      final String? routeName;
      final String? previousRouteName;
    }

The exact implementation may differ based on the existing event architecture.

Avoid duplicated fields when possible.

The important information is:

- action
- source route
- destination route
- timestamp

---

## Push Behavior

Example navigation:

    /home
        ↓ push
    /transfer

Expected event:

    ROUTE
    action: PUSH
    from: /home
    to: /transfer

The active route after the event should become:

    /transfer

---

## Pop Behavior

Example:

    /home
        ↓ push
    /transfer
        ↓ pop
    /home

Expected event:

    ROUTE
    action: POP
    from: /transfer
    to: /home

The active route after the event should become:

    /home

Be careful with NavigatorObserver.didPop arguments.

The popped route represents the screen being removed.

The previous route represents the route that becomes visible again.

Do not reverse from/to semantics.

---

## Replace Behavior

Example:

    /login
        ↓ replace
    /home

Expected event:

    ROUTE
    action: REPLACE
    from: /login
    to: /home

The active route after the event should become:

    /home

---

## Remove Behavior

Example stack:

    /home
    /transfer
    /confirmation

If:

    /transfer

is removed from the stack, record the removal event.

Example:

    ROUTE
    action: REMOVE
    route: /transfer

Do not incorrectly report a route removal as a user-visible navigation transition when the visible route did not change.

The event should still exist in the timeline because stack mutations are useful debugging information.

---

## Route Name Resolution

Prefer:

    Route.settings.name

when available.

However, not every Flutter application provides route names.

The Routing Observer must handle:

    route.settings.name == null

without crashing.

Never assume route names always exist.

---

## Route Fallback

If a route name is unavailable, the SDK may provide a fallback representation.

Possible fallback information:

- Route runtime type
- Route settings
- Developer-provided resolver

Example fallback:

    MaterialPageRoute<dynamic>

However, do not expose unreadable object representations as the primary QA experience if a better value is available.

---

## Custom Route Name Resolver

The host application should be able to provide a custom route-name resolver.

Conceptually:

    QaRouteObserver(
      routeNameResolver: (route) {
        return route.settings.name ??
            customResolveRoute(route);
      },
    )

This allows applications using custom routing systems to provide meaningful screen names.

The resolver must be optional.

Default behavior should work with standard Flutter route names.

---

## Current Route Tracking

The Routing Observer must maintain the current active route.

This current route information is required by other SDK modules, especially the Network Inspector.

Example:

    PUSH /transfer

Current route becomes:

    /transfer

Then:

    POST /api/validate

The network event should capture:

    screen: /transfer

The routing module should expose current route context through a lightweight abstraction.

Do not make the Network Inspector depend directly on NavigatorObserver.

Conceptually:

    Routing Observer
           ↓
    Route Context Store
           ↓
       Current Route
           ↓
    Network Inspector

---

## Route Context Provider

Prefer a small abstraction for reading current route information.

Conceptually:

    abstract interface class QaRouteContext {
      String? get currentRoute;
    }

The exact API may differ.

The goal is to prevent direct coupling between modules.

---

## Navigation Stack

The Routing Observer may maintain a lightweight internal representation of the navigation stack when necessary.

Example:

    [
      '/',
      '/home',
      '/transfer',
    ]

This can help correctly determine:

- Current route
- Previous route
- Pop destination

Do not attempt to recreate the entire Flutter Navigator implementation.

Only track information needed by the QA SDK.

---

## Timeline Integration

Every relevant navigation action must create a QaRouteEvent.

Example timeline:

    14:10:01.000
    PUSH
    / → /login

    14:10:02.200
    POST /api/login
    screen: /login
    status: 200

    14:10:02.700
    REPLACE
    /login → /home

    14:10:03.100
    GET /api/accounts
    screen: /home
    status: 200

    14:10:05.000
    PUSH
    /home → /transfer

The timeline must preserve the real event order.

---

## Screen and API Relationship

One of the primary goals of the SDK is allowing QA to understand which APIs were triggered from which screen.

Example QA representation:

    /login

      POST /api/login
      POST /api/device/register

    /home

      GET /api/accounts
      GET /api/cards
      GET /api/profile

    /transfer

      POST /api/beneficiary/validate
      POST /api/transfer/validate

The Routing Observer provides the route context.

The Network Inspector captures that context when the request starts.

Do not build separate duplicated API collections inside the Routing Observer.

The central Event Timeline remains the source of truth.

---

## Nested Navigators

Flutter applications may contain nested Navigators.

Examples include:

- Bottom navigation tabs
- Shell routes
- Nested flows
- Modal navigation flows

The MVP does not need to automatically discover every Navigator in the widget tree.

However, the architecture must not prevent multiple QaRouteObserver instances from reporting into the same timeline.

Example:

    rootNavigatorObservers: [
      qaRootObserver,
    ]

and potentially:

    nestedNavigatorObservers: [
      qaNestedObserver,
    ]

Do not use global assumptions that only one Navigator can exist.

---

## Duplicate Events

Multiple observers or routing integrations may accidentally produce duplicate events.

Avoid introducing complex deduplication in the MVP unless required.

However, event sources should contain enough information to diagnose duplicate reporting.

Do not silently discard legitimate navigation events based only on route names.

Two consecutive pushes to the same route name may be valid.

---

## Dialogs and Modal Routes

Flutter navigation may include:

- DialogRoute
- ModalBottomSheetRoute
- PopupRoute
- PageRoute

The MVP should primarily focus on meaningful screen navigation.

The architecture should allow configuration for whether non-page routes are included.

Conceptually:

    QaRoutingConfig(
      includeDialogs: false,
      includeBottomSheets: false,
    )

Safe MVP defaults may exclude noisy modal routes from the main QA timeline.

Do not permanently hardcode this behavior.

---

## Route Filtering

The host application should be able to ignore specific routes.

Conceptually:

    QaRoutingConfig(
      ignoredRoutes: {
        '/splash',
        '/internal-loading',
      },
    )

Ignored routes should not generate normal route timeline events.

This configuration should be optional.

---

## Route Filtering Callback

For advanced applications, allow an optional filter callback.

Conceptually:

    shouldTrackRoute: (route) {
      return route.settings.name != '/splash';
    }

Do not require this callback for normal usage.

---

## Unknown Routes

Unknown or unnamed routes must never crash the SDK.

Example representation:

    <unnamed-route>

or another consistent internal fallback.

If a custom resolver exists, use it before falling back.

---

## Disabled Mode

When the QA SDK is disabled:

- Do not create route events.
- Do not update unnecessary QA navigation state.
- Do not notify the timeline.
- Avoid unnecessary allocations.

The observer may still be registered by the host application, but its runtime overhead should remain minimal.

---

## Failure Safety

Routing inspection must never interfere with host navigation.

If:

- Route resolution fails
- Custom resolver throws
- Event creation fails
- Timeline publishing fails

the host Navigator must continue normally.

The QA SDK observes navigation.

It does not own navigation.

---

## UI Independence

The Routing Observer must not know about:

- Floating buttons
- Bottom sheets
- Inspector widgets
- Export widgets
- Notes UI

Its responsibility is:

    Navigator
        ↓
    Observe navigation
        ↓
    Resolve route information
        ↓
    Update route context
        ↓
    Create QaRouteEvent
        ↓
    Event Timeline

---

## Testing Requirements

Add tests covering at least:

1. Push navigation.
2. Pop navigation.
3. Replace navigation.
4. Remove navigation.
5. Correct from route.
6. Correct to route.
7. Current route after push.
8. Current route after pop.
9. Current route after replace.
10. Unnamed routes.
11. Custom route resolver.
12. Ignored routes.
13. Route filtering.
14. Multiple sequential navigation events.
15. Network route context compatibility.
16. Disabled mode.
17. Resolver failure does not break navigation.
18. Timeline failure does not break navigation.

---

## Example QA Output

The Routing Inspector should eventually allow the QA interface to display:

    Navigation Flow

    14:20:01
    PUSH
    / → /login

    14:20:05
    REPLACE
    /login → /home

    14:20:10
    PUSH
    /home → /accounts

    14:20:14
    PUSH
    /accounts → /account/details

    14:20:20
    POP
    /account/details → /accounts

This should make it possible to understand exactly how the user reached the problematic screen.

---

## Do Not

Do not:

- Control navigation.
- Replace the host Navigator.
- Require a specific routing package.
- Assume every route has a name.
- Crash on unnamed routes.
- Couple routing directly to Dio.
- Couple routing directly to UI.
- Create separate event history outside the central timeline.
- Introduce state-management dependencies.
- Recreate Flutter Navigator internally.
- Assume only one Navigator exists.
- Treat every stack mutation as a visible screen transition.

---

## Definition of Done

Routing Observer work is complete only when:

1. Push is tracked correctly.
2. Pop is tracked correctly.
3. Replace is tracked correctly.
4. Remove is tracked correctly.
5. From/to route semantics are correct.
6. Current route context is maintained.
7. Route events are published to the central Event Timeline.
8. Network Inspector can obtain route context without direct Navigator coupling.
9. Unnamed routes are handled safely.
10. Custom route resolution is supported.
11. Route filtering is supported.
12. Navigation behavior remains completely unchanged.
13. Disabled mode has minimal overhead.
14. Tests cover navigation behavior and failure safety.
15. Flutter 3.35.7 compatibility is preserved.
16. Static analysis and tests pass.