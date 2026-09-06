# Sensitive Data Masking Skill

## Purpose

The Sensitive Data Masking module protects sensitive information before network data is stored, displayed, copied, or exported by the QA SDK.

Sensitive data must be sanitized as early as possible.

The central rule is:

    Raw Network Data
          ↓
    Sensitive Data Masking
          ↓
    Sanitized Data
          ↓
    Event Timeline
          ↓
    QA Overlay
          ↓
    Copy / Export

Raw sensitive values must never be stored inside the Event Timeline.

The masking system must support both:

- Built-in default sensitive keys
- Developer-provided custom sensitive keys

The system must work recursively with nested request and response structures.

---

## Core Principles

When implementing or modifying sensitive-data masking:

1. Mask sensitive data before timeline storage.
2. Never mutate original host application data.
3. Support request bodies.
4. Support response bodies.
5. Support query parameters.
6. Support headers.
7. Support nested Maps.
8. Support nested Lists.
9. Match sensitive keys case-insensitively.
10. Allow developers to add custom sensitive keys.
11. Merge custom keys with SDK defaults by default.
12. Avoid broad substring matching.
13. Fail safely for unsupported values.
14. Keep masking independent from UI and export.
15. Do not store raw values for later masking.

---

## Security Boundary

The Event Timeline is considered sanitized storage.

Therefore:

    Dio Request
        ↓
    Mask
        ↓
    QaNetworkEvent
        ↓
    Event Timeline

NOT:

    Dio Request
        ↓
    QaNetworkEvent with raw data
        ↓
    Event Timeline
        ↓
    Mask when UI opens

Masking after timeline storage is too late.

---

## Default Sensitive Keys

The SDK should provide a default set of commonly sensitive field names.

Recommended defaults include common variations of:

    password
    passcode
    pin
    otp

    token
    accessToken
    access_token

    refreshToken
    refresh_token

    idToken
    id_token

    secret

    clientSecret
    client_secret

    sessionId
    session_id

The exact internal set may evolve.

Do not require developers to configure these basic fields manually.

---

## Default Sensitive Headers

Recommended sensitive headers include:

    authorization
    proxy-authorization

    cookie
    set-cookie

    x-api-key
    api-key

Sensitive header matching must be case-insensitive.

For example, all of these must match:

    Authorization
    authorization
    AUTHORIZATION

---

## Custom Sensitive Keys

The developer must be able to provide application-specific sensitive keys.

Conceptually:

    QaNetworkConfig(
      sensitiveKeys: {
        'nationalId',
        'accountNumber',
        'cardNumber',
        'cif',
        'mobileNumber',
      },
    )

These keys should apply to:

- Request body
- Response body
- Query parameters
- Nested Maps
- Maps inside Lists

Example:

    {
      "name": "User",
      "nationalId": "1234567890",
      "accountNumber": "00123456789"
    }

After sanitization:

    {
      "name": "User",
      "nationalId": "***",
      "accountNumber": "***"
    }

---

## Default + Custom Behavior

Custom sensitive keys must be merged with SDK defaults by default.

Conceptually:

    effectiveSensitiveKeys =
        defaultSensitiveKeys +
        customSensitiveKeys

Example configuration:

    sensitiveKeys: {
      'nationalId',
      'accountNumber',
    }

must still mask:

    password
    otp
    token
    accessToken

as well as:

    nationalId
    accountNumber

Custom configuration must NOT accidentally disable SDK security defaults.

---

## Optional Default-Key Override

For advanced use cases, allow developers to explicitly disable default sensitive keys.

Conceptually:

    QaNetworkConfig(
      includeDefaultSensitiveKeys: false,
      sensitiveKeys: {
        'customSecret',
      },
    )

Default:

    includeDefaultSensitiveKeys = true

When false:

    effectiveSensitiveKeys =
        customSensitiveKeys

This should be an explicit developer decision.

Never disable defaults automatically.

---

## Custom Sensitive Headers

Applications may use custom authentication or security headers.

Allow configuration such as:

    QaNetworkConfig(
      sensitiveHeaders: {
        'x-customer-token',
        'x-device-token',
        'x-session-key',
      },
    )

By default:

    effectiveSensitiveHeaders =
        defaultSensitiveHeaders +
        customSensitiveHeaders

Custom headers must not disable default sensitive headers.

---

## Optional Default Header Override

The architecture may support:

    includeDefaultSensitiveHeaders: false

Default:

    true

This should follow the same behavior as sensitive body keys.

---

## Key Matching

