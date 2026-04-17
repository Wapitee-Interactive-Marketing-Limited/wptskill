---
name: wapitee-typhoonx-setup
description: >
  Wapitee 内部数据追踪功能 TyphoonX 的埋点配置助手。
  事件名称与参数采用与 Google Analytics 4 完全一致的标准规范（snake_case），
  支持多技术栈代码生成。
triggers:
  - "typhoonx"
  - "wapitee typhoonx"
  - "typhoonx 埋点"
  - "typhoonx 对接"
  - "typhoonx 追踪"
version: 1.0.0
---

# Wapitee TyphoonX 埋点配置助手

## 触发条件

当用户提到以下关键词时激活：
- "typhoonx"
- "wapitee typhoonx"
- "typhoonx 埋点"
- "typhoonx 对接"
- "typhoonx 追踪"

## 核心工作流（含中断式交互）

### 阶段 1：信息收集（中断提问模式）

**以下信息缺失任何一项都必须中断并询问用户：**

1. **TyphoonX 配置信息**
   - [ ] `TYPHOONX_MERCHANT_ID`: 从 wapitee.io/admin 的 TyphoonX Setting 中获取的商户 ID。**必须以 `TPX-` 开头**
   - [ ] `SHOP_ID`（可选）: 店铺/站点唯一标识（如 Shopify 店铺 ID 或自研系统站点 ID）。如无则留空
   - [ ] `COOKIE_DOMAIN`（可选）: 设置 `__typhoon_client_id` Session cookie 的 domain。如需跨子域名共享（如 `.example.com`），请提供；单站点无需配置

2. **项目技术栈**
   - [ ] `FRAMEWORK`: 前端框架（nextjs / react / vue）

3. **业务场景与事件映射**
   - [ ] 网站类型：电商（e-commerce）/ 线索收集（lead-gen）/ 内容站（content）/ SaaS
   - [ ] 需要追踪的关键用户行为（页面浏览、查看商品、加入购物车、移除购物车、开始结账、购买、提交线索）

### 阶段 2：中断提问逻辑（关键）

**规则：如果以下任一条件满足，立即停止生成配置并询问用户：**

```markdown
IF 用户未提供 TYPHOONX_MERCHANT_ID:
  → 中断并提问：
     "请按以下步骤获取 TyphoonX Merchant ID：
      1. 登录 wapitee.io/admin
      2. 进入 TyphoonX > Merchant Management
      3. 选择你要追踪的商户
      4. 复制 Merchant ID 并提供给我
      5. ⚠️ 注意：Merchant ID 必须以 TPX- 开头（例如 TPX-12345678）。如果不是，请检查是否复制正确。"

IF 用户提供了 TYPHOONX_MERCHANT_ID 但非 TPX- 开头:
  → 中断并纠正：
     "你提供的 Merchant ID 似乎不是以 TPX- 开头。TyphoonX Merchant ID 的标准格式为 TPX-XXXXXXXX。
      请返回 wapitee.io/admin > TyphoonX > Merchant Management 重新核对并复制正确的 ID。"

IF 用户未提供 FRAMEWORK:
  → 中断并提问："你的项目使用什么技术栈？（nextjs / react / vue / html）"

IF 用户未说明业务场景或事件映射:
  → 中断并提问：
     "请告诉我你的站点类型和需要追踪的关键行为，我会帮你映射到 TyphoonX 标准事件：
      - 站点类型？（电商 / 线索收集 / 内容站 / SaaS）
      - 是否需要追踪：页面浏览、查看商品、加入购物车、移除购物车、开始结账、购买、提交线索？"
```

### 阶段 3：根据收集的信息生成配置

#### 通用规范（所有技术栈必须遵循）

**TyphoonX 数据上报规范：**
- 上报地址：`https://spell.typhoonx.io/api/v1/receive`
- 上报方式：`navigator.sendBeacon`
- 请求体：`Blob`（`type: application/json`）

**所有事件必须包含以下基础字段：**

