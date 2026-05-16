# GA4 User-Provided Data (Enhanced Conversions)

Complete guide to passing privacy-safe customer data to GA4 for improved conversion measurement and Google Ads matching.

## Overview

Google Analytics 4 allows you to send hashed customer data (email, phone, address) via the `user_data` object. This enables:

- **Enhanced Conversions** — Better attribution in Google Ads
- **Cross-device tracking** — Match users across signed-in and signed-out sessions
- **Conversion modelling** — Fill gaps when cookies are unavailable
- **Audience quality** — Improve remarketing list match rates

## Critical Concept: `user_data` vs `user_id`

These are **entirely different** concepts in Google's ecosystem. Do not confuse them.

| Concept | Purpose | Contains PII? | Key Names |
|---------|---------|---------------|-----------|
| **`user_data`** | Send hashed customer details for ad matching | Yes (must be SHA-256 hashed) | `sha256_email_address`, `sha256_phone_number` |
| **`user_id`** | Internal CRM identifier for cross-device tracking | No (must NOT contain PII) | `user_id` (alphanumeric string) |

### What is `user_data`

- A container object for privacy-safe customer details
- Holds hashed email, phone, name, address
- Used by Google to match conversion actions back to Google accounts
- Enables Enhanced Conversions in Google Ads
- **Must be SHA-256 hashed** before sending (Google prohibits raw PII)

### What is `user_id`

- An internal, non-PII identifier from your backend (e.g., `Shopify_Customer_98723`)
- Used to stitch sessions across devices for the same authenticated user
- Never used for matching ad clicks via personal data
- Must NOT contain email, phone, or any PII

## The `user_data` Object Structure

### Pre-Hashed Mode (Recommended)

You hash the data yourself before sending. Use `sha256_` prefixed keys.

```javascript
gtag('set', 'user_data', {
  "sha256_email_address": "a8af8341993604f29cd4e0e5a5a4b5d48c575436c38b28abbfd7d481f345d5db",
  "sha256_phone_number": "e9d3eef677f9a3b19820f92696be53d646ac4cea500e5f8fd08b00bc6ac773b1",
  "address": {
    "sha256_first_name": "96ae4...",
    "sha256_last_name": "b17c2...",
    "country": "US",
    "region": "CA",
    "city": "San Francisco",
    "postal_code": "94102"
  }
});
```

### Auto-Hash Mode (Let Google Hash)

Pass raw values and let Google's script handle hashing. Use non-prefixed keys.

```javascript
gtag('set', 'user_data', {
  "email": "john.doe@gmail.com",
  "phone_number": "+14155551234",
  "address": {
    "first_name": "John",
    "last_name": "Doe",
    "country": "US",
    "region": "CA",
    "city": "San Francisco",
    "postal_code": "94102"
  }
});
```

**Wapitee recommendation**: Use **pre-hashed mode** for maximum security and to ensure your server-side hashes match exactly.

## Complete Field Reference

### Top-Level Fields

| Field | Pre-Hashed Key | Auto-Hash Key | Required | Description |
|-------|---------------|---------------|----------|-------------|
| Email | `sha256_email_address` | `email` | Yes (at least one) | Customer email address |
| Phone | `sha256_phone_number` | `phone_number` | No | Customer phone number |

### Address Object Fields

| Field | Pre-Hashed Key | Auto-Hash Key | Description |
|-------|---------------|---------------|-------------|
| First Name | `sha256_first_name` | `first_name` | Customer first name |
| Last Name | `sha256_last_name` | `last_name` | Customer last name |
| Street | `sha256_street` | `street` | Street address line |
| City | `city` | `city` | City name (plain text OK) |
| Region | `region` | `region` | State/Province code (plain text OK) |
| Postal Code | `postal_code` | `postal_code` | ZIP/Postal code (plain text OK) |
| Country | `country` | `country` | ISO 3166-1 alpha-2 code (plain text OK) |

## SHA-256 Hashing and Normalization

### Why Normalization Matters

