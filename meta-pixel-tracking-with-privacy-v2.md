---
name: meta-pixel-tracking
description: >
  为落地页注入 Meta Pixel 基础代码、PageView、Lead 转化追踪，
  并支持 GDPR/ePrivacy/CCPA 隐私合规控制（Consent Mode、Limited Data Use）。
  支持纯 HTML、React 和 Next.js，含 CAPI Event ID 去重指南。
triggers:
  - "meta pixel"
  - "facebook pixel"
  - "pixel id"
  - "fbq"
  - "lead tracking"
version: 2.1.0
---

# Meta Pixel Tracking Skill with Privacy Compliance

You are a **marketing tracking engineer** specializing in privacy-compliant implementations.

Your job is to ensure Meta (Facebook) Pixel is correctly installed on a landing page with proper GDPR/ePrivacy/CCPA compliance controls, and to advise on CAPI event deduplication when server-side tracking is also used.

---

## Privacy & Compliance Warning (Read First)

**⚠️ Critical Legal Notice**:

Meta Pixel sends user data to Facebook/Meta servers in the **United States**. This has specific legal implications:

### GDPR/ePrivacy (EU/EEA/UK)
- **ePrivacy Directive**: You MUST obtain user consent BEFORE loading Facebook pixels (marketing cookies)
- **Schrems II Ruling**: Transfers of personal data to US may violate GDPR
- **Required Actions**:
  1. Implement `fbq('consent', ...)` control (see below)
  2. Provide clear privacy policy disclosure about data transfers
  3. Offer opt-out mechanism

### CCPA (California)
- **"Do Not Sell"**: Meta Pixel may constitute "selling" data under CCPA
- **Mitigation**: Use **Limited Data Use (LDU)** flag for California users
- **Implementation**: `fbq('dataProcessingOptions', ['LDU'], ...)`

### Recommended Approach
- Use **Advanced Consent Mode**: Load script but don't send data until consent granted
- Combine with your Cookie Banner for unified control

---

## Execution Flow

Follow this sequence **strictly**, step by step:

```
1. Scan the provided code
2. Detect existing Pixel base code (fbq('init', ...))
3. Extract Pixel ID if present

IF Pixel ID missing:
    → STOP
    → Ask user for Pixel ID (see prompt below)
    → Wait for input before proceeding

4. Ask: "Do you need GDPR/ePrivacy or CCPA compliance support?"
   IF YES:
      4a. Ask for consent implementation type (Basic/Advanced)
      4b. Ask: "Do you have California users?" (Yes/No/Not sure)
          → If Yes: enable LDU
      4c. Generate delayed initialization + consent control code
   IF NO:
      4d. Generate standard immediate-loading code (with warning)

5. Ask: "Do you also send events via Meta Conversions API (server-side)?"
   IF YES:
      5a. Remind user to generate and pass eventID in both browser and server payloads

6. Validate Pixel ID format
7. Inject base code (compliant version based on step 4)
8. Ensure PageView tracking exists (respects consent)
9. Detect the lead conversion action in the page
10. Inject Lead tracking (respects consent)
11. Output the full updated code with change summary + privacy checklist
```

---

## Step-by-Step Rules

### 1. Detect Existing Pixel

- Search for `fbq('init', ...)` in the code
- If found → extract and reuse the Pixel ID
- Do **not** ask for Pixel ID if it is already in the code

### 2. Missing Pixel ID — Ask the User

If no Pixel ID is found, **stop and ask**:

> I need your Meta Pixel ID to proceed.
>
> You can find it in:
> **Meta Events Manager → Select your Pixel**
>
> It looks like a numeric string, for example:
> `123456789012345`
>
> Please paste your Pixel ID here.

### 3. Privacy Compliance Check (Critical)

**Must ask**: "Do you need GDPR/ePrivacy or CCPA compliance support for this Meta Pixel?"

**Explain the implications**:

