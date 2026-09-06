## Sensitive Data Masking

Sensitive information must be masked BEFORE it enters the Event Timeline.

The SDK must provide a default set of sensitive keys and also allow the host application to provide additional sensitive keys.

### Default Sensitive Headers

Default sensitive header names should include:

- authorization
- proxy-authorization
- cookie
- set-cookie
- x-api-key
- api-key

### Default Sensitive Body and Query Keys

Default sensitive body/query field names should include common variations of:

- password
- passcode
- pin
- otp
- token
- accessToken
- access_token
- refreshToken
- refresh_token
- idToken
- id_token
- secret
- clientSecret
- client_secret
- sessionId
- session_id

Matching should be case-insensitive where appropriate.

---

## Custom Sensitive Keys

The host application must be able to provide additional sensitive keys.

Example:

    QaNetworkConfig(
      sensitiveKeys: {
        'nationalId',
        'accountNumber',
        'cardNumber',
        'cif',
        'mobileNumber',
      },
    )

These custom keys must be applied to:

- Request bodies
- Response bodies
- Query parameters
- Nested Maps
- Lists containing Maps

Custom sensitive keys must be merged with the SDK default sensitive keys.

Conceptually:

    effectiveSensitiveKeys =
        defaultSensitiveKeys + customSensitiveKeys;

Providing custom sensitive keys must NOT disable the default protection.

Example:

SDK defaults:

    password
    otp
    token

Host configuration:

    nationalId
    cardNumber

Effective sensitive keys:

    password
    otp
    token
    nationalId
    cardNumber

---

## Sensitive Header Configuration

The host application should also be able to provide additional sensitive header names.

Example:

    QaNetworkConfig(
      sensitiveKeys: {
        'nationalId',
        'cardNumber',
      },
      sensitiveHeaders: {
        'x-customer-token',
        'x-device-token',
      },
    )

Custom sensitive headers must be merged with the SDK default sensitive headers.

---

## Optional Default Replacement

The configuration may support an explicit option for advanced consumers to replace the default sensitive keys.

This must NOT be the default behavior.

Conceptually:

    QaNetworkConfig(
      sensitiveKeys: {
        'customSecret',
      },
      includeDefaultSensitiveKeys: false,
    )

Default:

    includeDefaultSensitiveKeys = true

When true:

    effectiveKeys =
        defaultSensitiveKeys + customSensitiveKeys;

When false:

    effectiveKeys =
        customSensitiveKeys;

The same pattern may be supported for sensitive headers if needed.

---

## Matching Rules

Sensitive-key matching should be case-insensitive.

For example, all of the following should match the configured key "accessToken":

    accessToken
    AccessToken
    ACCESSTOKEN
    accesstoken

Do not require consumers to configure every capitalization variation.

Exact normalized key matching should be preferred by default.

Do not automatically use broad substring matching unless explicitly configured.

For example, configuring:

    pin

must not accidentally mask unrelated keys such as:

    shippingAddress

because the string contains similar characters.

---

## Recursive Masking

Sensitive keys may exist at any depth.

Example:

    {
      "customer": {
        "authentication": {
          "otp": "123456"
        },
        "cards": [
          {
            "cardNumber": "1234567890123456"
          }
        ]
      }
    }

After sanitization:

    {
      "customer": {
        "authentication": {
          "otp": "***"
        },
        "cards": [
          {
            "cardNumber": "***"
          }
        ]
      }
    }

The sanitizer must recursively support:

- Map
- List
- Map inside List
- List inside Map
- Arbitrarily nested combinations within reasonable runtime limits

Never mutate the host application's original object while sanitizing.

---

## Response Masking

Sensitive-key masking must apply to BOTH request and response data.

This is important because backend responses may also contain sensitive information.

Example:

    {
      "accessToken": "...",
      "refreshToken": "...",
      "customer": {
        "nationalId": "..."
      }
    }

must be sanitized before being stored in the timeline.

---

## Configuration Ownership

Sensitive-data configuration belongs to the Network Inspector configuration layer.

Do not hardcode project-specific sensitive keys into the SDK.

The SDK provides safe generic defaults.

The host application provides business-specific sensitive keys.

---

## Testing Requirements for Custom Sensitive Keys

Add tests verifying:

1. Default sensitive keys are masked.
2. Custom sensitive keys are masked.
3. Defaults remain active when custom keys are provided.
4. Custom keys work in request bodies.
5. Custom keys work in response bodies.
6. Custom keys work in query parameters.
7. Custom keys work in nested Maps.
8. Custom keys work inside Lists.
9. Matching is case-insensitive.
10. Original request/response objects are not mutated.
11. includeDefaultSensitiveKeys=false uses only custom keys.