| 字段 | 说明 | 获取方式示例 |
|:---|:---|:---|
| `event` | 事件名（严格 `snake_case`） | 硬编码 |
| `merchant_id` | TyphoonX Merchant ID（`TPX-` 开头） | `{{TYPHOONX_MERCHANT_ID}}` |
| `shop_id` | 店铺/站点 ID（可选） | `{{SHOP_ID}}` 或空字符串 |
| `client_id` | 客户端唯一标识 | 从 `__typhoon_client_id` Session cookie 读取，不存在则生成 UUID v4 |
| `referrer` | 来源页面 URL | `document.referrer` |
| `request_page_url` | 当前页面 URL | `window.location.href` |
| `timestamp` | ISO 8601 时间戳 | `new Date().toISOString()` |
| `user_agent` | 浏览器 User-Agent | `navigator.userAgent` |

**事件推送规范：**
- 事件名必须严格使用 `snake_case` 命名，禁止空格和 camelCase
- 参数结构采用与 **Google Analytics 4 完全一致**的标准规范（但这只是规范上的巧合，TyphoonX 本身与 GA4 无直接关联）
- 如果你同时使用 GA4，TyphoonX 的事件代码可以直接复用，无需额外转换

---

## TyphoonX 标准事件映射表

**CRITICAL**: TyphoonX 事件名使用 `snake_case`，大小写敏感。

| 业务场景 | 事件名 | 必填参数 | 可选参数 |
|:---|:---|:---|:---|
| 页面浏览 | `page_view` | — | — |
| 查看商品详情 | `view_item` | `currency`, `items`, `value` | — |
| 加入购物车 | `add_to_cart` | `currency`, `items`, `value` | — |
| 移除购物车 | `remove_from_cart` | `currency`, `items`, `value` | — |
| 开始结账 | `begin_checkout` | — | `currency`, `items`, `value`, `coupon` |
| 购买完成 | `purchase` | `currency`, `items`, `transaction_id`, `value` | `tax`, `shipping`, `coupon` |
| 提交线索表单 | `generate_lead` | — | `email`, `lead_source`, `value`, `currency`, `transaction_id` |

### `items` 数组标准结构

```javascript
const items = [{
  item_id: 'SKU_12345',
  item_name: 'Stan and Friends Tee',
  item_category: 'Apparel',
  item_category2: 'T-Shirts',
  price: 50.00,
  quantity: 2,
  item_brand: 'Wapitee',
  item_variant: 'Blue / M'
}];
```

## 分技术栈实现

### 通用上报函数（所有前端技术栈通用）

```javascript
const TYPHOONX_API = 'https://spell.typhoonx.io/api/v1/receive';
const MERCHANT_ID = '{{TYPHOONX_MERCHANT_ID}}';
const SHOP_ID = '{{SHOP_ID}}' || '';

function getCookie(name) {
  if (typeof document === 'undefined') return null;
  var nameEQ = name + '=';
  var cookies = document.cookie.split(';');
  for (var i = 0; i < cookies.length; i++) {
    var cookie = cookies[i];
    while (cookie.charAt(0) === ' ') cookie = cookie.substring(1, cookie.length);
    if (cookie.indexOf(nameEQ) === 0) return cookie.substring(nameEQ.length, cookie.length);
  }
  return null;
}

function setSessionCookie(name, value, domain) {
  if (typeof document === 'undefined') return;
  var cookieStr = name + '=' + value + '; path=/; SameSite=Lax';
  if (domain) cookieStr += '; domain=' + domain;
  document.cookie = cookieStr;
}

function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0;
    var v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function getClientId() {
  if (typeof document === 'undefined') return '';
  var cookieName = '__typhoon_client_id';
  var clientId = getCookie(cookieName);
  if (!clientId || clientId.trim() === '') {
    clientId = generateUUID();
    setSessionCookie(cookieName, clientId, '{{COOKIE_DOMAIN}}');
  }
  return clientId;
}

function typhoonxTrack(eventName, params) {
  const payload = {
    event: eventName,
    merchant_id: MERCHANT_ID,
    shop_id: SHOP_ID || '',
    client_id: getClientId(),
    referrer: typeof document !== 'undefined' ? document.referrer : '',
    request_page_url: typeof window !== 'undefined' ? window.location.href : '',
    timestamp: new Date().toISOString(),
    user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
    ...(params || {}),
  };

  const blob = new Blob([JSON.stringify(payload)], { type: 'application/json' });

  if (typeof window !== 'undefined' && window.navigator.sendBeacon) {
    window.navigator.sendBeacon(TYPHOONX_API, blob);
  }
}
```