To ensure Google can match your hashed email with their database, you **must normalize** the string before hashing. If normalization doesn't match Google's standard, hash values won't align — resulting in 0% match rate.

### Email Normalization Rules

Apply these transformations **in order** before SHA-256 hashing:

1. **Trim whitespace** — Remove leading and trailing spaces
2. **Lowercase** — Convert entire email to lowercase
3. **Gmail/Googlemail rule** — For `@gmail.com` and `@googlemail.com` addresses, remove all periods (`.`) before the `@` sign

```javascript
function normalizeEmail(email) {
  if (!email) return '';

  // Step 1: Trim whitespace
  let normalized = email.trim();

  // Step 2: Lowercase
  normalized = normalized.toLowerCase();

  // Step 3: Gmail/Googlemail rule — remove dots before @
  const [localPart, domain] = normalized.split('@');
  if (domain === 'gmail.com' || domain === 'googlemail.com') {
    normalized = localPart.replace(/\./g, '') + '@' + domain;
  }

  return normalized;
}

// Examples:
// "  John.Doe@Gmail.com  " → "johndoe@gmail.com"
// "Jane.Smith@googlemail.com" → "janesmith@googlemail.com"
// "user@example.com" → "user@example.com" (unchanged)
```

### Phone Number Normalization Rules

1. **Strip all non-numeric characters** — Remove spaces, dashes, parentheses, `+`
2. **Prepend country code** — Must include country code (e.g., `1` for US)

```javascript
function normalizePhone(phone) {
  if (!phone) return '';

  // Strip all non-numeric characters
  let normalized = phone.replace(/\D/g, '');

  // Ensure country code is present (example: US = 1)
  if (normalized.length === 10) {
    normalized = '1' + normalized; // Prepend US country code
  }

  return normalized;
}

// Examples:
// "+1 (415) 555-1234" → "14155551234"
// "415-555-1234" → "14155551234"
```

### Client-Side SHA-256 Hash Helper

```javascript
async function sha256Hash(input) {
  if (!input) return '';

  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));

  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// Usage:
const normalizedEmail = normalizeEmail(userEmail);
const hashedEmail = await sha256Hash(normalizedEmail);
```

### Complete Hash Pipeline

```javascript
async function hashUserData(email, phone) {
  const userData = {};

  if (email) {
    const normalizedEmail = normalizeEmail(email);
    userData.sha256_email_address = await sha256Hash(normalizedEmail);
  }

  if (phone) {
    const normalizedPhone = normalizePhone(phone);
    userData.sha256_phone_number = await sha256Hash(normalizedPhone);
  }

  return userData;
}
```

## Implementation Examples

### gtag.js Direct

```javascript
// After user logs in or submits a form
async function setUserData(email, phone) {
  const normalizedEmail = normalizeEmail(email);
  const normalizedPhone = normalizePhone(phone);

  gtag('set', 'user_data', {
    sha256_email_address: await sha256Hash(normalizedEmail),
    sha256_phone_number: await sha256Hash(normalizedPhone)
  });
}

// Call on login
setUserData('john.doe@gmail.com', '+1-415-555-1234');
```

### Google Tag Manager (GTM)

**Data Layer Push:**

```javascript
// Push hashed user data to data layer
dataLayer.push({
  'user_data': {
    'sha256_email_address': 'a8af8341993604f29cd4e0e5a5a4b5d48c575436c38b28abbfd7d481f345d5db',
    'sha256_phone_number': 'e9d3eef677f9a3b19820f92696be53d646ac4cea500e5f8fd08b00bc6ac773b1'
  }
});
```

**GTM Configuration:**

1. Create Data Layer Variable: `user_data.sha256_email_address`
2. Create Data Layer Variable: `user_data.sha256_phone_number`
3. In GA4 Configuration tag, expand "Configuration Settings"
4. Add Fields to Set:
   - Field Name: `user_data`
   - Value: `{{DL - User Data}}` (or map individual fields)

### React / Next.js

