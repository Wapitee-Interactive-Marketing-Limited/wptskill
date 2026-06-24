# Landing Page TyphoonX 安装指南

<!-- ai-directive: must-ask-merchant-id -->

## AI 执行规则（必读）

**在开始生成任何代码之前，AI 必须执行以下步骤：**

1. **主动询问 `merchant_id`**
   - `merchant_id` 必须在 TyphoonX 后台生成（格式如 `TPX-LANDING-001`）。
   - **如果用户没有提供，必须中断并提问：** "请提供你的 TyphoonX `merchant_id`（例如 `TPX-LANDING-001`）。如果你还没有，需要先在 TyphoonX 后台创建。"

2. **明确告知用户：无需额外 SDK**
   - `typid`（用户唯一标识）：由脚本**内部自动生成**并写入 Cookie，无需额外文件。
   - `session_id`（会话标识）：由脚本**内部自动生成**并写入 `sessionStorage`，无需额外文件。
   - `client_id`：Landing Page 场景下**主动留空**，因为该字段是 Shopify 专用。

3. **输出完整代码包**
   - 必须包含：基础追踪脚本 + `merchant_id` 配置 + `generate_lead` 触发示例。
   - 如果用户提供了表单选择器（如 `#lead-form`），应在示例中直接使用。

---

## 概述

本指南用于在独立的 Landing Page 上集成 TyphoonX 追踪系统。适用于仅接收流量、无需完整 Shopify 集成的场景。

 Landing Page 将自动追踪以下标准事件：
- `page_view` —— 页面加载时触发
- `engaged_view` —— 用户停留 5 秒后触发
- `generate_lead` —— 用户提交表单/产生线索时手动触发

## 集成方式

### 1. 基础安装

将以下代码粘贴到 Landing Page 的 `<head>` 中（尽量靠前）：