---

### 1. Next.js 14 (App Router)

```tsx
// lib/typhoonx.ts
'use client';

const TYPHOONX_API = 'https://spell.typhoonx.io/api/v1/receive';
const MERCHANT_ID = process.env.NEXT_PUBLIC_TYPHOONX_MERCHANT_ID;
const SHOP_ID = process.env.NEXT_PUBLIC_TYPHOONX_SHOP_ID || '';

function getCookie(name: string): string | null {
  if (typeof document === 'undefined') return null;
  const nameEQ = name + '=';
  const cookies = document.cookie.split(';');
  for (let i = 0; i < cookies.length; i++) {
    let cookie = cookies[i];
    while (cookie.charAt(0) === ' ') cookie = cookie.substring(1, cookie.length);
    if (cookie.indexOf(nameEQ) === 0) return cookie.substring(nameEQ.length, cookie.length);
  }
  return null;
}

function setSessionCookie(name: string, value: string, domain?: string) {
  if (typeof document === 'undefined') return;
  let cookieStr = name + '=' + value + '; path=/; SameSite=Lax';
  if (domain) cookieStr += '; domain=' + domain;
  document.cookie = cookieStr;
}

function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function getClientId(): string {
  if (typeof document === 'undefined') return '';
  const cookieName = '__typhoon_client_id';
  let clientId = getCookie(cookieName);
  if (!clientId || clientId.trim() === '') {
    clientId = generateUUID();
    setSessionCookie(cookieName, clientId, process.env.NEXT_PUBLIC_TYPHOONX_COOKIE_DOMAIN);
  }
  return clientId;
}

export function typhoonxTrack(eventName: string, params?: Record<string, unknown>) {
  if (typeof window === 'undefined' || !MERCHANT_ID) return;

  const payload = {
    event: eventName,
    merchant_id: MERCHANT_ID,
    shop_id: SHOP_ID || '',
    client_id: getClientId(),
    referrer: document.referrer,
    request_page_url: window.location.href,
    timestamp: new Date().toISOString(),
    user_agent: navigator.userAgent,
    ...(params || {}),
  };

  const blob = new Blob([JSON.stringify(payload)], { type: 'application/json' });

  window.navigator.sendBeacon(TYPHOONX_API, blob);
}

// 购买事件示例
export function trackPurchase(data: {
  transaction_id: string;
  value: number;
  currency: string;
  items: Array<{
    item_id: string;
    item_name: string;
    price: number;
    quantity: number;
    item_category?: string;
  }>;
}) {
  typhoonxTrack('purchase', data);
}
```

```env
# .env.local
NEXT_PUBLIC_TYPHOONX_MERCHANT_ID={{TYPHOONX_MERCHANT_ID}}
NEXT_PUBLIC_TYPHOONX_SHOP_ID={{SHOP_ID}}
# 可选：如需跨子域名共享 client_id cookie，请配置（例如 .looki.ai）
NEXT_PUBLIC_TYPHOONX_COOKIE_DOMAIN={{COOKIE_DOMAIN}}
```

---

### 3. React (客户端)