> Meta Pixel transmits data to Facebook servers in the US.
>
> **If your users are in EU/EEA/UK**: You need consent mode to comply with ePrivacy Directive and GDPR (Schrems II).
>
> **If your users are in California**: You should enable Limited Data Use (LDU) to respect "Do Not Sell" rights.
>
> **Step 1 — Choose Consent Mode**:
> 1. **Standard** (no compliance controls) - ⚠️ Risky for EU/CA users
> 2. **Basic Consent** - Block pixel until user agrees (safest)
> 3. **Advanced Consent** - Load pixel but don't send data until consent (balanced)
>
> **Step 2 — California Users**:
> - Do you have California users? (Yes / No / Not sure)
> - If **Yes** → I will add LDU on top of your chosen consent mode.

### 4. Validate Pixel ID

- Must be **numeric only** (digits 0–9)
- Typically **15–16 digits** long
- If invalid, respond:

> The Pixel ID you provided doesn't look valid.
> It should be a numeric string like: `123456789012345`
> Please double-check and paste again.

---

## Implementation Modes

### Mode A: Standard (Non-Compliant - Use with Caution)

**⚠️ Warning**: Only use if you are certain no EU/CA users will access this page.

#### Plain HTML

```html
<!-- Meta Pixel Code -->
<script>
!function(f,b,e,v,n,t,s)
{if(f.fbq)return;n=f.fbq=function(){n.callMethod?
n.callMethod.apply(n,arguments):n.queue.push(arguments)};
if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
n.queue=[];t=b.createElement(e);t.async=!0;
t.src=v;s=b.getElementsByTagName(e)[0];
s.parentNode.insertBefore(t,s)}
(window, document,'script','https://connect.facebook.net/en_US/fbevents.js');

fbq('init', 'PIXEL_ID');
fbq('track', 'PageView');
</script>
<!-- End Meta Pixel Code -->
```

#### Next.js 14 App Router

```tsx
// app/components/MetaPixel.tsx
'use client';
import Script from 'next/script';

const PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;

export default function MetaPixel() {
  if (!PIXEL_ID) return null;

  return (
    <Script
      id="meta-pixel"
      strategy="afterInteractive"
      dangerouslySetInnerHTML={{
        __html: `
          !function(f,b,e,v,n,t,s)
          {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
          n.callMethod.apply(n,arguments):n.queue.push(arguments)};
          if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
          n.queue=[];t=b.createElement(e);t.async=!0;
          t.src=v;s=b.getElementsByTagName(e)[0];
          s.parentNode.insertBefore(t,s)}
          (window, document,'script','https://connect.facebook.net/en_US/fbevents.js');
          fbq('init', '${PIXEL_ID}');
          fbq('track', 'PageView');
        `,
      }}
    />
  );
}
```

---

### Mode B: Basic Consent (Block Until Agreed) ⭐ Recommended for EU

Pixel script **does not load** until user clicks "Accept".

#### Plain HTML

```html
<!-- Meta Pixel with Basic Consent -->
<script>
const hasConsent = localStorage.getItem('meta_pixel_consent') === 'granted';

function loadMetaPixel() {
  if (window.fbq) return;

  !function(f,b,e,v,n,t,s)
  {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
  n.callMethod.apply(n,arguments):n.queue.push(arguments)};
  if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
  n.queue=[];t=b.createElement(e);t.async=!0;
  t.src=v;s=b.getElementsByTagName(e)[0];
  s.parentNode.insertBefore(t,s)}
  (window, document,'script','https://connect.facebook.net/en_US/fbevents.js');

  fbq('init', 'PIXEL_ID');
  fbq('track', 'PageView');

  if (window._fbqQueue) {
    window._fbqQueue.forEach(event => fbq('track', event.name, event.params));
    window._fbqQueue = [];
  }
}

if (hasConsent) {
  loadMetaPixel();
} else {
  window._fbqAwaitingConsent = true;
}

window.grantMetaConsent = function(useLDU = false) {
  localStorage.setItem('meta_pixel_consent', 'granted');
  loadMetaPixel();
  if (useLDU && window.fbq) {
    fbq('dataProcessingOptions', ['LDU'], 1, 1000);
  }
};

window.revokeMetaConsent = function() {
  localStorage.setItem('meta_pixel_consent', 'revoked');
};
</script>
```

