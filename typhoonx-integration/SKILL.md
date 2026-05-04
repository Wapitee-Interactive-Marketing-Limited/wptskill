---
name: typhoonx-integration
description: "Integrate Wapitee TyphoonX tracking into web projects with GA4-compatible snake_case events, sendBeacon payloads, client_id cookie handling, and framework-specific implementation guidance for Next.js, React, Vue, and plain HTML."
---

# TyphoonX Integration

## Overview

TyphoonX is Wapitee's internal event tracking service. Use this skill to add browser-side tracking to a website, map business actions to TyphoonX standard events, and verify that events are sent to:

```text
https://spell.typhoonx.io/api/v1/receive
```

TyphoonX event names and ecommerce payloads intentionally follow the same naming style as Google Analytics 4: `snake_case` event names and standard ecommerce parameters such as `items`, `currency`, `value`, and `transaction_id`. TyphoonX is not GA4, but GA4 ecommerce event shapes can usually be reused.

## When to Use This Skill

- 用户提到 `TyphoonX`、`Wapitee TyphoonX`、`TyphoonX 埋点`、`TyphoonX 对接`、`TyphoonX 追踪`
- 需要在 Next.js、React、Vue、Nuxt 或纯 HTML 项目中添加 TyphoonX 事件上报
- 需要把电商、线索收集、内容站或 SaaS 的关键行为映射到标准事件
- 需要检查现有 TyphoonX 集成是否缺字段、事件名不规范或 `client_id` 处理不正确

## Core Instructions

### Step 1: Collect Required Inputs

Before generating code or editing a project, collect these values:

| Input | Required | Notes |
|-------|----------|-------|
| `TYPHOONX_MERCHANT_ID` | Yes | Must start with `TPX-`. Get it from `wapitee.io/admin` TyphoonX settings. |
| `FRAMEWORK` | Yes | One of: Next.js, React, Vue, Nuxt, HTML, or another detected framework. |
| Site type | Yes | Ecommerce, lead generation, content, SaaS, or custom. |
| Tracked actions | Yes | Examples: page view, view item, add to cart, checkout, purchase, lead submit. |
| `SHOP_ID` | Optional | Store or site identifier. Use empty string when absent. |
| `COOKIE_DOMAIN` | Optional | Only needed when `__typhoon_client_id` must be shared across subdomains. |

If `TYPHOONX_MERCHANT_ID` is missing, ask the user to retrieve it from `wapitee.io/admin` and confirm it starts with `TPX-`.

If a provided Merchant ID does not start with `TPX-`, stop and ask the user to verify it. Never generate a TyphoonX integration with an invalid Merchant ID.

### Step 2: Detect the Project Entry Point

Inspect the project before editing:

| Framework | Common Entry Point |
|-----------|--------------------|
| Next.js App Router | `app/layout.tsx`, client components, or `lib/typhoonx.ts` |
| Next.js Pages Router | `pages/_app.tsx`, `pages/_document.tsx`, or `lib/typhoonx.ts` |
| React / Vite | `src/main.tsx`, `src/App.tsx`, `index.html`, or `src/lib/typhoonx.ts` |
| Vue 3 / Vite | `src/main.ts`, composables, or `index.html` |
| Nuxt 3 | `nuxt.config.ts`, plugins, or composables |
| Plain HTML | `index.html` and inline or linked JavaScript |

Prefer creating a small reusable tracking helper such as `lib/typhoonx.ts`, `src/lib/typhoonx.ts`, or `composables/useTyphoonx.ts`. Keep framework integration thin and call the helper from page, route, component, or form handlers.

### Step 3: Implement the Tracking Contract

Every TyphoonX event must be sent with `navigator.sendBeacon` using a JSON `Blob`:

```ts
const blob = new Blob([JSON.stringify(payload)], {type: 'application/json'});
navigator.sendBeacon('https://spell.typhoonx.io/api/v1/receive', blob);
```

Every payload must include these base fields:

| Field | Source |
|-------|--------|
| `event` | Standard `snake_case` event name |
| `merchant_id` | `TYPHOONX_MERCHANT_ID`, must start with `TPX-` |
| `shop_id` | Provided `SHOP_ID` or empty string |
| `client_id` | Read from `__typhoon_client_id`; generate UUID v4 if missing |
| `referrer` | `document.referrer` |
| `request_page_url` | `window.location.href` |
| `timestamp` | `new Date().toISOString()` |
| `user_agent` | `navigator.userAgent` |

Manage `client_id` with a session cookie named `__typhoon_client_id`:

- Read the cookie before each event.
- If missing or blank, generate a UUID v4 and write it to `__typhoon_client_id`.
- Set `path=/` and `SameSite=Lax`.
- Add `domain={{COOKIE_DOMAIN}}` only when the user needs cross-subdomain tracking.

### Step 4: Map Business Actions to Standard Events

Use these standard events unless the user has a documented custom event taxonomy:

| Business Action | Event | Required Parameters | Optional Parameters |
|-----------------|-------|---------------------|---------------------|
| Page view | `page_view` | base fields | none |
| View product | `view_item` | `currency`, `items`, `value` | none |
| Add to cart | `add_to_cart` | `currency`, `items`, `value` | none |
| Remove from cart | `remove_from_cart` | `currency`, `items`, `value` | none |
| Begin checkout | `begin_checkout` | base fields | `currency`, `items`, `value`, `coupon` |
| Purchase | `purchase` | `currency`, `items`, `transaction_id`, `value` | `tax`, `shipping`, `coupon` |
| Lead submission | `generate_lead` | base fields | `email`, `lead_source`, `value`, `currency`, `transaction_id` |

For ecommerce events, `items` should contain product-level objects:

```ts
{
  item_id: 'SKU_12345',
  item_name: 'Stan and Friends Tee',
  price: 50,
  quantity: 2,
  item_category: 'Apparel',
  item_category2: 'T-Shirts',
  item_brand: 'Wapitee',
  item_variant: 'Blue / M',
}
```

`item_id`, `item_name`, `price`, and `quantity` are the minimum useful fields. Include category, brand, and variant when available.

### Step 5: Add Framework-Specific Usage

#### Next.js

- Put the helper in a client-only module such as `lib/typhoonx.ts` with `'use client'`.
- Read public values from `NEXT_PUBLIC_TYPHOONX_MERCHANT_ID`, `NEXT_PUBLIC_TYPHOONX_SHOP_ID`, and optional `NEXT_PUBLIC_TYPHOONX_COOKIE_DOMAIN`.
- Call `track('page_view')` from a client route observer or page component.
- Call ecommerce events from user handlers or checkout/order confirmation UI.

#### React

- Put the helper in `src/lib/typhoonx.ts`.
- Use build-time public env vars when available; otherwise use explicit constants supplied by the user.
- Call tracking from `useEffect` for page views and from event handlers for product, cart, checkout, and lead events.

#### Vue / Nuxt

- Prefer a composable such as `composables/useTyphoonx.ts`.
- For Vite, read `VITE_TYPHOONX_MERCHANT_ID`, `VITE_TYPHOONX_SHOP_ID`, and optional `VITE_TYPHOONX_COOKIE_DOMAIN`.
- For Nuxt, use public runtime config and ensure browser-only access to `window`, `document`, and `navigator`.

#### Plain HTML

- Add a small script loaded after the DOM is available.
- Define a global `typhoonxTrack(eventName, params)` helper.
- Attach it to click, submit, and purchase confirmation handlers.

## Verification

After implementation, verify with the browser Network panel:

1. Trigger each configured event.
2. Confirm requests are sent to `https://spell.typhoonx.io/api/v1/receive`.
3. Confirm the request body includes all base fields.
4. Confirm `merchant_id` starts with `TPX-`.
5. Confirm event names are `snake_case`.
6. Confirm `__typhoon_client_id` is created and reused within the session.
7. Confirm `purchase` includes `currency`, `items`, `transaction_id`, and `value`.
8. Confirm no event sends `undefined`, `null`, or placeholder values for required fields.

## Output Format

When reporting work back to the user, use this structure:

```markdown
### TyphoonX 埋点配置摘要

- Merchant ID: `TPX-...`
- Shop ID: `[provided / empty]`
- Framework: `[Next.js / React / Vue / Nuxt / HTML]`
- Site type: `[ecommerce / lead-gen / content / SaaS]`
- Events: `[page_view, view_item, add_to_cart, ...]`

### Post-Deployment Checklist

- [ ] Network panel shows requests to `spell.typhoonx.io/api/v1/receive`
- [ ] Every payload contains the 8 base fields
- [ ] `client_id` cookie is created and reused
- [ ] Purchase payload includes `currency`, `items`, `transaction_id`, and `value`
- [ ] TyphoonX dashboard receives expected events
```

## Best Practices

- Keep the helper small and framework-agnostic; only framework entry points should know about routing or component lifecycles.
- Use environment variables for Merchant ID and Shop ID in real projects. Do not hard-code production identifiers unless the user explicitly asks.
- Reuse existing GA4 ecommerce data objects when the project already has GA4 tracking.
- Do not send personally identifiable information unless the user confirms it is expected and legally permitted.
- Avoid duplicate page view events when frameworks re-render or hydrate client components.

## Hard Rules

- Never invent `merchant_id`, `shop_id`, product IDs, order IDs, or prices.
- Never proceed with a Merchant ID that does not start with `TPX-`.
- Always use `navigator.sendBeacon` with a JSON `Blob`.
- Always send the 8 base fields: `event`, `merchant_id`, `shop_id`, `client_id`, `referrer`, `request_page_url`, `timestamp`, `user_agent`.
- Always use `snake_case` event names. Do not use camelCase, spaces, or ad-platform event names such as `AddToCart` or `CompletePayment`.
- Always manage `client_id` through the `__typhoon_client_id` session cookie.
- Always include `currency`, `items`, `transaction_id`, and `value` for `purchase`.
- Always include `item_id`, `item_name`, `price`, and `quantity` when sending ecommerce `items`.
