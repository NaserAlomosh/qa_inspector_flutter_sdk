# Testing Skill

## Purpose

The Testing skill defines how the QA SDK must be validated as a complete system.

Testing must verify both:

- Individual modules
- End-to-end QA workflows

The SDK is not complete when isolated classes pass unit tests while the full flow is broken.

The main system flow is:

    Host Application
        ↓
    Route Observation
        ↓
    Network Inspection
        ↓
    Sensitive Data Masking
        ↓
    Event Timeline
        ↓
    QA Overlay
        ↓
    Notes
        ↓
    Step-Based Report
        ↓
    PNG / Copy

Testing should prove that this complete flow behaves correctly, safely, and predictably.

---

## Core Principles

When adding or modifying SDK functionality:

1. Test observable behavior.
2. Test cross-module integration.
3. Test failure isolation.
4. Test disabled mode.
5. Test sensitive-data protection.
6. Test chronological correctness.
7. Test screen-to-API association.
8. Test report output structure.
9. Avoid brittle implementation-specific tests.
10. Preserve compatibility with Flutter 3.35.7.

---

## Testing Layers

The SDK should use multiple testing layers.

Recommended:

    Unit Tests
        ↓
    Widget Tests
        ↓
    Integration Tests

Each layer has a different purpose.

Do not attempt to test everything using only widget tests or only unit tests.

---

## Unit Tests

Use unit tests for logic-heavy modules.

Examples:

- Event Timeline
- Sanitizer
- Network event transformation
- Route context tracking
- Report data building
- Filtering
- Grouping
- Truncation
- Configuration behavior

Unit tests should remain fast and deterministic.

---

## Widget Tests

Use widget tests for QA interface behavior.

Examples:

- Floating QA button
- Inspector opening
- Timeline rendering
- API details
- Route history
- Notes input
- Clear confirmation
- Export trigger
- Copy trigger
- Disabled overlay behavior

Do not depend on real backend APIs in widget tests.

---

## Integration Tests

Use integration tests for complete workflows.

The MVP should have at least one representative host application flow.

Example:

    Launch app
        ↓
    Open Home
        ↓
    API called
        ↓
    Navigate to Transfer
        ↓
    API called
        ↓
    Navigate to Confirm
        ↓
    API fails
        ↓
    Open QA Inspector
        ↓
    Add note
        ↓
    Generate report

The final report should correctly describe the full sequence.

---

## Test Host Application

Maintain a lightweight example/test host application.

Its purpose is to simulate real SDK integration.

It should include:

- Multiple screens
- Navigator
- Dio
- Successful API simulation
- Failed API simulation
- Delayed API simulation
- Parallel API simulation
- Notes
- QA Inspector

Do not make the test host application unnecessarily complex.

It exists to validate integration, not demonstrate production architecture.

---

## Minimum Flutter Compatibility

All tests must remain compatible with:

    Flutter 3.35.7

Do not write tests that only pass on newer Flutter APIs if the SDK claims 3.35.7 support.

CI should use the minimum supported Flutter version when practical.

---

## Recommended CI Matrix

At minimum, test against:

    Flutter 3.35.7

and:

    Current supported stable Flutter version

This catches both:

- Minimum-version regressions
- Newer-version compatibility issues

Do not assume code compiling on the latest Flutter automatically works on the minimum version.

---

## Static Analysis

Every change should pass:

    flutter analyze

No new analyzer errors should be introduced.

Avoid adding broad ignore rules simply to make analysis pass.

Fix the underlying issue when practical.

---

## Formatting

Code should pass standard Dart formatting.

Conceptually:

    dart format .

Avoid unrelated formatting changes across the whole repository when making small feature changes.

---

## Event Timeline Tests

Test at least:

1. Event addition.
2. Event insertion order.
3. Mixed event types.
4. Max event limit.
5. Oldest event eviction.
6. Timeline clear.
7. Snapshot behavior.
8. Snapshot immutability.
9. Listener notification.
10. Disabled behavior if timeline is gated.
11. Sequential event IDs.
12. Multiple rapid additions.

Example:

    add route event
    add network event
    add route event

Expected order:

    route
    network
    route

Do not sort incorrectly based on asynchronous completion.

---

## Network Inspector Tests

Test at least:

1. Successful GET.
2. Successful POST.
3. Failed response.
4. DioException.
5. Cancelled request.
6. Request duration.
7. Status code.
8. Request body.
9. Response body.
10. Query parameters.
11. Headers.
12. Route context.
13. Request start route is preserved.
14. Payload truncation.
15. Binary payload handling.
16. FormData handling.
17. Multipart handling.
18. Multiple Dio instances.
19. Inspection failure safety.
20. Disabled mode.
21. Original request remains unchanged.
22. Original response remains unchanged.

---

## Request-Start Route Test

This is a critical behavior.

Scenario:

    Current screen:
    /transfer

Then:

    POST /api/validate starts

Immediately afterward:

    PUSH /confirm

Then:

    POST /api/validate returns

Expected:

    Network event screen:
    /transfer

NOT:

    /confirm

The originating route must be captured when the request starts.

---

## Parallel API Tests

Scenario:

    Screen:
    /home

Start:

    GET /accounts

Then shortly after:

    GET /cards

Suppose:

    /cards finishes first
    /accounts finishes second

The dedicated report should preserve request-start ordering when grouping APIs.

Expected:

    API 1
    GET /accounts

    API 2
    GET /cards

Do not reorder solely based on response completion time.

---

## Routing Observer Tests

Test at least:

1. didPush.
2. didPop.
3. didReplace.
4. didRemove.
5. Correct from route.
6. Correct to route.
7. Current route after push.
8. Current route after pop.
9. Current route after replace.
10. Unnamed route.
11. Custom resolver.
12. Resolver failure.
13. Ignored route.
14. Filter callback.
15. Multiple observers.
16. Nested navigator compatibility where applicable.
17. Disabled mode.

---

## Sensitive Data Masking Tests

This area must have strong coverage.

Test at least:

1. password
2. passcode
3. pin
4. otp
5. token
6. accessToken
7. access_token
8. refreshToken
9. refresh_token
10. idToken
11. id_token
12. sessionId
13. session_id
14. authorization header
15. cookie
16. API key
17. custom sensitive keys
18. custom sensitive headers
19. default + custom merge
20. case-insensitive matching
21. exact matching
22. no substring false positives
23. nested maps
24. nested lists
25. maps inside lists
26. query parameters
27. sanitized URL
28. response body
29. request body
30. original object unchanged
31. sanitization failure
32. recursion limits
33. circular references
34. FormData
35. binary content

---

## Security Regression Test

Add at least one test that inspects the entire stored QaNetworkEvent and verifies that known raw secrets do not appear anywhere.

Example raw values:

    superSecretPassword123
    otp987654
    bearer-token-abc
    card-number-1234

After event creation:

    event.toString()
    serialized event representation
    request fields
    response fields
    headers
    URL

must contain none of those raw values.

This protects against future accidental leakage.

---

## QA Overlay Tests

Test at least:

1. Floating button visible when enabled.
2. Floating button hidden when disabled.
3. Tap opens inspector.
4. Closing inspector preserves host screen.
5. Timeline displays events.
6. API tab displays network events.
7. Route tab displays route events.
8. Notes can be typed.
9. Notes remain during session.
10. API details open.
11. Sanitized request is shown.
12. Sanitized response is shown.
13. Failed API is visually distinguishable.
14. Search works.
15. Filters work.
16. Clear confirmation appears.
17. Clear removes session events.
18. New events can be collected after clear.
19. Copy delegates correctly.
20. Export delegates correctly.
21. Large lists use lazy rendering.
22. Keyboard does not break Notes UI.

---

## Screen Grouping Tests

The UI and report should group APIs under the correct originating screen.

Scenario:

    /home
      GET /accounts
      GET /cards

    /transfer
      POST /validate

Expected grouping:

    /home
        /accounts
        /cards

    /transfer
        /validate

Do not group based on response time.

---

## Notes Tests

Test:

1. Empty notes.
2. Normal notes.
3. Multiline notes.
4. Large notes within configured limit.
5. Notes included in report.
6. Notes included in copy output.
7. Clear session behavior.

Notes are session data only for the MVP.

---

## Step-Based Report Tests

The report must be tested as a user journey.

Scenario:

    /home
        GET /accounts → 200

    PUSH /transfer

    /transfer
        POST /validate → 200

    PUSH /confirm

    /confirm
        POST /transfer → 400