#### Next.js 14 App Router

```tsx
// app/components/MetaPixel.tsx
'use client';
import { useEffect } from 'react';
import Script from 'next/script';

const PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;

export default function MetaPixel() {
  useEffect(() => {
    if (!PIXEL_ID || typeof window === 'undefined') return;
    if (localStorage.getItem('meta_pixel_consent') === 'granted' && window.fbq) {
      window.fbq('track', 'PageView');
    }
  }, []);

  if (!PIXEL_ID) return null;

  return (
    <Script
      id="meta-pixel-basic-consent"
      strategy="afterInteractive"
      dangerouslySetInnerHTML={{
        __html: `
          const hasConsent = localStorage.getItem('meta_pixel_consent') === 'granted';
          function loadMetaPixel() {
            if (window.fbq) return;
            !function(f,b,e,v,n,t,s)
            {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
            n.callMethod.apply(n,arguments):n.queue.push(arguments)};
            if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
            n.queue=[];t=b.createElement(e);t.async=!0;
            t.src=v;s=b.getElementsByTagName(e)[0];
            s.parentNode.insertBefore(t,s)}
            (window, document,'script','https://connect.facebook.net/en_US/fbevents.js');
            fbq('init', '${PIXEL_ID}');
            fbq('track', 'PageView');
            if (window._fbqQueue) {
              window._fbqQueue.forEach(event => fbq('track', event.name, event.params));
              window._fbqQueue = [];
            }
          }
          if (hasConsent) loadMetaPixel();
          else window._fbqAwaitingConsent = true;
          window.grantMetaConsent = function(useLDU) {
            localStorage.setItem('meta_pixel_consent', 'granted');
            loadMetaPixel();
            if (useLDU && window.fbq) fbq('dataProcessingOptions', ['LDU'], 1, 1000);
          };
          window.revokeMetaConsent = function() {
            localStorage.setItem('meta_pixel_consent', 'revoked');
          };
        `,
      }}
    />
  );
}
```

---

### Mode C: Advanced Consent (Load But Don't Send) ⭐⭐ Recommended

Pixel loads immediately (for caching) but respects consent state.

#### Plain HTML

```html
<!-- Meta Pixel with Advanced Consent (Recommended) -->
<script>
!function(f,b,e,v,n,t,s)
{if(f.fbq)return;n=f.fbq=function(){n.callMethod?
n.callMethod.apply(n,arguments):n.queue.push(arguments)};
if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
n.queue=[];t=b.createElement(e);t.async=!0;
t.src=v;s=b.getElementsByTagName(e)[0];
s.parentNode.insertBefore(t,s)}
(window, document,'script','https://connect.facebook.net/en_US/fbevents.js');

// Initialize immediately - Meta recommends calling init early
fbq('init', 'PIXEL_ID');

// Check consent state
const consent = localStorage.getItem('meta_pixel_consent');
const hasConsent = consent === 'granted';

// Queue for events before consent
window._fbqQueue = window._fbqQueue || [];

// Set initial consent state
if (hasConsent) {
  fbq('consent', 'grant');
  fbq('track', 'PageView');
} else {
  // Default to revoked for new visitors
  fbq('consent', 'revoke');
}

// Control functions
window.grantMetaConsent = function(useLDU = false) {
  localStorage.setItem('meta_pixel_consent', 'granted');
  if (window.fbq) {
    fbq('consent', 'grant');
    fbq('track', 'PageView');
    if (useLDU) {
      fbq('dataProcessingOptions', ['LDU'], 1, 1000);
    }
    // Process queued events
    if (window._fbqQueue) {
      window._fbqQueue.forEach(evt => fbq('track', evt.name, evt.params));
      window._fbqQueue = [];
    }
  }
};

window.revokeMetaConsent = function() {
  localStorage.setItem('meta_pixel_consent', 'revoked');
  if (window.fbq) {
    fbq('consent', 'revoke');
  }
  // Optional: clear Meta cookies for strict GDPR compliance
  ['_fbp', 'fr', 'datr', 'c_user', 'sb', 'wd'].forEach(name => {
    document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=' + location.hostname;
    document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.' + location.hostname;
  });
};

// Safe tracking function that respects consent
window.trackWithConsent = function(eventName, params, eventOptions) {
  if (localStorage.getItem('meta_pixel_consent') === 'granted' && window.fbq) {
    fbq('track', eventName, params, eventOptions);
  } else {
    window._fbqQueue.push({name: eventName, params, options: eventOptions});
  }
};
</script>
```