Sensitive-key matching must be case-insensitive.

Example configured key:

    accountNumber

must match:

    accountNumber
    AccountNumber
    ACCOUNTNUMBER
    accountnumber

Normalize keys before comparison.

Conceptually:

    normalizedKey = key.toLowerCase()

---

## Exact Matching

Use normalized exact key matching by default.

Example sensitive key:

    pin

should match:

    pin
    PIN
    Pin

but should NOT automatically match:

    shippingAddress
    spinnerValue
    pinCodeEnabled

Broad substring matching can hide unrelated data and make reports useless.

Do not use:

    key.contains('pin')

as the default masking strategy.

---

## Key Normalization

The implementation may normalize common formatting differences if intentionally designed.

For example:

    accessToken
    access_token

should normally both exist in the default sensitive-key set.

Do not introduce aggressive normalization that creates unpredictable matches.

Prefer explicit variants over clever matching.

Predictability is more important than magical behavior.

---

## Mask Value

The default replacement should be simple and obvious.

Recommended:

    ***

Example:

    "otp": "***"

The mask value may become configurable later.

Do not preserve partial sensitive values by default.

---

## Recursive Map Masking

Nested structures must be sanitized recursively.

Input:

    {
      "customer": {
        "name": "User",
        "nationalId": "1234567890"
      }
    }

Output:

    {
      "customer": {
        "name": "User",
        "nationalId": "***"
      }
    }

---

## Recursive List Masking

Lists must also be traversed.

Input:

    {
      "accounts": [
        {
          "accountNumber": "001"
        },
        {
          "accountNumber": "002"
        }
      ]
    }

Output:

    {
      "accounts": [
        {
          "accountNumber": "***"
        },
        {
          "accountNumber": "***"
        }
      ]
    }

---

## Deep Structures

The masking algorithm should support combinations such as:

    Map
      ↓
    List
      ↓
    Map
      ↓
    List
      ↓
    Map

Example:

    {
      "customers": [
        {
          "cards": [
            {
              "cardNumber": "1234567890123456"
            }
          ]
        }
      ]
    }

must become:

    {
      "customers": [
        {
          "cards": [
            {
              "cardNumber": "***"
            }
          ]
        }
      ]
    }

---

## Request Body Masking

Request bodies must be sanitized before creating QaNetworkEvent.

Example:

    POST /login

Raw request:

    {
      "username": "naser",
      "password": "secret",
      "otp": "123456"
    }

Stored event:

    {
      "username": "naser",
      "password": "***",
      "otp": "***"
    }

The raw password and OTP must never exist inside the Event Timeline.

---

## Response Body Masking

Response bodies must also be sanitized.

This is mandatory.

Sensitive information may be returned by backend APIs.

Example:

    {
      "accessToken": "abc",
      "refreshToken": "xyz",
      "user": {
        "name": "User"
      }
    }

Stored response:

    {
      "accessToken": "***",
      "refreshToken": "***",
      "user": {
        "name": "User"
      }
    }

Do not only sanitize requests.

---

## Query Parameter Masking

Query parameters must be sanitized.

Example:

    GET /verify?otp=123456&language=en

Stored representation:

    GET /verify?otp=***&language=en

The URL displayed or exported must not accidentally contain the original sensitive query value.

---

## URL Safety

Be careful when storing full URLs.

If sensitive values exist in query parameters, storing the original full URL would bypass masking.

Do not store:

    https://api.example.com/verify?otp=123456

while separately storing:

    queryParameters = {
      "otp": "***"
    }

because the secret still exists in the URL.

The sanitized URL must also contain the masked query value.

---

## Header Masking

Input:

    Authorization: Bearer abc123
    Content-Type: application/json
    X-Device-Token: xyz123

Output:

    Authorization: ***
    Content-Type: application/json
    X-Device-Token: ***

Header names should remain visible.

Only sensitive values should be replaced.

This allows developers to know that the header existed without exposing its content.

---

## Original Data Must Not Be Mutated

This requirement is critical.

The masking process must create sanitized copies.

It must never modify the original:

- Dio request body
- Dio response body
- Query parameters
- Headers
- Nested application objects

Example:

    final original = {
      'otp': '123456',
    };

    final sanitized = sanitizer.sanitize(original);

After sanitization:

    original['otp']

must still be:

    123456

while:

    sanitized['otp']

must be:

    ***

The QA SDK must never change application behavior.

---

## Maps

Support common Map structures safely.

Do not assume every map is exactly:

    Map<String, dynamic>

Keys may have other runtime types.

