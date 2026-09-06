# QA Overlay UI Skill

## Purpose

The QA Overlay UI is the main in-app interface used by Quality Assurance engineers to inspect runtime information collected by the Flutter QA SDK.

The UI must allow QA engineers to quickly understand:

- What screens the user visited
- What navigation actions occurred
- Which APIs were called
- Which APIs belong to each screen
- Which requests succeeded or failed
- Request and response details
- The chronological event timeline
- QA notes
- Export and copy actions

The QA Overlay must be lightweight, non-intrusive, easy to use, and completely isolated from the host application's business logic.

The UI must consume data from the central Event Timeline.

It must never become another source of truth.

---

## Core Principles

When implementing or modifying the QA Overlay UI:

1. Keep the interface simple enough for non-developers.
2. Prioritize QA workflows over developer tooling complexity.
3. Do not require Flutter DevTools or IDE access.
4. Do not modify host application navigation.
5. Do not modify host application state.
6. Do not introduce a state-management dependency.
7. Consume data from the central Event Timeline.
8. Avoid unnecessary rebuilds.
9. Keep the overlay isolated from the host application.
10. Make important failures visually easy to identify.
11. Do not expose sensitive information.
12. The overlay must disappear completely when the SDK is disabled.

---

## Target User Experience

The normal QA workflow should be:

    Open application
        ↓
    Use application normally
        ↓
    QA SDK collects events silently
        ↓
    QA notices an issue
        ↓
    Tap floating QA button
        ↓
    Inspector opens
        ↓
    Review Timeline / APIs / Routes
        ↓
    Add Notes
        ↓
    Copy or Export report

Opening the inspector should not interrupt or reset the current application flow.

Closing the inspector should return the QA engineer to exactly where they were.

---

## Floating Action Button

The primary entry point should be a floating QA button displayed above the host application.

The button should:

- Remain accessible across application screens
- Not depend on individual Scaffold widgets
- Be visually recognizable
- Have a compact size
- Avoid blocking important application controls
- Open the QA Inspector when tapped
- Support repositioning if practical
- Preserve its position during the current runtime session if repositioning is supported

The floating button must NOT require developers to manually add it to every screen.

---

## Overlay Integration

Prefer integrating the QA UI at a high level in the application.

Target developer experience:

    QaInspector(
      enabled: qaToolsEnabled,
      child: const MyApp(),
    )

The wrapper should be responsible for displaying the QA entry point.

Do not require modifications to individual application screens.

Do not require each Scaffold to include a QA widget.

---

## Overlay Architecture

Conceptually:

    Host Application
          │
          ▼
    QaInspector Wrapper
          │
          ├── Host Application UI
          │
          └── QA Overlay Layer
                  │
                  └── Floating QA Button

When opened:

    Floating QA Button
          ↓
    QA Inspector
          ↓
    ┌──────────────────────────┐
    │ Timeline                 │
    │ APIs                     │
    │ Routes                   │
    │ Notes                    │
    └──────────────────────────┘

The exact visual design may evolve.

Keep data collection independent from this UI.

---

## Inspector Presentation

For the MVP, prefer a full-screen inspector page or large modal sheet that provides enough space for network payloads and timeline information.

The implementation must not force the host application to define a QA-specific route.

Prefer Overlay, Navigator overlay, or another isolated Flutter mechanism where appropriate.

Do not permanently add QA routes to the host application's business navigation flow unless there is a strong reason.

---

## Main Sections

The inspector should provide four primary sections:

    Timeline

    APIs

    Routes

    Notes

The UI may use:

- Tabs
- Navigation bar
- Segmented controls
- Another compact navigation mechanism

Choose the simplest implementation that works well on mobile devices.

---

## Timeline Section

The Timeline is the primary combined view.

It must display network and routing events in chronological order.

Example:

    14:20:01

    PUSH
    / → /login

    ------------------------

    14:20:02

    POST /api/login
    200
    421 ms

    Screen: /login

    ------------------------

    14:20:03

    REPLACE
    /login → /home

    ------------------------

    14:20:04

    GET /api/accounts
    200
    180 ms

    Screen: /home

    ------------------------

    14:20:05

    GET /api/cards
    500
    260 ms

    Screen: /home

The Timeline must consume the central Event Timeline directly.

Do not create a second timeline state inside the UI.