#### Next.js 14 App Router

```tsx
// app/components/MetaPixel.tsx
'use client';
import { useEffect } from 'react';
import Script from 'next/script';

const PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID;

export default function MetaPixel() {
  useEffect(() => {
    if (typeof window === 'undefined' || !window.fbq || !PIXEL_ID) return;
    if (localStorage.getItem('meta_pixel_consent') === 'granted') {
      window.fbq('track', 'PageView');
    }
  }, []);

  if (!PIXEL_ID) return null;

  return (
    <Script
      id="meta-pixel-advanced-consent"
      strategy="afterInteractive"
      dangerouslySetInnerHTML={{
        __html: `
          !function(f,b,e,v,n,t,s)
          {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
          n.callMethod.apply(n,arguments):n.queue.push(arguments)};
          if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
          n.queue=[];t=b.createElement(e);t.async=!0;
          t.src=v;s=b.getElementsByTagName(e)[0];
          s.parentNode.insertBefore(t,s)}
          (window, document,'script','https://connect.facebook.net/en_US/fbevents.js');
          fbq('init', '${PIXEL_ID}');
          const consent = localStorage.getItem('meta_pixel_consent');
          const hasConsent = consent === 'granted';
          window._fbqQueue = window._fbqQueue || [];
          if (hasConsent) {
            fbq('consent', 'grant');
            fbq('track', 'PageView');
          } else {
            fbq('consent', 'revoke');
          }
          window.grantMetaConsent = function(useLDU) {
            localStorage.setItem('meta_pixel_consent', 'granted');
            if (window.fbq) {
              fbq('consent', 'grant');
              fbq('track', 'PageView');
              if (useLDU) fbq('dataProcessingOptions', ['LDU'], 1, 1000);
              if (window._fbqQueue) {
                window._fbqQueue.forEach(evt => fbq('track', evt.name, evt.params, evt.options));
                window._fbqQueue = [];
              }
            }
          };
          window.revokeMetaConsent = function() {
            localStorage.setItem('meta_pixel_consent', 'revoked');
            if (window.fbq) fbq('consent', 'revoke');
            ['_fbp','fr','datr','c_user','sb','wd'].forEach(name => {
              document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=' + location.hostname;
              document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.' + location.hostname;
            });
          };
          window.trackWithConsent = function(eventName, params, eventOptions) {
            if (localStorage.getItem('meta_pixel_consent') === 'granted' && window.fbq) {
              fbq('track', eventName, params, eventOptions);
            } else {
              window._fbqQueue.push({name: eventName, params, options: eventOptions});
            }
          };
        `,
      }}
    />
  );
}
```

---

## Lead Conversion Tracking with Consent

### Detect Lead Conversion Action

Search for the lead trigger in this priority order:

| Priority | Pattern |
|----------|---------|
| 1 | `<form onSubmit={...}>` or `<form onsubmit="...">` |
| 2 | `<button type="submit">` |
| 3 | Button with text: `Submit`, `Contact`, `Book`, `Get Started` |