```typescript
// lib/typhoonx.ts
const TYPHOONX_API = 'https://spell.typhoonx.io/api/v1/receive';
const MERCHANT_ID = '{{TYPHOONX_MERCHANT_ID}}';
const SHOP_ID = '{{SHOP_ID}}' || '';

function getCookie(name) {
  var nameEQ = name + '=';
  var cookies = document.cookie.split(';');
  for (var i = 0; i < cookies.length; i++) {
    var cookie = cookies[i];
    while (cookie.charAt(0) === ' ') cookie = cookie.substring(1, cookie.length);
    if (cookie.indexOf(nameEQ) === 0) return cookie.substring(nameEQ.length, cookie.length);
  }
  return null;
}

function setSessionCookie(name, value, domain) {
  var cookieStr = name + '=' + value + '; path=/; SameSite=Lax';
  if (domain) cookieStr += '; domain=' + domain;
  document.cookie = cookieStr;
}

function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0;
    var v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function getClientId() {
  var cookieName = '__typhoon_client_id';
  var clientId = getCookie(cookieName);
  if (!clientId || clientId.trim() === '') {
    clientId = generateUUID();
    setSessionCookie(cookieName, clientId, '{{COOKIE_DOMAIN}}');
  }
  return clientId;
}

export function typhoonxTrack(eventName: string, params?: Record<string, unknown>) {
  const payload = {
    event: eventName,
    merchant_id: MERCHANT_ID,
    shop_id: SHOP_ID || '',
    client_id: getClientId(),
    referrer: document.referrer,
    request_page_url: window.location.href,
    timestamp: new Date().toISOString(),
    user_agent: navigator.userAgent,
    ...(params || {}),
  };

  const blob = new Blob([JSON.stringify(payload)], { type: 'application/json' };
  window.navigator.sendBeacon(TYPHOONX_API, blob);
}
```

```tsx
// 组件中使用
import { typhoonxTrack } from './lib/typhoonx';

function ProductCard({ product }: { product: any }) {
  const handleAddToCart = () => {
    typhoonxTrack('add_to_cart', {
      currency: 'USD',
      value: product.price,
      items: [{
        item_id: product.sku,
        item_name: product.name,
        price: product.price,
        quantity: 1,
        item_category: product.category
      }]
    });
  };

  return <button onClick={handleAddToCart}>加入购物车</button>;
}
```

---

### 4. Vue 3

```typescript
// composables/useTyphoonx.ts
const TYPHOONX_API = 'https://spell.typhoonx.io/api/v1/receive';
const MERCHANT_ID = import.meta.env.VITE_TYPHOONX_MERCHANT_ID;
const SHOP_ID = import.meta.env.VITE_TYPHOONX_SHOP_ID || '';

function getCookie(name) {
  var nameEQ = name + '=';
  var cookies = document.cookie.split(';');
  for (var i = 0; i < cookies.length; i++) {
    var cookie = cookies[i];
    while (cookie.charAt(0) === ' ') cookie = cookie.substring(1, cookie.length);
    if (cookie.indexOf(nameEQ) === 0) return cookie.substring(nameEQ.length, cookie.length);
  }
  return null;
}

function setSessionCookie(name, value, domain) {
  var cookieStr = name + '=' + value + '; path=/; SameSite=Lax';
  if (domain) cookieStr += '; domain=' + domain;
  document.cookie = cookieStr;
}

function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0;
    var v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function getClientId() {
  if (typeof document === 'undefined') return '';
  var cookieName = '__typhoon_client_id';
  var clientId = getCookie(cookieName);
  if (!clientId || clientId.trim() === '') {
    clientId = generateUUID();
    setSessionCookie(cookieName, clientId, import.meta.env.VITE_TYPHOONX_COOKIE_DOMAIN || '');
  }
  return clientId;
}

export function useTyphoonx() {
  const track = (eventName: string, params?: Record<string, unknown>) => {
    if (typeof window === 'undefined' || !MERCHANT_ID) return;

    const payload = {
      event: eventName,
      merchant_id: MERCHANT_ID,
      shop_id: SHOP_ID || '',
      client_id: getClientId(),
      referrer: document.referrer,
      request_page_url: window.location.href,
      timestamp: new Date().toISOString(),
      user_agent: navigator.userAgent,
      ...(params || {}),
    };

    const blob = new Blob([JSON.stringify(payload)], { type: 'application/json' });

    window.navigator.sendBeacon(TYPHOONX_API, blob);
  };

  return { track };
}
```