---

## Timeline Event Cards

Different event types should be visually distinguishable.

Examples:

    ROUTE
    PUSH
    /home → /transfer

and:

    API
    POST /api/transfer
    400
    320 ms

Do not overload cards with every possible field.

Show summary information first.

Allow the QA engineer to open details when needed.

---

## API Section

The APIs section should display captured network requests.

Each API row should initially show useful summary information:

- HTTP method
- Path or endpoint
- Status code
- Duration
- Screen/route
- Request time

Example:

    GET
    /api/accounts

    200
    184 ms

    /home

Failed APIs must be easy to identify.

Do not require opening every request to discover whether it failed.

---

## API Ordering

By default, APIs should appear in chronological order.

The most recent API may appear first in the dedicated API section if this improves usability.

However, the main Timeline must remain chronological.

Document and test whichever API list ordering is selected.

---

## API Details

Tapping an API should open a detailed view.

The detailed view should support:

    General

    Headers

    Request

    Response

    Error

General information should include:

- Method
- URL
- Path
- Status
- Duration
- Screen
- Request timestamp

---

## API Request Details

The request view should display sanitized:

- Query parameters
- Headers
- Request body

JSON should be formatted for readability when possible.

Example:

    {
      "amount": 100,
      "currency": "JOD",
      "otp": "***"
    }

Do not perform expensive JSON formatting while the request is being captured.

Formatting belongs to presentation time.

---

## API Response Details

The response view should display sanitized response information.

Example:

    {
      "status": false,
      "message": "Invalid beneficiary"
    }

If the response was truncated, clearly indicate:

    Response truncated

If the response is binary:

    Binary content omitted

Never attempt to render raw binary data.

---

## Copy API Data

Useful API values should be copyable.

At minimum support copying:

- URL
- Request body
- Response body
- Complete sanitized API details

Copied information must remain sanitized.

Never provide a copy action that exposes the original unmasked value.

---

## API Filtering

The API section should support simple filters.

Recommended MVP filters:

    All

    Success

    Failed

Optionally:

    Cancelled

Do not build an overly complex filtering system for the MVP.

---

## API Search

The QA engineer should be able to search APIs.

Search should support at least:

- URL
- Path
- HTTP method

Example:

    search: transfer

could match:

    /api/transfer/validate
    /api/transfer/confirm
    /api/transfer/history

Search should operate on already collected data.

---

## Routes Section

The Routes section should show navigation history separately from the combined Timeline.

Example:

    14:20:01
    PUSH
    / → /login

    14:20:05
    REPLACE
    /login → /home

    14:20:10
    PUSH
    /home → /accounts

    14:20:15
    PUSH
    /accounts → /account/details

    14:20:20
    POP
    /account/details → /accounts

The action must be clearly visible.

Supported actions include:

- PUSH
- POP
- REPLACE
- REMOVE

---

## Screen-Based View

The SDK should support presenting collected information grouped by screen.

This is one of the key QA features.

Example:

    /home

      APIs: 3

      GET /api/accounts       200
      GET /api/cards          200
      GET /api/profile        500

    /transfer

      APIs: 2

      POST /api/validate      200
      POST /api/transfer      400

This grouping must be derived from the central Event Timeline.

Do not create independent screen-specific API storage.

---

## Screen Details

When a QA engineer opens a screen group, show useful information such as:

- Route name
- Navigation action that entered the screen
- Time entered
- APIs triggered from the screen
- Number of successful APIs
- Number of failed APIs

Keep the MVP focused on information already collected.

Do not introduce screen performance profiling unless explicitly requested.

---

## Notes Section

The QA engineer must be able to write notes about the issue.

The MVP should provide a simple multiline text input.

Example:

    When I press Confirm Transfer,
    the loader closes but the screen does not navigate.

Notes should remain available while the current QA SDK session is alive.

The MVP does not require persistent notes across application restarts.

---

## Notes Behavior

Notes should:

- Be editable
- Be included in report generation
- Be included in image export
- Be included in copyable report text

Do not send notes to external services.

No Jira or backend integration is required for the MVP.

---

## Quick Note Access

Consider allowing the Notes field to be quickly accessible from the inspector.

QA should not need to navigate through several screens just to add a note.

Do not introduce complex issue forms in the MVP.

---

## Summary

The inspector should provide a compact session summary.