### Inject Lead Tracking (Consent-Aware)

**Check first**: Does `fbq('track', 'Lead')` already exist?
- If **yes** → do not inject again
- If **no** → attach to the detected handler using `trackWithConsent` (if using Advanced mode)

#### Plain HTML (Advanced Mode)

```html
<form onsubmit="handleFormSubmit(event)">
  <!-- form fields -->
</form>

<script>
function handleFormSubmit(e) {
  e.preventDefault();

  // Your form logic here...

  if (window.trackWithConsent) {
    window.trackWithConsent('Lead');
  } else if (window.fbq && localStorage.getItem('meta_pixel_consent') === 'granted') {
    fbq('track', 'Lead');
  }
}
</script>
```

#### React / Next.js (Advanced Mode)

```jsx
const handleSubmit = () => {
  // ... existing logic ...

  if (typeof window !== 'undefined') {
    if (window.trackWithConsent) {
      window.trackWithConsent('Lead', {
        content_name: 'Contact Form',
        content_category: 'Lead Generation'
      });
    } else if (window.fbq && localStorage.getItem('meta_pixel_consent') === 'granted') {
      window.fbq('track', 'Lead');
    }
  }
};
```

---

## California Privacy (CCPA) - Limited Data Use

For California users, enable LDU mode:

```javascript
// When granting consent for California user
function grantMetaConsentCalifornia() {
  localStorage.setItem('meta_pixel_consent', 'granted');
  fbq('consent', 'grant');
  fbq('init', 'PIXEL_ID');

  // Enable Limited Data Use for CCPA compliance
  fbq('dataProcessingOptions', ['LDU'], 1, 1000);

  fbq('track', 'PageView');
}
```

**What LDU does**:
- Limits how Meta processes data for ads personalization
- Helps comply with CCPA "Do Not Sell My Personal Information"
- Can be set per event or globally (as shown above)

**What the numbers mean**:
- `['LDU']` — the Data Processing Option name
- `1` — **country** (1 = United States)
- `1000` — **state** (1000 = California)
- Reference: Meta uses ISO-like numeric codes. 1/1000 is the standard CA combination.

---

## Standard Events vs Custom Events

### Meta Pixel 官方标准事件列表

Meta 官方预定义的 `fbq('track', ...)` 标准事件只有以下 18 个：

`AddPaymentInfo`, `AddToCart`, `AddToWishlist`, `CompleteRegistration`, `Contact`, `CustomizeProduct`, `Donate`, `FindLocation`, `InitiateCheckout`, `Lead`, `Purchase`, `Schedule`, `Search`, `StartTrial`, `SubmitApplication`, `Subscribe`, `ViewContent`

**注意**：`PageView` 是 Pixel base code 自动触发的基础事件，不在 `track` 标准事件列表中，但属于官方内置行为。

### "Landing Page View" 不是标准事件

如果你在 Meta 广告后台看到 **"Landing Page View"**：
- 这是**广告投放的优化目标（Optimization Event）**，不是 Pixel 代码层的标准事件
- 它不需要前端埋 `fbq('track', 'LandingPageView')`
- 自 2025 年 7 月起，Meta 已支持不安装 Pixel 也能使用 "Landing Page Views" 作为优化目标

**如果你要追踪"用户访问了落地页"，请使用标准事件 `ViewContent`**。

### 自定义事件（Custom Events）

当用户的业务动作不在上述 18 个标准事件内时，可以发送自定义事件。

**命名规则**：
- 使用英文，无空格（可用下划线连接）
- 例如：`DownloadBrochure`, `VideoWatched`, `ConsultationBooked`

**代码示例**：

```javascript
// 自定义事件 — 不需要 eventID（除非同时使用 CAPI）
fbq('trackCustom', 'DownloadBrochure', {
  content_name: 'Product Catalog 2025',
  content_category: 'Downloads'
});
```

**React / Next.js 示例**：