Expected report structure:

    STEP 1
    /home
    GET /accounts
    200

    NEXT ACTION
    PUSH
    /home → /transfer

    STEP 2
    /transfer
    POST /validate
    200

    NEXT ACTION
    PUSH
    /transfer → /confirm

    STEP 3
    /confirm
    POST /transfer
    400

The report must not separate routes and APIs into unrelated primary sections.

---

## Report Data Tests

Test at least:

1. Report snapshot.
2. Current route.
3. Notes.
4. Screen steps.
5. API grouping.
6. API status.
7. Request data.
8. Response data.
9. Failed API.
10. Successful API.
11. Navigation between steps.
12. No-API screen.
13. Delayed API response.
14. Parallel API requests.
15. Truncated response.
16. Binary response.
17. Empty session.
18. Large session.
19. Report limits.
20. Sanitized content only.

---

## PNG Export Tests

Where practical, test:

1. PNG bytes are generated.
2. PNG output is non-empty.
3. Tall report can render.
4. Multiple steps render.
5. Large responses do not cause uncontrolled output.
6. Export failure returns safe failure result.

Avoid brittle pixel-perfect golden tests for the entire report unless visual stability is intentionally required.

---

## Golden Tests

Golden tests may be useful for a few stable UI components such as:

- API status card
- Route event card
- Report step header

Do not create dozens of fragile golden tests that fail because of minor Flutter rendering differences.

Use them selectively.

---

## Copy Report Tests

Verify copied text contains:

- QA notes
- Screens
- Navigation
- API methods
- Endpoints
- Status codes
- Sanitized request
- Sanitized response

Verify copied text does NOT contain raw sensitive values.

---

## Disabled Mode End-to-End Test

This test is mandatory.

Initialize:

    enabled = false

Then perform:

- Navigation
- API calls
- Screen changes

Expected:

- No QA button.
- No route events.
- No network events.
- No report.
- No notes UI.
- No significant QA processing.

This proves production-safe integration.

---

## Host Application Safety Tests

Explicitly test that SDK failures do not affect host behavior.

Examples:

### Sanitizer throws

Expected:

    API still succeeds normally.

### Timeline throws

Expected:

    API still returns normally.

### Route resolver throws

Expected:

    Navigation still succeeds.

### Export fails

Expected:

    Host application remains usable.

### QA overlay error

Expected:

    Host business state remains unchanged.

---

## Clear Session Integration Test

Scenario:

    collect 10 events
        ↓
    clear session
        ↓
    timeline becomes empty
        ↓
    trigger new API
        ↓
    new event appears

Clear must not permanently disable collection.

---

## Multiple Open/Close Test

Repeat:

    Open QA Inspector
    Close QA Inspector

multiple times.

Expected:

- One floating button.
- One inspector at a time.
- No duplicate listeners.
- No duplicated events.
- No controller disposal errors.

---

## Memory-Oriented Tests

Where practical, verify architecture rather than exact heap values.

Check that events do not contain:

- BuildContext
- Widget
- Route objects
- Dio Response
- RequestOptions

The event model should contain lightweight captured values only.

---

## Test Data

Use clearly fake values in tests.

Example:

    accountNumber: 123456789
    token: fake-token
    otp: 123456

Do not use real user/customer information.

---

## Deterministic Time

Where timestamps matter, inject or abstract clock behavior if this improves test reliability.

Avoid tests that depend on exact wall-clock timing.

For duration tests, use reasonable ranges or controlled timing.

---

## Avoid Arbitrary Delays

Do not fill tests with:

    Future.delayed(Duration(seconds: 2))

unless necessary.

Prefer deterministic test control.

Integration tests may simulate latency intentionally.

---

## Test Naming

Tests should describe behavior.

Good:

    captures request-start route when response finishes on another screen

Good:

    masks custom sensitive keys in nested response lists

Bad:

    testNetwork1

Bad:

    routeTest

A failing test name should explain what behavior broke.

---

## Test Organization

Recommended structure:

    test/
    ├── core/
    ├── events/
    ├── network/
    ├── routing/
    ├── security/
    ├── ui/
    ├── export/
    └── integration/

Exact structure may follow repository architecture.

Keep tests easy to discover.

---

## No Over-Mocking

Avoid mocking every internal class.

Prefer real lightweight implementations for:

- Timeline
- Sanitizer
- Route context
- Report builder

Mock only external or expensive boundaries when useful.

