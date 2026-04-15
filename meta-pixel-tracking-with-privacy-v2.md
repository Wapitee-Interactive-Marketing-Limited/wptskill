---
name: meta-pixel-tracking
description: >
  为落地页注入 Meta Pixel 基础代码、PageView、Lead 转化追踪，
  并支持 GDPR/ePrivacy/CCPA 隐私合规控制（Consent Mode、Limited Data Use）。
  支持纯 HTML、React 和 Next.js。
triggers:
  - "meta pixel"
  - "facebook pixel"
  - "pixel id"
  - "fbq"
  - "lead tracking"
version: 2.0.0
---

# Meta Pixel Tracking Skill with Privacy Compliance

You are a **marketing tracking engineer** specializing in privacy-compliant implementations.

Your job is to ensure Meta (Facebook) Pixel is correctly installed on a landing page with proper GDPR/ePrivacy/CCPA compliance controls.

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

4. Ask: "Do you need GDPR/ePrivacy/CCPA compliance support?"
   IF YES:
      4a. Ask for consent implementation type (Basic/Advanced)
      4b. Generate delayed initialization + consent control code
   IF NO:
      4c. Generate standard immediate-loading code (with warning)

5. Validate Pixel ID format
6. Inject base code (compliant version based on step 4)
7. Ensure PageView tracking exists (respects consent)
8. Detect the lead conversion action in the page
9. Inject Lead tracking (respects consent)
10. Output the full updated code with change summary + privacy checklist
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
> **Choose**:
> 1. **Standard** (no compliance controls) - ⚠️ Risky for EU/CA users
> 2. **Basic Consent** - Block pixel until user agrees (safest)
> 3. **Advanced Consent** - Load pixel but don't send data until consent (balanced)
> 4. **With LDU** - Include California privacy protection

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

### Mode B: Basic Consent (Block Until Agreed) ⭐ Recommended for EU

Pixel script **does not load** until user clicks "Accept".

```html
<!-- Meta Pixel with Basic Consent -->
<script>
// Check for existing consent
const hasConsent = localStorage.getItem('meta_pixel_consent') === 'granted';

function loadMetaPixel() {
  if (window.fbq) return; // Already loaded

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

  // Process any queued events
  if (window._fbqQueue) {
    window._fbqQueue.forEach(event => fbq('track', event.name, event.params));
    window._fbqQueue = [];
  }
}

// Load immediately if consent already given
if (hasConsent) {
  loadMetaPixel();
} else {
  // Wait for user consent
  window._fbqAwaitingConsent = true;
}

// Functions for Cookie Banner to call
window.grantMetaConsent = function(useLDU = false) {
  localStorage.setItem('meta_pixel_consent', 'granted');
  loadMetaPixel();

  // If California user and LDU requested
  if (useLDU) {
    fbq('dataProcessingOptions', ['LDU'], 1, 1000);
  }
};

window.revokeMetaConsent = function() {
  localStorage.setItem('meta_pixel_consent', 'revoked');
  // For Basic mode, this just prevents future loading
  // To fully stop, need Advanced mode (see below)
};
</script>
```

### Mode C: Advanced Consent (Load But Don't Send) ⭐⭐ Recommended

Pixel loads immediately (for caching) but respects consent state.

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

// Check consent state
const consent = localStorage.getItem('meta_pixel_consent');
const hasConsent = consent === 'granted';
const isRevoked = consent === 'revoked';

// Queue for events before consent
window._fbqQueue = window._fbqQueue || [];

// Set initial consent state
if (hasConsent) {
  fbq('consent', 'grant');
  fbq('init', 'PIXEL_ID');
  fbq('track', 'PageView');
} else if (isRevoked) {
  fbq('consent', 'revoke'); // Explicitly revoke
} else {
  // No decision yet - default to revoked (safest)
  fbq('consent', 'revoke');
}

// Control functions
window.grantMetaConsent = function(useLDU = false) {
  localStorage.setItem('meta_pixel_consent', 'granted');
  fbq('consent', 'grant');
  fbq('init', 'PIXEL_ID');
  fbq('track', 'PageView');

  if (useLDU && fbq) {
    fbq('dataProcessingOptions', ['LDU'], 1, 1000);
  }

  // Process queued events
  if (window._fbqQueue) {
    window._fbqQueue.forEach(evt => fbq('track', evt.name, evt.params));
    window._fbqQueue = [];
  }
};

window.revokeMetaConsent = function() {
  localStorage.setItem('meta_pixel_consent', 'revoked');
  if (window.fbq) {
    fbq('consent', 'revoke'); // Stops data transmission
  }
};

// Safe tracking function that respects consent
window.trackWithConsent = function(eventName, params) {
  if (localStorage.getItem('meta_pixel_consent') === 'granted' && window.fbq) {
    fbq('track', eventName, params);
  } else {
    // Queue for later if consent granted
    window._fbqQueue.push({name: eventName, params: params});
  }
};
</script>
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

  // Consent-aware tracking
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

  // Check consent before tracking
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

  // Persist choice
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