Useful information may include:

    Screens visited: 6

    API requests: 18

    Successful: 15

    Failed: 3

    Current screen:
    /transfer/confirm

This information should be calculated from the current timeline.

Do not maintain duplicate counters unless required for performance.

---

## Clear Session

Provide a Clear action.

The action should clear:

- Timeline events
- Network history
- Route history derived from the timeline
- QA notes if the user explicitly confirms clearing the complete session

Because Clear is destructive, require a lightweight confirmation.

Example:

    Clear current QA session?

    This will remove collected events and notes.

    Cancel
    Clear

After clearing, collection must continue normally.

---

## Export Action

The inspector should expose an Export action.

The actual report/export implementation belongs to the Report Export module.

The UI should only trigger it.

Conceptually:

    QA Overlay
        ↓
    Export
        ↓
    Report Export Service
        ↓
    Image

Do not implement report generation logic directly inside UI widgets.

---

## Copy Report

Provide a Copy action for a text representation of the current QA report.

Example:

    QA Report

    Current Screen:
    /transfer/confirm

    Notes:
    Confirm button does not navigate.

    Navigation:
    /home
    → /transfer
    → /transfer/confirm

    Failed APIs:

    POST /api/transfer
    Status: 400
    Duration: 320ms

Copied report data must be sanitized.

---

## Live Updates

The inspector should update when new timeline events arrive.

Example:

QA keeps the inspector open.

A new API request occurs.

The API should appear without closing and reopening the inspector.

Use the timeline's notification mechanism.

Do not poll for changes.

---

## Rebuild Performance

Avoid rebuilding the entire inspector for every small event when unnecessary.

Prefer rebuilding only affected sections.

Do not rebuild the host application when QA events change.

The host application must remain isolated from QA UI state.

---

## Large Lists

Timeline and API history may contain up to the configured event limit.

Use lazy list widgets such as:

    ListView.builder

Do not create hundreds of expensive widgets eagerly.

---

## JSON Rendering

Large JSON objects should not freeze the UI.

Prefer:

- Lazy detail rendering
- Formatting only when details are opened
- Truncated payloads from the Network Inspector

Do not syntax-highlight enormous payloads in the MVP unless it is lightweight.

Readable formatted text is sufficient.

---

## Floating Button Position

The floating QA button should avoid common application interaction areas where possible.

If draggable behavior is implemented:

- Keep the button inside screen bounds
- Respect safe areas
- Prevent it from becoming unreachable
- Keep position only in memory for MVP

Persistent position storage is not required.

---

## Safe Areas

All QA UI must respect:

- SafeArea
- Display cutouts
- System navigation areas
- Keyboard insets

The inspector must remain usable on both Android and iOS.

---

## Keyboard Behavior

The Notes section must work correctly with the keyboard.

The keyboard should not permanently hide:

- Notes input
- Save/update interaction
- Inspector navigation

Use appropriate scrolling and inset handling.

---

## Accessibility

Use reasonable:

- Touch target sizes
- Text contrast
- Labels
- Semantics where appropriate

Do not make the floating button unnecessarily tiny.

---

## Theme Isolation

The QA interface should have predictable styling.

Do not assume the host application theme contains every required style.

At the same time, avoid globally changing the host application's Theme.

QA UI styling must remain local to QA widgets.

---

## Localization

English is sufficient for the initial MVP unless localization is explicitly requested.

Do not couple the SDK to the host application's localization system.

Design UI strings so localization can be introduced later without rewriting architecture.

---

## Error Handling

QA UI failures must not crash the host application.

Examples:

- Invalid JSON formatting
- Missing route information
- Missing response body
- Export failure
- Clipboard failure

Show a safe fallback where appropriate.

The QA tool failing must not take the banking, commerce, or host application down with it.

---

## Disabled Mode

When the SDK is disabled:

- Do not render the floating button.
- Do not create inspector overlays.
- Do not subscribe UI listeners to the timeline.
- Do not allocate unnecessary UI controllers.
- Do not expose any QA UI interaction.

Conceptually:

    if (!enabled) {
      return child;
    }

Disabled behavior should be extremely lightweight.

---

## Production Release Behavior

Do not assume:

    kDebugMode == QA enabled

The SDK may intentionally be enabled in a QA release build.

Activation should come from SDK configuration.