Only string keys should participate in sensitive-key matching.

Unsupported map structures must not crash sanitization.

---

## Lists

Create sanitized list copies.

Do not modify the original List.

Every element should be recursively sanitized when safe.

---

## Primitive Values

Primitive values should normally pass through unchanged.

Examples:

    String
    int
    double
    bool
    null

unless they are the value of a sensitive key.

Example:

    {
      "pin": 1234
    }

must become:

    {
      "pin": "***"
    }

regardless of the original value type.

---

## FormData

Dio FormData requires special handling.

Do not consume files or streams.

Text fields may be sanitized based on field names.

Example:

    FormData

    username = naser
    nationalId = 1234567890

should be represented as:

    username = naser
    nationalId = ***

File fields should use metadata only.

Example:

    file:
      filename: document.pdf
      content: [omitted]

Do not read file bytes for masking.

---

## MultipartFile

Do not attempt to inspect MultipartFile contents.

Store only safe metadata where available.

Example:

    {
      "filename": "document.pdf",
      "content": "[binary omitted]"
    }

If the filename itself is considered sensitive in the future, that should be separately configurable.

---

## Binary Data

Do not inspect arbitrary binary data for sensitive keys.

Examples:

    Uint8List
    ByteData
    Streams

Represent them safely.

Example:

    [binary content omitted]

Do not convert large binary content into Strings just to inspect it.

---

## String JSON

Some applications send JSON as a String.

Example:

    '{"username":"naser","password":"secret"}'

The sanitizer may attempt JSON decoding when:

- The value appears to contain JSON.
- Decoding is safe.
- The operation remains reasonably lightweight.

If decoding succeeds:

    {
      "username": "naser",
      "password": "***"
    }

If decoding fails, preserve the safe representation.

Do not allow parsing failures to affect networking.

---

## Plain Strings

The SDK cannot reliably know whether arbitrary plain text contains sensitive data.

Do not aggressively modify arbitrary strings based on substring searches.

Example:

    "shipping completed"

must not be altered because a configured key happens to be:

    pin

Key-based structured masking is the default strategy.

---

## Maximum Recursion Safety

Malformed or unusually deep data structures should not cause stack or performance problems.

Consider a reasonable recursion-depth safeguard.

If the maximum safe depth is exceeded, use a safe representation such as:

    [content omitted: maximum depth reached]

Do not allow hostile or malformed payloads to crash the QA SDK.

---

## Circular References

Custom Dart objects or collections may theoretically contain circular references.

The sanitizer must fail safely.

Do not enter infinite recursion.

Where practical, detect already-visited objects during recursive sanitization.

If a circular structure is detected:

    [circular reference omitted]

is acceptable.

---

## Unsupported Objects

Custom Dart objects should not be deeply reflected or inspected automatically.

Avoid dart:mirrors or reflection-like complexity.

Use a safe representation.

The Network Inspector may decide how unsupported objects are represented before storage.

Never allow:

    object.toString()

failure to break networking.

---

## Configuration Ownership

Sensitive data configuration belongs to the QA SDK/network inspection configuration.

Conceptually:

    QaInspectorConfig(
      network: QaNetworkConfig(
        sensitiveKeys: {
          'nationalId',
          'accountNumber',
          'cardNumber',
        },
        sensitiveHeaders: {
          'x-device-token',
        },
      ),
    )

Avoid project-specific hardcoded fields inside the core SDK.

---

## Configuration Immutability

Prefer immutable configuration.

Once the inspector is initialized, sanitization rules should remain predictable.

If runtime configuration changes are supported later, they must be handled intentionally.

They are not required for the MVP.

---

## Central Sanitizer

Prefer one reusable sanitizer service.

Conceptually:

    QaDataSanitizer

Responsibilities:

    sanitizeBody(...)
    sanitizeQueryParameters(...)
    sanitizeHeaders(...)
    sanitizeUrl(...)

Do not implement different masking algorithms independently in:

- Network Inspector
- Overlay UI
- Report Export
- Clipboard logic

There should be one security implementation.

---

## UI Behavior

The QA Overlay receives already-sanitized values.

The UI must never request raw values.

Example:

    Request:

    {
      "otp": "***"
    }

There should be no:

    Show original value

button.

Masked data stays masked.

---

## Export Behavior

The Report Export module must use the same sanitized events.

Export should not require another sanitization pass as its primary protection.

Defense-in-depth sanitization may be added later if necessary, but the timeline must already be safe.

---

## Copy Behavior

Clipboard actions