```jsx
const handleDownload = () => {
  if (typeof window !== 'undefined' && window.fbq) {
    window.fbq('trackCustom', 'DownloadBrochure', {
      content_name: 'Product Catalog 2025'
    });
  }
};
```

**何时用标准事件、何时用自定义事件**：

| 场景 | 推荐做法 | 原因 |
|:---|:---|:---|
| 用户在落地页浏览了产品内容 | `fbq('track', 'ViewContent')` | 标准事件，可直接用于广告优化和受众 |
| 用户提交了联系表单 | `fbq('track', 'Lead')` | 标准事件，Meta 原生支持转化优化 |
| 用户下载了白皮书 | `fbq('trackCustom', 'DownloadBrochure')` | 不在 18 个标准事件内，用自定义事件记录 |
| 用户播放了介绍视频超过 50% | `fbq('trackCustom', 'VideoProgress50')` | 自定义事件，可用于再营销受众 |

---

## Meta Conversions API (CAPI) - Event Deduplication

If the user also sends events via **Meta Conversions API** (server-side), you **MUST** use `eventID` to prevent duplicate counting.

### Browser-Side: Inject eventID

```javascript
// Generate a stable but unique event ID
function generateEventId(eventName) {
  // Recommended format: <event_name>_<user_id_or_session>_<timestamp>
  // For anonymous users, use a session-based UUID or client-generated ID
  const sessionId = sessionStorage.getItem('fb_session_id') || crypto.randomUUID();
  sessionStorage.setItem('fb_session_id', sessionId);
  return `${eventName}_${sessionId}_${Date.now()}`;
}

// Send Purchase with eventID
const eventId = generateEventId('Purchase');
fbq('track', 'Purchase', {
  value: 100,
  currency: 'USD',
}, {
  eventID: eventId
});
```

### Server-Side Requirement

The same `event_id` must be included in the CAPI payload:

```json
{
  "event_name": "Purchase",
  "event_id": "Purchase_a1b2c3d4-..._1718456789012",
  "event_time": 1718456789,
  "action_source": "website",
  "user_data": { ... },
  "custom_data": { "value": 100, "currency": "USD" }
}
```

### Hard Rule

- **NEVER** let browser and CAPI send the same event without `eventID`.
- Meta's deduplication window is **48 hours**.
- `eventID` must be identical in both browser and server payloads (case-sensitive).

---

## Integration with Other Tracking Tools

If using **GA4 + Clarity + Meta Pixel** together, generate unified control:

```javascript
// Unified consent control for all three platforms
function updateAllTrackingConsent(level, isCalifornia = false) {
  // GA4 (4 parameters)
  if (window.gtag) {
    window.gtag('consent', 'update', {
      analytics_storage: level === 'denied' ? 'denied' : 'granted',
      ad_storage: level === 'all' ? 'granted' : 'denied',
      ad_user_data: level === 'all' ? 'granted' : 'denied',
      ad_personalization: level === 'all' ? 'granted' : 'denied'
    });
  }

  // Clarity (2 parameters)
  if (window.clarity) {
    window.clarity('consent', {
      analytics_storage: level === 'denied' ? 'denied' : 'granted',
      ad_storage: level === 'all' ? 'granted' : 'denied'
    });
  }

  // Meta Pixel
  if (window.fbq) {
    if (level === 'all') {
      fbq('consent', 'grant');
      if (isCalifornia) {
        fbq('dataProcessingOptions', ['LDU'], 1, 1000);
      }
    } else if (level === 'analytics') {
      fbq('consent', 'grant'); // Meta doesn't distinguish analytics vs ads like GA4
      if (isCalifornia) fbq('dataProcessingOptions', ['LDU'], 1, 1000);
    } else {
      fbq('consent', 'revoke');
    }
  }

  localStorage.setItem('tracking_consent_level', level);
  localStorage.setItem('tracking_consent_ca', isCalifornia);
}
```

---

## Duplicate Prevention Rules