```vue
<script setup>
import { useTyphoonx } from '@/composables/useTyphoonx';

const { track } = useTyphoonx();

function handleLeadSubmit(email) {
  if (!email) return;
  track('generate_lead', {
    email,
    lead_source: 'standard'
  });
}
</script>
```

---

## 输出格式

```markdown
### TyphoonX 埋点配置摘要

- **TyphoonX Merchant ID**: {{TYPHOONX_MERCHANT_ID}}
- **Shop ID**: {{SHOP_ID}}（可选，未提供时为空）
- **框架**: [HTML / Next.js / React / Vue]
- **站点类型**: [电商 / 线索收集 / 内容站 / SaaS]
- **追踪事件列表**: [page_view, view_item, add_to_cart, remove_from_cart, begin_checkout, purchase, generate_lead]

### 变更说明

1. [配置了 sendBeacon 上报地址和基础 payload 结构]
2. [添加了 XX 个标准事件的追踪代码]
3. [配置了 items 数组参数结构]

### Post-Deployment Checklist

- [ ] **TyphoonX 后台确认**：wapitee.io/admin 中 Merchant ID 以 `TPX-` 开头且配置正确
- [ ] **Shop ID 校验**（如提供）：请求体中 `shop_id` 正确
- [ ] **事件命名检查**：所有事件使用 `snake_case`，无空格和 camelCase
- [ ] **Purchase 必填项**：`purchase` 事件包含 `currency`、`items`、`transaction_id`、`value` + 基础字段
- [ ] **Items 数组格式**：`item_id`、`item_name`、`price`、`quantity` 字段完整
- [ ] **基础字段完整**：每个事件都包含 `merchant_id`、`shop_id`、`client_id`、`referrer`、`request_page_url`、`timestamp`、`user_agent`
- [ ] **Client ID 生成**：`__typhoon_client_id` cookie 正确写入，跨子域名场景下 domain 配置生效
- [ ] **端到端测试**：在真实页面完成一次购买/表单提交，通过 Network 面板确认 `spell.typhoonx.io/api/v1/receive` 收到 200

### 生成的代码

[Full code]
```

---

## 交互示例

**用户说**："我要在电商站上加 TyphoonX 埋点"

**Skill 响应**：
> 我来帮你配置 Wapitee TyphoonX 的埋点。
>
> **请先提供以下信息：**
> 1. 登录 [wapitee.io/admin](https://wapitee.io/admin)，进入 TyphoonX > Merchant Management，复制 **Merchant ID**（必须以 `TPX-` 开头）
> 2. 你的技术栈（nextjs / react / vue / html）
> 3. 如有 Shop ID（店铺/站点唯一标识），也可以一并提供；没有则留空
> 4. 你的站点类型和需要追踪的关键行为（如：加购、移除购物车、结账、购买、提交线索等）
>
> 提供以上信息后，我会为你生成完整的埋点代码和事件映射。

---

## 硬规则（Never Violate）

- **NEVER** 虚构 Merchant ID 或 Shop ID
- **NEVER** 接受非 `TPX-` 开头的 Merchant ID — 若用户提供则必须中断并纠正
- **NEVER** 对 TyphoonX 自定义事件使用 camelCase 或空格 — 必须 `snake_case`
- **ALWAYS** 确保每个事件 payload 都包含 8 个基础字段：`event`、`merchant_id`、`shop_id`、`client_id`、`referrer`、`request_page_url`、`timestamp`、`user_agent`（其中 `shop_id` 可选，未提供时为空字符串）
- **ALWAYS** 通过 `__typhoon_client_id` Session cookie 管理 `client_id`：存在则读取，不存在则生成 UUID v4 并写入；`COOKIE_DOMAIN` 按需配置跨子域名共享
- **ALWAYS** 在 `purchase` 事件中额外包含 `currency`、`items`、`transaction_id`、`value`
- **ALWAYS** 确保 `items` 数组中的对象包含 `item_id`、`item_name`、`price`、`quantity`
- **ALWAYS** 使用 `navigator.sendBeacon` 上报至 `https://spell.typhoonx.io/api/v1/receive`