```html
<script>
(function() {
  'use strict';

  // ==================== 配置 ====================
  const CONFIG = {
    ENDPOINT: 'https://spell.typhoonx.io/api/v1/receive',
    COOKIE_NAME: 'typid',
    COOKIE_EXPIRES_DAYS: 365 * 2,
    ENGAGED_VIEW_DELAY_MS: 5000,
    DEBUG: false,
  };

  // ==================== 工具函数 ====================
  function log() {
    if (CONFIG.DEBUG) console.log('[TyphoonX LP]', ...arguments);
  }

  function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  function getCookie(name) {
    const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
    return match ? decodeURIComponent(match[2]) : null;
  }

  function setCookie(name, value, days) {
    const expires = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
    const domainParts = window.location.hostname.split('.');
    const domain = domainParts.length > 2 ? '.' + domainParts.slice(-2).join('.') : window.location.hostname;
    const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
    const domainStr = isLocalhost ? '' : '; domain=' + domain;
    const secure = window.location.protocol === 'https:' ? '; secure' : '';
    document.cookie = `${name}=${encodeURIComponent(value)}${domainStr}; expires=${expires.toUTCString()}; path=/; SameSite=Lax${secure}`;
  }

  function getSessionId() {
    const key = 'typhoon_session';
    try {
      const stored = sessionStorage.getItem(key);
      if (stored) {
        const session = JSON.parse(stored);
        if (Date.now() - session.lastActivity < 30 * 60 * 1000) {
          session.lastActivity = Date.now();
          sessionStorage.setItem(key, JSON.stringify(session));
          return session.id;
        }
      }
    } catch (e) {}
    const id = generateUUID();
    try {
      sessionStorage.setItem(key, JSON.stringify({ id, lastActivity: Date.now() }));
    } catch (e) {}
    return id;
  }

  function getUrlParams() {
    const url = new URL(window.location.href);
    const result = {};
    const keys = [
      'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content', 'utm_id',
      'ttm_source', 'ttm_medium', 'ttm_campaign', 'ttm_term', 'ttm_content', 'ttm_id',
      'fbclid', 'fb_ad_id', 'fb_campaign_id',
      'gclid', 'gad_campaignid', 'gad_source', 'gbraid',
      'kbr_campaign', 'kbr_content', 'kbr_medium', 'kbr_source',
      'campaign_id', 'ad_id'
    ];
    keys.forEach(k => {
      const v = url.searchParams.get(k);
      if (v) result[k] = v;
    });
    return result;
  }

  // ==================== 核心状态 ====================
  const state = {
    typid: null,
    sessionId: getSessionId(),
    merchantId: window.typhoonConfig?.merchantId || '',
    shopId: window.typhoonConfig?.shopId || '',
    engagedViewFired: false,
  };

  // 初始化 typid（用户唯一标识）
  function initTypId() {
    let id = getCookie(CONFIG.COOKIE_NAME);
    if (!id) {
      id = generateUUID();
      setCookie(CONFIG.COOKIE_NAME, id, CONFIG.COOKIE_EXPIRES_DAYS);
      log('New typid generated:', id);
    } else {
      log('Existing typid:', id);
    }
    state.typid = id;
  }

  // ==================== 事件发送 ====================
  function buildPayload(eventType, extraProperties) {
    return {
      timestamp: new Date().toISOString(),
      event_type: eventType,
      typid: state.typid,
      client_id: '',           // Shopify 专用，Landing Page 留空
      session_id: state.sessionId,
      merchant_id: state.merchantId,
      shop_id: state.shopId,
      request_page_url: window.location.href,
      referrer: document.referrer || '',
      user_agent: navigator.userAgent,
      ip_address: '',          // Worker 从 CF 头解析，客户端不主动传
      _noscript: false,
      ...getUrlParams(),       // UTM / TTM / FB / Google / Kickbooster
      properties: {
        page_title: document.title,
        page_path: window.location.pathname,
        screen_width: window.screen.width,
        screen_height: window.screen.height,
        viewport_width: window.innerWidth,
        viewport_height: window.innerHeight,
        language: navigator.language || '',
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || '',
        ...extraProperties
      }
    };
  }

  function sendEvent(eventType, extraProperties) {
    const payload = buildPayload(eventType, extraProperties);
    const payloadStr = JSON.stringify(payload);

    log('Sending event:', eventType, payload);

    // 优先使用 sendBeacon（页面关闭也能发）
    if (navigator.sendBeacon) {
      const blob = new Blob([payloadStr], { type: 'application/json' });
      const sent = navigator.sendBeacon(CONFIG.ENDPOINT, blob);
      if (sent) {
        log('Sent via beacon:', eventType);
        return;
      }
    }

    // Fallback: fetch with keepalive
    fetch(CONFIG.ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: payloadStr,
      keepalive: true,
    }).then(() => {
      log('Sent via fetch:', eventType);
    }).catch(err => {
      log('Send failed:', err);
    });
  }

  // ==================== 自动追踪 ====================
  function initTracking() {
    initTypId();

    // 1. 立即发送 page_view
    sendEvent('page_view');

    // 2. 5秒后发送 engaged_view（只发一次）
    setTimeout(() => {
      if (!state.engagedViewFired) {
        state.engagedViewFired = true;
        sendEvent('engaged_view', { engagement_duration_ms: CONFIG.ENGAGED_VIEW_DELAY_MS });
      }
    }, CONFIG.ENGAGED_VIEW_DELAY_MS);

    // 页面关闭/隐藏时，如果还没发 engaged_view，尝试补发
    const flushEngagedView = () => {
      if (!state.engagedViewFired) {
        state.engagedViewFired = true;
        sendEvent('engaged_view', { engagement_duration_ms: Date.now() - performance.timing.navigationStart });
      }
    };
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'hidden') flushEngagedView();
    });
    window.addEventListener('pagehide', flushEngagedView);
  }

  // ==================== 公开 API ====================
  window.typhoon = window.typhoon || function(command, ...args) {
    if (command === 'event' && args[0]) {
      const eventType = args[0];
      const props = args[1] || {};
      sendEvent(eventType, props);
    } else if (command === 'lead' || command === 'generate_lead') {
      const props = args[0] || {};
      sendEvent('generate_lead', props);
    } else if (command === 'config' && args[0]) {
      if (args[0].merchantId) state.merchantId = args[0].merchantId;
      if (args[0].shopId) state.shopId = args[0].shopId;
      if (args[0].debug) CONFIG.DEBUG = args[0].debug;
    }
  };

  // ==================== 初始化 ====================
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initTracking);
  } else {
    initTracking();
  }
})();
</script>
```