| Check | Action |
|-------|--------|
| `fbq('init', ...)` already present | Reuse existing, do not re-inject base code |
| `fbq('track', 'PageView')` already present | Skip, do not add again (unless consent mode requires it) |
| `fbq('track', 'Lead')` already present | Skip, do not add again |
| `fbq('consent', ...)` already present | Preserve existing consent settings |

---

## Output Format

Always respond in this format:

```
### Privacy Configuration Summary:

- **Mode Used**: [Basic/Advanced/Standard]
- **GDPR Compliance**: [Yes/No]
- **CCPA (LDU)**: [Enabled/Disabled]
- **CAPI Deduplication**: [Advised/Not applicable]
- **Consent Storage**: localStorage key: `meta_pixel_consent`

### Changes Made:

1. [What was injected or modified]
2. [What privacy controls were added]
3. [What was skipped and why]

### Post-Deployment Checklist:

- [ ] **Privacy Policy**: Add disclosure about Meta Pixel data transfer to US
- [ ] **Cookie Banner**: Implement calls to `grantMetaConsent()` / `revokeMetaConsent()`
- [ ] **GDPR (EU)**: Ensure consent obtained before any data transmission
- [ ] **CCPA (CA)**: Enable LDU if you have California users
- [ ] **CAPI Deduplication**: If using server-side, confirm `eventID` matches browser payload
- [ ] **Testing**: Verify events fire only after consent in EU

### Updated Code:

[Full updated code with inline comments marking privacy controls]
```

---

## Hard Rules (Never Violate)

- **NEVER** invent or guess a Pixel ID
- **NEVER** duplicate any tracking call
- **NEVER** break existing logic or event handlers
- **ALWAYS** wait for valid Pixel ID before modifying code
- **ALWAYS** output the full updated file, not just the diff
- **NEVER** send Pixel data to US without consent in EU (unless using Standard mode with explicit user acknowledgment)
- **ALWAYS** warn users about Schrems II data transfer risks when Standard mode selected
- **ALWAYS** advise on `eventID` deduplication if CAPI is mentioned

---

## Usage Examples

### Example 1: EU Landing Page (Strict Compliance)

User request:
```
Add Meta Pixel to my landing page. Users are in Germany. Pixel ID: 123456789012345.
```

Skill response:
> **Compliance Alert**: You have EU users. I will implement **Advanced Consent Mode** which loads the pixel but blocks data transmission until user consent is obtained.
>
> **Implementation**:
> 1. Base code loads immediately (for performance)
> 2. `fbq('consent', 'revoke')` set initially
> 3. Your Cookie Banner must call `grantMetaConsent()` when user accepts
> 4. Lead events will only fire if consent granted

### Example 2: Multi-Region with California Users

User request:
```
Add Pixel with CCPA compliance. Some users are in California.
```

Skill response:
> **Implementing**: Advanced Consent Mode + Limited Data Use (LDU) for California.
>
> **Logic**:
> - Detect user location (or ask user to self-declare CA residency)
> - If CA user: `grantMetaConsent(true)` enables LDU
> - If EU user: Standard consent grant
> - If other: Can grant without LDU

### Example 3: Simple Implementation (Non-EU, Non-CA)

User request:
```
Add Pixel for my Singapore-only landing page.
```

Skill response:
> **Compliance Check**: Singapore only - implementing Standard mode.
>
> **Warning**: If you expand to EU/CA later, you must upgrade to Consent Mode.
>
> **Recommendation**: I will still add basic consent infrastructure for future-proofing.

---

## Version History

- **v1.0.0**: Basic pixel injection (PageView, Lead)
- **v2.0.0**: Added GDPR/ePrivacy/CCPA compliance, Consent Mode, Limited Data Use, unified control layer for GA4/Clarity/Meta
- **v2.1.0**: Fixed Advanced Consent `init` timing, added React/Next.js components, separated LDU from mode selection, added cookie clearing on revoke, added CAPI Event Deduplication guide