Example:

    const qaEnabled = bool.fromEnvironment(
      'QA_TOOLS',
      defaultValue: false,
    );

Then:

    QaInspector(
      enabled: qaEnabled,
      child: const MyApp(),
    )

---

## Host Application Independence

The QA Overlay must not require:

- Bloc
- Cubit
- Riverpod
- Provider
- GetX
- Redux
- MobX

The host application may use any of them.

The SDK should not care.

---

## Navigation Independence

Opening the inspector must not require the host application to expose its Navigator globally unless absolutely necessary.

Prefer an isolated overlay/presentation mechanism.

Do not push QA routes through the application's business navigation unless intentionally designed.

---

## MVP UI Structure

Recommended initial structure:

    QA Inspector

    ┌─────────────────────────────────┐
    │ Summary                         │
    │                                 │
    │ 18 APIs   3 Failed   6 Screens │
    ├─────────────────────────────────┤
    │                                 │
    │ Timeline | APIs | Routes | Notes│
    │                                 │
    ├─────────────────────────────────┤
    │                                 │
    │ Selected section content        │
    │                                 │
    │                                 │
    ├─────────────────────────────────┤
    │ Clear       Copy       Export   │
    └─────────────────────────────────┘

This is a conceptual layout.

Implementation may improve the design while preserving simplicity.

---

## Suggested API List Item

Conceptually:

    ┌─────────────────────────────────┐
    │ POST                  400       │
    │ /api/transfer/validate          │
    │                                 │
    │ /transfer/confirm     326 ms    │
    └─────────────────────────────────┘

Tapping opens details.

---

## Suggested Route List Item

Conceptually:

    ┌─────────────────────────────────┐
    │ PUSH                            │
    │                                 │
    │ /home                           │
    │    ↓                            │
    │ /transfer                       │
    │                                 │
    │ 14:20:10.320                    │
    └─────────────────────────────────┘

---

## Testing Requirements

Add widget/unit tests covering at least:

1. Floating QA button appears when enabled.
2. Floating QA button does not appear when disabled.
3. Floating button opens inspector.
4. Inspector closes without affecting host app.
5. Timeline displays mixed events.
6. API list displays network events.
7. Failed API is distinguishable.
8. API details can be opened.
9. Request data is displayed.
10. Response data is displayed.
11. Sanitized values remain masked.
12. Routes section displays navigation events.
13. Push is displayed correctly.
14. Pop is displayed correctly.
15. Replace is displayed correctly.
16. Screen grouping works.
17. APIs are grouped with correct route.
18. Notes can be entered.
19. Notes remain during current session.
20. Clear session works.
21. Clear confirmation works.
22. Copy action receives sanitized data.
23. Export action delegates to exporter.
24. Timeline updates while inspector is open.
25. Large event lists use lazy rendering.
26. Missing data does not crash UI.
27. Keyboard does not break Notes UI.
28. QA UI changes do not rebuild host application unnecessarily.

---

## Do Not

Do not:

- Put event collection logic inside widgets.
- Create another timeline inside the UI.
- Modify host application state.
- Modify host navigation.
- Require QA widgets on every screen.
- Introduce a state-management framework.
- Display unmasked sensitive values.
- Copy unmasked sensitive values.
- Render raw binary content.
- Perform expensive JSON formatting during collection.
- Persist QA notes in the MVP.
- Integrate Jira in the MVP.
- Add issue-management workflows.
- Build a replacement for Flutter DevTools.
- Allow QA UI failures to crash the host application.

---

## Definition of Done

QA Overlay UI work is complete only when:

1. QA can open the inspector from a global floating button.
2. Host screens require no individual QA widget integration.
3. Timeline events are visible chronologically.
4. APIs can be viewed separately.
5. API details show sanitized request and response information.
6. Routes can be viewed separately.
7. Navigation actions are clearly identified.
8. APIs can be associated with their originating screens.
9. QA can enter notes.
10. QA can clear the current session.
11. QA can trigger Copy.
12. QA can trigger Export.
13. Inspector updates when new events arrive.
14. Host application behavior remains unchanged.
15. Disabled mode renders no QA interface.
16. UI remains performant with the configured event limit.
17. Tests cover primary QA workflows.
18. Flutter 3.35.7 compatibility is preserved.
19. Static analysis and tests pass.