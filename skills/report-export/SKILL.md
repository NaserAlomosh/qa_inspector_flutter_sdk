## Example Final Report

The exported QA report should present the application flow as clear chronological steps.

Each step represents one screen or meaningful navigation state.

Every API request must appear under the screen where the request originally started.

The report should be easy for:

- QA engineers to explain what happened.
- Developers to understand the technical sequence.
- Developers to identify which API caused or contributed to the issue.
- Developers to inspect request, response, status code, duration, and screen context without reconstructing the flow manually.

The report should prioritize readability first, while still exposing useful technical details.

---

## Recommended Report Structure

The report should follow this structure:

    QA REPORT

    Issue Notes

    Session Summary

    Step-by-Step User Flow

Each screen should become a numbered step.

Example:

    STEP 1
    Home Screen

    STEP 2
    Transfer Screen

    STEP 3
    Transfer Confirmation Screen

Each step contains:

- Screen name
- Route name
- How the user reached the screen
- Time the screen was opened
- APIs triggered from this screen
- Status code
- Duration
- Sanitized request
- Sanitized response
- Error information if applicable
- Next navigation action

---

## Report Header

Example:

    QA INSPECTOR REPORT

    Generated:
    2026-09-06 19:30:22

    Current Screen:
    /transfer/confirm

    Total Screens:
    4

    Total APIs:
    7

    Failed APIs:
    1

Keep this section compact.

---

## Issue Notes

QA notes should appear near the top of the report.

Example:

    ISSUE NOTES

    When pressing Confirm Transfer,
    the loader closes but the application
    remains on the confirmation screen.

This allows the developer to understand the reported problem before reading the technical flow.

---

## Step Header

Each screen should have a clear step header.

Example:

    ─────────────────────────────────

    STEP 1

    Screen:
    Home

    Route:
    /home

    Entered At:
    19:20:03.120

    Navigation:
    LOGIN → HOME

    Action:
    REPLACE

    ─────────────────────────────────

Prefer a developer-friendly screen label when available.

If only a route exists, use the route.

Example:

    Screen:
    /home

---

## APIs Inside a Step

Every API started from the screen must appear inside that screen step.

Example:

    APIs Triggered: 3

    API 1

    GET /api/accounts

    Status:
    200 OK

    Duration:
    184 ms

    Request:
    No body

    Response:

    {
      "status": true,
      "accounts": [...]
    }

    ----------------------------

    API 2

    GET /api/cards

    Status:
    200 OK

    Duration:
    210 ms

    Request:
    No body

    Response:

    {
      "status": true,
      "cards": [...]
    }

    ----------------------------

    API 3

    GET /api/profile

    Status:
    500 INTERNAL SERVER ERROR

    Duration:
    330 ms

    Response:

    {
      "status": false,
      "message": "Unexpected server error"
    }

Failed APIs must be visually distinguishable from successful APIs.

---

## API Information Order

For every API, use the same predictable order:

    Method + Endpoint

    Status Code

    Duration

    Request

    Response

    Error

This consistency is important.

Developers should not need to search around the report to find the status code or response.

---

## API Example

Example:

    API 1

    POST /api/transfer/confirm

    Status:
    400 BAD REQUEST

    Duration:
    326 ms

    Request:

    {
      "amount": 100,
      "currency": "JOD",
      "otp": "***"
    }

    Response:

    {
      "status": false,
      "message": "Invalid beneficiary"
    }

If a Dio or network error exists:

    Error:

    DioExceptionType.badResponse

Do not display unnecessary internal implementation information unless it helps debugging.

---

## Successful API

Successful APIs should still show useful response data.

Example:

    GET /api/transfer/fees

    Status:
    200 OK

    Duration:
    140 ms

    Response:

    {
      "fee": 1.25,
      "currency": "JOD"
    }

Do not hide successful responses by default.

Returned backend data may be essential for reproducing or understanding the bug.

Large responses must respect configured truncation limits.

---

## Failed API

Failed APIs should be emphasized.

Example:

    FAILED API

    POST /api/transfer/confirm

    Status:
    400 BAD REQUEST

    Duration:
    326 ms

    Request:

    {
      "amount": 100,
      "currency": "JOD"
    }

    Response:

    {
      "status": false,
      "message": "Invalid beneficiary"
    }

A developer should be able to identify a failed request immediately while scanning the report.

---

## No APIs On Screen

If no APIs were triggered from a screen:

    APIs Triggered:
    None

Do not omit the step.

The screen itself is still part of the user journey.

---

## Navigation Between Steps

At the bottom of each step, display what happened next.

Example:

    NEXT ACTION

    PUSH

    From:
    /home

    To:
    /transfer

Then continue:

    STEP 2

    Screen:
    Transfer

This creates a readable application journey.

---

## Full Example