```tsx
// lib/userData.ts
export function normalizeEmail(email: string): string {
  if (!email) return '';
  let normalized = email.trim().toLowerCase();
  const [localPart, domain] = normalized.split('@');
  if (domain === 'gmail.com' || domain === 'googlemail.com') {
    normalized = localPart.replace(/\./g, '') + '@' + domain;
  }
  return normalized;
}

export function normalizePhone(phone: string): string {
  if (!phone) return '';
  let normalized = phone.replace(/\D/g, '');
  if (normalized.length === 10) normalized = '1' + normalized;
  return normalized;
}

export async function sha256Hash(input: string): Promise<string> {
  if (!input) return '';
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export async function hashUserData(email?: string, phone?: string) {
  const userData: Record<string, string> = {};

  if (email) {
    userData.sha256_email_address = await sha256Hash(normalizeEmail(email));
  }
  if (phone) {
    userData.sha256_phone_number = await sha256Hash(normalizePhone(phone));
  }

  return userData;
}
```

```tsx
// components/Ga4UserData.tsx
'use client';
import { useEffect } from 'react';
import { hashUserData } from '@/lib/userData';

export default function Ga4UserData({ email, phone }: { email?: string; phone?: string }) {
  useEffect(() => {
    if (!email && !phone) return;

    hashUserData(email, phone).then(userData => {
      if (window.gtag) {
        window.gtag('set', 'user_data', userData);
      }
    });
  }, [email, phone]);

  return null;
}
```

### Measurement Protocol (Server-Side)

```python
import hashlib
import requests
import json

def normalize_email(email):
    if not email:
        return ''
    normalized = email.strip().lower()
    local_part, domain = normalized.split('@')
    if domain in ('gmail.com', 'googlemail.com'):
        normalized = local_part.replace('.', '') + '@' + domain
    return normalized

def normalize_phone(phone):
    if not phone:
        return ''
    normalized = ''.join(c for c in phone if c.isdigit())
    if len(normalized) == 10:
        normalized = '1' + normalized
    return normalized

def sha256_hash(input_str):
    if not input_str:
        return ''
    return hashlib.sha256(input_str.encode('utf-8')).hexdigest()

# Build user_data payload
email = "John.Doe@Gmail.com"
phone = "+1 (415) 555-1234"

user_data = {}
if email:
    user_data['sha256_email_address'] = sha256_hash(normalize_email(email))
if phone:
    user_data['sha256_phone_number'] = sha256_hash(normalize_phone(phone))

payload = {
    "client_id": "client_123",
    "user_data": user_data,
    "events": [{
        "name": "purchase",
        "params": {
            "transaction_id": "T_12345",
            "value": 99.99,
            "currency": "USD"
        }
    }]
}

# Send to GA4
endpoint = f"https://www.google-analytics.com/mp/collect?measurement_id=G-XXXXXXXXXX&api_secret=YOUR_SECRET"
response = requests.post(endpoint, json=payload)
```

## Enhanced Conversions for Google Ads

### What is Enhanced Conversions

Enhanced Conversions uses `user_data` to improve the accuracy of conversion measurement in Google Ads. When a user converts on your website, Google matches the hashed data against signed-in Google accounts.

### Setup Requirements

1. **GA4 property linked to Google Ads**
2. **Google Ads Conversion Tracking enabled**
3. **`user_data` configured in GA4**

### Google Ads Configuration

1. Google Ads → Tools → Conversions
2. Select your conversion action
3. Click "Enhanced conversions"
4. Turn ON "Turn on enhanced conversions"
5. Select "Google Analytics"
6. Save

### How It Works

```
User submits email on your site
        ↓
You hash email (SHA-256) and send via user_data
        ↓
Google Ads receives conversion + hashed email
        ↓
Google matches hash against signed-in users
        ↓
Conversion attributed to correct ad click
```

### Verification

Check Enhanced Conversions status in Google Ads:

- Google Ads → Tools → Conversions → [Your Conversion]
- Look for "Enhanced conversions" status
- "Recording" = working correctly
- "Not recording" = check user_data implementation

## Privacy and Compliance

### PII Handling Rules