### 2. 配置 Merchant ID

在引入上述脚本之前，添加配置对象：

```html
<script>
window.typhoonConfig = {
  merchantId: 'TPX-LANDING-001',
  shopId: 'landing-variant-a'  // 可选
};
</script>
```

### 3. 手动触发 generate_lead

当用户提交表单或产生线索时调用：

```html
<script>
document.querySelector('#lead-form').addEventListener('submit', function(e) {
  const email = document.querySelector('#email').value;
  typhoon('lead', {
    email: email,
    form_id: 'hero-form',
    landing_page_variant: 'A'
  });
});
</script>
```

## 自动触发的事件

| 事件 | 触发时机 | 说明 |
|------|----------|------|
| `page_view` | DOM 加载完成后立即触发 | 标准页面浏览事件 |
| `engaged_view` | 页面停留 5 秒后 | 表示用户真正看了页面 |
| `engaged_view`（补发） | 页面关闭/隐藏时 | 如果 5 秒未到但已关闭，会按实际停留时间补发 |

## 数据字段映射

发送的 JSON 结构与 Worker `/api/v1/receive` 端点完全兼容，字段说明如下：

| 字段 | 值 | 说明 |
|------|-----|------|
| `timestamp` | ISO 8601 字符串 | 客户端生成的事件时间 |
| `event_type` | `page_view` / `engaged_view` / `generate_lead` | ClickHouse 标准事件名 |
| `typid` | UUID Cookie | 用户唯一标识，跨会话持久 |
| `client_id` | `''` |  Shopify 专用，Landing Page 留空 |
| `session_id` | UUID | sessionStorage 内 30 分钟有效 |
| `merchant_id` | `window.typhoonConfig.merchantId` | 商户标识 |
| `shop_id` | `window.typhoonConfig.shopId` | 店铺/变体标识（可选） |
| `request_page_url` | `window.location.href` | 当前完整 URL |
| `referrer` | `document.referrer` | 来源页面 |
| `user_agent` | `navigator.userAgent` | 浏览器 UA |
| `ip_address` | `''` | 由 Worker 从 `CF-Connecting-IP` 自动解析 |
| `_noscript` | `false` | 非 noscript 请求 |
| `utm_*` / `ttm_*` / `fbclid` / `gclid` / `kbr_*` 等 | URL 参数 | 自动从当前页面 URL 提取 |
| `properties` | JSON 对象 | 包含页面标题、屏幕尺寸、语言、时区、以及自定义属性 |

## Worker 兼容性确认

- 接收端点：`POST https://spell.typhoonx.io/api/v1/receive`
- 请求格式：单条 JSON，`Content-Type: application/json`
- Worker 中的 `normalizeEvent()` 函数兼容 `event_type`、`typid`、`client_id`（为空时自动处理）、`session_id`、所有 UTM/追踪参数以及 `properties` 字段
- `ip_address` 留空时，Worker 会按优先级从 `CF-Connecting-IPv4` → `CF-Connecting-IP` → `X-Forwarded-For` 自动提取真实 IP

## 调试

开启调试模式查看控制台日志：

```html
<script>
window.typhoonConfig = { debug: true };
</script>
```

或运行：

```javascript
typhoon('config', { debug: true });
```

---

**注意**：每次修改 Tracking 代码不需要重新部署 Worker，因为数据是通过标准的 `/api/v1/receive` 端点接收的。