Conceptually:

    QA INSPECTOR REPORT

    Issue:
    Transfer confirmation does not navigate
    to the success screen.

    ========================================

    STEP 1

    Screen:
    Home

    Route:
    /home

    Entered:
    19:20:01

    APIs Triggered: 2

    ----------------------------------------

    API 1

    GET /api/accounts

    Status:
    200 OK

    Duration:
    184 ms

    Response:

    {
      "status": true,
      "accounts": [...]
    }

    ----------------------------------------

    API 2

    GET /api/profile

    Status:
    200 OK

    Duration:
    130 ms

    Response:

    {
      "name": "N***",
      "customerId": "***"
    }

    ----------------------------------------

    NEXT ACTION

    PUSH

    /home
        ↓
    /transfer

    ========================================

    STEP 2

    Screen:
    Transfer

    Route:
    /transfer

    Entered:
    19:20:10

    APIs Triggered: 2

    ----------------------------------------

    API 1

    POST /api/beneficiary/validate

    Status:
    200 OK

    Duration:
    220 ms

    Request:

    {
      "beneficiaryId": "***"
    }

    Response:

    {
      "status": true
    }

    ----------------------------------------

    API 2

    GET /api/transfer/fees

    Status:
    200 OK

    Duration:
    145 ms

    Response:

    {
      "fee": 1.25,
      "currency": "JOD"
    }

    ----------------------------------------

    NEXT ACTION

    PUSH

    /transfer
        ↓
    /transfer/confirm

    ========================================

    STEP 3

    Screen:
    Transfer Confirmation

    Route:
    /transfer/confirm

    Entered:
    19:20:18

    APIs Triggered: 1

    ----------------------------------------

    FAILED API

    POST /api/transfer/confirm

    Status:
    400 BAD REQUEST

    Duration:
    326 ms

    Request:

    {
      "amount": 100,
      "currency": "JOD",
      "otp": "***"
    }

    Response:

    {
      "status": false,
      "message": "Invalid beneficiary"
    }

    ----------------------------------------

    NEXT ACTION

    None

    User remained on:
    /transfer/confirm

    ========================================

    END OF REPORT

This format should allow the developer to immediately understand:

    User opened Home
        ↓
    APIs loaded successfully
        ↓
    User opened Transfer
        ↓
    Validation APIs succeeded
        ↓
    User opened Confirmation
        ↓
    Confirm API returned 400
        ↓
    No navigation happened
        ↓
    User remained on Confirmation screen

This is the primary goal of the report.

---

## API-to-Screen Association

An API must always remain associated with the screen where the request started.

Example:

    STEP 2
    /transfer

    POST /api/validate
    Request started at 19:20:10

Then navigation happens:

    /transfer
        ↓
    /confirm

The API responds afterward at:

    19:20:11

The API must still appear inside:

    STEP 2
    /transfer

Do not move the API to /confirm based on response time.

The request-start route is authoritative.

---

## Parallel APIs

Multiple APIs may run at the same time.

Example:

    /home

    API 1
    GET /accounts
    Started: 19:20:01.100
    Finished: 19:20:01.500

    API 2
    GET /cards
    Started: 19:20:01.120
    Finished: 19:20:01.300

Display APIs in request-start order.

Do not reorder them based only on response completion time.

This better represents what the application actually triggered.

---

## Request Information

Request details should include when available:

- Query parameters
- Request body
- Relevant sanitized headers

Do not automatically dump every request header into the main report.

Headers may be available inside an optional detailed section.

The main report should remain readable.

---

## Response Information

Response details should include:

- Status code
- Sanitized response body
- Error message
- Truncation indicator when applicable

Example:

    Response:

    {
      "items": [...]
    }

    [Response truncated]

---

## Sensitive Data

All values in the report must already be sanitized.

Example:

    {
      "otp": "***",
      "token": "***",
      "cardNumber": "***"
    }

Never expose original sensitive values in:

- Request
- Response
- Query parameters
- Headers
- Copied text
- Exported image

---

## Visual Hierarchy

The final image should make these elements immediately recognizable:

1. STEP
2. SCREEN
3. API
4. STATUS
5. REQUEST
6. RESPONSE
7. NEXT ACTION

Do not make every line visually equal.

The developer should be able to scan the image quickly.

---

## Compact vs Detailed Data

The report should remain useful without becoming absurdly long.

Recommended behavior:

Successful API:

    Method
    Endpoint
    Status
    Duration
    Request
    Response preview

Failed API:

    Method
    Endpoint
    Status
    Duration
    Full available sanitized request
    Full available sanitized response
    Error information

Payload truncation rules still apply.

---

## Report Goal

The exported report should answer these questions without requiring additional explanation:

1. What did the QA engineer do?
2. Which screen was open?
3. Which API was triggered?
4. What request was sent?
5. What status code returned?
6. What data did the backend return?
7. Did navigation happen afterward?
8. Where did the application end up?
9. Which API is the likely failure point?

If the report answers these questions clearly, the export format is doing its job.