Over-mocking can make tests pass while actual integration is broken.

---

## Public API Tests

Test the SDK as a consumer would use it.

Example integration:

    QaInspector(
      enabled: true,
      child: MyApp(),
    )

and:

    dio.interceptors.add(
      QaNetworkInterceptor(...),
    );

and:

    navigatorObservers: [
      QaRouteObserver(...),
    ]

Public integration APIs should be covered because they are what package users depend on.

---

## Breaking Change Protection

Important public APIs should have tests around expected behavior.

Examples:

- QaInspector
- QaNetworkInterceptor
- QaRouteObserver
- Configuration models

Do not casually rename or change public APIs without deliberate compatibility decisions.

---

## Example End-to-End Acceptance Scenario

A representative MVP test should simulate:

    Application starts

    STEP 1
    /login

    POST /login
    200

    REPLACE

    STEP 2
    /home

    GET /accounts
    200

    GET /cards
    200

    PUSH

    STEP 3
    /transfer

    POST /validate
    200

    PUSH

    STEP 4
    /transfer/confirm

    POST /transfer
    400

QA then:

    opens inspector
        ↓
    sees failed API
        ↓
    adds note
        ↓
    exports report

Expected report:

    STEP 1
    /login
    POST /login → 200

    STEP 2
    /home
    GET /accounts → 200
    GET /cards → 200

    STEP 3
    /transfer
    POST /validate → 200

    STEP 4
    /transfer/confirm
    POST /transfer → 400

    QA Note:
    Confirm action failed.

The response and request data must be included according to report rules and remain sanitized.

---

## Required Commands Before Completion

Before considering implementation complete, run:

    dart format .

    flutter analyze

    flutter test

If an example/integration test project exists, also run its relevant tests.

Do not claim completion while known tests are failing.

---

## Change Discipline

When Codex modifies the SDK:

1. Inspect relevant existing tests.
2. Implement the smallest coherent change.
3. Add or update tests for changed behavior.
4. Avoid unrelated refactors.
5. Run formatting.
6. Run static analysis.
7. Run relevant tests.
8. Report any remaining limitation clearly.

Do not rewrite large working areas merely to make testing easier.

---

## Do Not

Do not:

- Test only isolated implementation details.
- Skip disabled-mode testing.
- Skip security tests.
- Use real customer data.
- Depend on live production APIs.
- Depend on Jira.
- Depend on external network availability.
- Add arbitrary sleeps everywhere.
- Overuse mocks.
- Create fragile full-app golden tests.
- Ignore Flutter 3.35.7 compatibility.
- Mark work complete while tests or analysis fail.
- Allow tests to expose sensitive fixture values in generated artifacts unnecessarily.

---

## MVP Acceptance Criteria

The complete SDK MVP should pass a flow proving that:

1. The SDK can be enabled using configuration.
2. A global floating QA button appears.
3. Navigation is captured.
4. APIs are captured.
5. Each API is associated with the screen where it started.
6. Request data is captured safely.
7. Response data is captured safely.
8. Status code is captured.
9. Duration is captured.
10. Sensitive information is masked.
11. Custom sensitive keys work.
12. Events appear in chronological order.
13. QA can inspect APIs.
14. QA can inspect routes.
15. QA can add notes.
16. QA can clear the session.
17. QA can copy the report.
18. QA can generate a PNG report.
19. The report is step-based.
20. Each screen step contains its related APIs.
21. Each API includes status and returned data.
22. Failed APIs are easy to identify.
23. Delayed API responses remain attached to their originating screen.
24. Parallel requests preserve request-start ordering.
25. The SDK does not change host application behavior.
26. Disabled mode produces no QA UI or event collection.
27. Host app continues working if an SDK component fails.
28. Flutter 3.35.7 compatibility is preserved.
29. flutter analyze passes.
30. flutter test passes.

---

## Definition of Done

Testing work is complete only when:

1. Core modules have unit coverage.
2. QA UI has widget coverage.
3. Sensitive-data masking has strong regression coverage.
4. Network and route integration is covered.
5. Screen-to-API association is tested.
6. Step-based report generation is tested.
7. Disabled mode is tested end-to-end.
8. Failure isolation is tested.
9. Copy and PNG export are tested.
10. At least one realistic full QA journey passes.
11. Minimum Flutter compatibility is validated.
12. Static analysis passes.
13. All required tests pass.