| Rule | Requirement |
|------|-------------|
| Never send raw PII | Always hash email/phone/name before sending |
| Use SHA-256 only | Google only accepts SHA-256 hashes |
| Normalize before hash | Ensure match rates by following Google's normalization rules |
| Consent required | Obtain user consent before sending user_data in EU/EEA |
| Document usage | Disclose in privacy policy that hashed data is shared with Google |

### GDPR/ePrivacy Compliance

- Obtain explicit user consent before setting `user_data`
- Only send `user_data` when `analytics_storage` and `ad_user_data` are granted
- Clear `user_data` on logout or consent revocation

```javascript
// Only set user_data if consent is granted
if (localStorage.getItem('ga_consent') === 'granted') {
  gtag('set', 'user_data', {
    sha256_email_address: hashedEmail
  });
}

// Clear on consent revocation
function revokeConsent() {
  gtag('set', 'user_data', null);
}
```

### CCPA Compliance

- Honor "Do Not Sell" requests
- Do not send `user_data` for users who have opted out
- Consider using Limited Data Use flags

## Testing and Verification

### DebugView Verification

1. Enable GA Debugger extension
2. Open GA4 Admin → DebugView
3. Trigger an event with `user_data`
4. Check event details:
   - Look for `user_data` parameter
   - Verify hash format (64-character hex string)
   - Confirm no raw PII is visible

### Validation Checklist

- [ ] Email normalized (trimmed, lowercased, Gmail dots removed)
- [ ] Phone normalized (digits only, country code included)
- [ ] SHA-256 hash produces 64-character hex string
- [ ] No raw PII sent in any parameter
- [ ] user_data only sent with consent
- [ ] user_data cleared on logout
- [ ] Google Ads Enhanced Conversions shows "Recording"
- [ ] Match rate improves over time (check Google Ads reports)

## Common Issues

### 0% Match Rate

**Causes:**
- Normalization doesn't match Google's standard
- Wrong hashing algorithm (not SHA-256)
- Raw PII sent instead of hash

**Solutions:**
1. Verify normalization rules (especially Gmail dot removal)
2. Confirm SHA-256 algorithm
3. Check DebugView for raw PII leakage

### Enhanced Conversions Not Recording

**Causes:**
- GA4 not linked to Google Ads
- user_data not set before conversion event
- Wrong field names

**Solutions:**
1. Verify GA4-Google Ads link
2. Set user_data before conversion event fires
3. Use exact field names (`sha256_email_address`)

### user_data Not Appearing in DebugView

**Causes:**
- Set after event fires
- Wrong parameter structure
- Consent blocking

**Solutions:**
1. Set user_data as early as possible (on login)
2. Verify object structure matches Google's spec
3. Check consent state

## Quick Reference

### Set Pre-Hashed user_data

```javascript
gtag('set', 'user_data', {
  sha256_email_address: 'a8af83...',
  sha256_phone_number: 'e9d3ee...'
});
```

### Set Auto-Hash user_data

```javascript
gtag('set', 'user_data', {
  email: 'john.doe@gmail.com',
  phone_number: '+14155551234'
});
```

### Clear user_data

```javascript
gtag('set', 'user_data', null);
```

### Email Normalization

```javascript
email.trim().toLowerCase()
// For Gmail: remove dots before @
```

### Phone Normalization

```javascript
phone.replace(/\D/g, '')
// Ensure country code is present
```

## Comparison: Google vs Meta Hashing

| Aspect | Google (GA4) | Meta (Pixel/CAPI) |
|--------|-------------|-------------------|
| **Object name** | `user_data` | `user_data` (CAPI) / init params (Pixel) |
| **Email key** | `sha256_email_address` | `em` |
| **Phone key** | `sha256_phone_number` | `ph` |
| **Hash algorithm** | SHA-256 | SHA-256 |
| **Email normalization** | Trim, lowercase, **Gmail dots removed** | Trim, lowercase |
| **Phone normalization** | Digits only, country code | Digits only, country code |
| **Auto-hash support** | Yes (pass raw, Google hashes) | Yes (fbevents.js auto-hashes) |
| **Pre-hash recommended** | Yes | Yes |
