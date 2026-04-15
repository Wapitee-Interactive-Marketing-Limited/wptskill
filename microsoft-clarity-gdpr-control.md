---
name: microsoft-clarity-gdpr-control
description: >
  专门处理 Microsoft Clarity 与 Cookie Banner 的隐私合规集成。
  在开发 Cookie Consent Banner 时调用此 Skill，生成符合 GDPR/CCPA/个人信息保护法的
  Clarity Consent Mode V2 控制代码。
  支持：延迟加载、同意级别动态切换、无 Cookie 模式、完全阻止模式。
  可与 Cookiebot、OneTrust、Osano、Quantcast 或自建 Banner 集成。
triggers:
  - "cookie banner clarity"
  - "clarity consent mode"
  - "gdpr clarity"
  - "隐私合规 clarity"
  - "开发 cookie 同意 banner"
version: 1.0.0
---

# Microsoft Clarity 隐私合规控制器

## 触发条件

当用户提到以下场景时激活：
- "cookie banner clarity"
- "clarity consent mode"
- "用户拒绝 cookie 后 clarity 怎么办"
- "隐私合规 clarity"
- "gdpr clarity 设置"
- "开发 cookie 同意 banner"
- "clarity 同意管理"

## 核心机制：Consent Mode V2

Microsoft Clarity 使用 **两个信号维度** [参考 Microsoft 官方文档]：

| 信号 | Cookie Banner 对应类别 | 控制内容 | 拒绝时的行为 |
|------|----------------------|----------|-------------|
| `analytics_storage` | **Statistics/Analytics** | 热力图、录屏、点击追踪、滚动深度 | 进入 **无 Cookie 模式**（Cookie-less），仅收集页面级聚合数据，单页会话断裂 |
| `ad_storage` | **Marketing/Targeting** | 与 Microsoft Ads 的归因、再营销 | 禁用广告相关功能 |

## 单次询问模式（极简）

**唯一问题**："用户选择哪个同意级别？"

选项：
1. **完全拒绝** (Necessary only) - 立即停止所有追踪
2. **仅允许分析** (Statistics/Analytics) - 无 Cookie 模式，可追踪但无法跨页关联用户
3. **全部同意** (All) - 完整追踪，设置 `_clck` 和 `_clsk` cookies

## 三种同意级别的代码方案

### 方案 1：完全拒绝 (Denied)

**适用场景**：用户点击 "拒绝所有"、"仅必要 Cookie" 或关闭 Banner

**行为**：
- 立即停止数据收集
- 清除已有的 Clarity cookies
- Dashboard 中不再显示该用户后续数据

**代码**：

```javascript
// 在 Cookie Banner 的拒绝回调中调用
function handleRejectAll() {
  if (typeof window !== 'undefined' && window.clarity) {
    window.clarity("stop");  // 立即停止追踪
  }

  // 可选：清除已有 cookies（严格合规）
  document.cookie = "_clck=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
  document.cookie = "_clsk=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";

  localStorage.setItem('clarity_consent', 'denied');
}
```

### 方案 2：仅允许分析 (Analytics Only) ⭐ 推荐

**适用场景**：用户同意 "统计/分析" 但拒绝 "营销/广告"

**行为**：
- ✅ 继续收集热力图数据
- ✅ 继续 Session Recordings（但单页，跨页断裂）
- ❌ 不设置长期 cookies（`_clck`, `_clsk`）
- ❌ 无法跨页面关联同一用户
- ⚠️ 每个页面访问视为独立会话

**前置条件**：必须在 Clarity Dashboard 关闭 Cookies 设置！
- 路径：Clarity Project > Settings > Setup > Advanced Settings > **Cookies: OFF**

**代码**：

```javascript
// 在 Cookie Banner 的"仅分析"回调中调用
function handleAnalyticsOnly() {
  if (typeof window !== 'undefined' && window.clarity) {
    window.clarity("consentv2", {
      analytics_storage: "granted",  // 允许分析
      ad_storage: "denied"           // 拒绝广告
    });
  }

  localStorage.setItem('clarity_consent', 'analytics_only');
}
```

### 方案 3：全部同意 (Granted)

**适用场景**：用户点击 "接受所有" 或 "同意全部 Cookie"

**行为**：
- ✅ 完整追踪（热力图 + 录屏 + cookies）
- ✅ 跨页面会话保持（通过 cookies 识别同一用户）
- ✅ 支持与 Microsoft Ads 的归因集成

**代码**：

```javascript
// 在 Cookie Banner 的"全部同意"回调中调用
function handleAcceptAll() {
  if (typeof window !== 'undefined' && window.clarity) {
    window.clarity("consentv2", {
      analytics_storage: "granted",  // 允许分析
      ad_storage: "granted"          // 允许广告
    });
  }

  localStorage.setItem('clarity_consent', 'granted');
}
```

## 完整集成方案（按 Banner 类型）

### 类型 A：自建 Cookie Banner（React/Vue）

**架构设计**：

```tsx
// components/CookieBanner.tsx
import { useState, useEffect } from 'react';

export default function CookieBanner() {
  const [showBanner, setShowBanner] = useState(false);
  const [consentLevel, setConsentLevel] = useState<'denied' | 'analytics' | 'all' | null>(null);

  // 1. 页面加载时检查之前的同意状态
  useEffect(() => {
    const savedConsent = localStorage.getItem('clarity_consent');
    if (!savedConsent) {
      setShowBanner(true); // 首次访问，显示 Banner
    } else {
      // 恢复之前的同意状态
      applyConsent(savedConsent as any);
    }
  }, []);

  // 2. 应用同意状态到 Clarity
  const applyConsent = (level: 'denied' | 'analytics' | 'all') => {
    if (typeof window === 'undefined' || !window.clarity) return;

    switch (level) {
      case 'denied':
        window.clarity("stop");
        break;
      case 'analytics':
        window.clarity("consentv2", {
          analytics_storage: "granted",
          ad_storage: "denied"
        });
        break;
      case 'all':
        window.clarity("consentv2", {
          analytics_storage: "granted",
          ad_storage: "granted"
        });
        break;
    }
  };

  // 3. 处理按钮点击
  const handleChoice = (level: 'denied' | 'analytics' | 'all') => {
    setConsentLevel(level);
    localStorage.setItem('clarity_consent', level);
    applyConsent(level);
    setShowBanner(false);
  };

  if (!showBanner) return null;

  return (
    <div className="cookie-banner">
      <p>我们使用 Cookie 来改善您的体验...</p>
      <div className="buttons">
        <button onClick={() => handleChoice('denied')}>
          拒绝所有
        </button>
        <button onClick={() => handleChoice('analytics')}>
          仅允许统计
        </button>
        <button onClick={() => handleChoice('all')}>
          接受所有
        </button>
      </div>
    </div>
  );
}
```

### 类型 B：集成 Cookiebot（第三方 CMP）

```javascript
// 监听 Cookiebot 的同意事件
window.addEventListener('CookiebotOnAccept', function () {
  const consent = Cookiebot.consent;

  if (typeof window !== 'undefined' && window.clarity) {
    // Cookiebot 的 statistics 对应 Clarity 的 analytics_storage
    window.clarity("consentv2", {
      analytics_storage: consent.statistics ? "granted" : "denied",
      ad_storage: consent.marketing ? "granted" : "denied"
    });
  }
});

// 用户后续修改同意设置时
window.addEventListener('CookiebotOnDecline', function () {
  if (window.clarity) window.clarity("stop");
});
```

### 类型 C：集成 OneTrust / Osano

```javascript
// OneTrust 示例
function handleOneTrustConsent() {
  // OneTrust 通常会把同意状态放在 dataLayer 或特定全局变量
  const analyticsConsent = OnetrustActiveGroups.includes('C0002'); // 分析组 ID
  const marketingConsent = OnetrustActiveGroups.includes('C0004'); // 营销组 ID

  if (window.clarity) {
    window.clarity("consentv2", {
      analytics_storage: analyticsConsent ? "granted" : "denied",
      ad_storage: marketingConsent ? "granted" : "denied"
    });
  }
}

// 监听 OneTrust 的同意变更
window.addEventListener('consent.onetrust', handleOneTrustConsent);
```

## 前置检查清单（部署前必须完成）

在 Clarity Dashboard 中确认：

- [ ] **关闭自动 Cookie**：Project > Settings > Setup > Advanced Settings > **Cookies: OFF** ⚠️
- [ ] **启用 Consent Mode**：确保项目支持 Consent V2（2025年10月31日后强制）
- [ ] **地域设置**：如果用户来自 EEA/UK/瑞士，确保 Consent Signal 已发送 [^31^]

## 验证测试方法

### 1. 控制台验证

```javascript
// 查看当前同意状态
clarity('metadata', (data, upgrade, consent) => {
  console.log('Clarity Consent:', consent);
  // 应返回: { analytics_storage: "granted", ad_storage: "denied" }
}, false, true, true);
```

### 2. Network 面板验证

- 打开 DevTools > Network > 筛选 "clarity.ms"
- 触发同意变更（点击 Banner 按钮）
- 查看请求 payload 中应包含 `consent` 参数

### 3. Dashboard 验证

- 进入 Clarity Dashboard > Settings > Consent
- 查看 "Consent Mode Events" 统计
- 应看到不同同意级别的会话分布

## 故障排查

### 问题：用户同意后 Clarity 仍显示 "无数据"
**检查**：
1. 是否在 Dashboard 关闭了 Cookies 设置？（必须关闭才能支持部分同意）
2. `window.clarity` 是否在调用前已初始化？（确保 base code 已加载）
3. 是否等待了足够时间？（数据延迟 30 分钟）

### 问题：用户拒绝后仍在收集数据
**检查**：
1. 是否正确调用了 `window.clarity("stop")`？
2. 是否在页面加载早期就发送了 "granted" 信号？（避免默认允许）

### 问题：跨页面无法保持会话（Analytics Only 模式）
**解释**：这是预期行为！当 `analytics_storage: "denied"` 或用户仅选择 Analytics Only 时，Clarity 不设置 cookies，因此每页都是新会话。用户同意后，新页面会开始设置 cookies。

## 交互示例

**用户说**："我在开发 Cookie Banner，需要处理用户拒绝后 Clarity 的追踪问题"

**Skill 响应**：
> 我来帮你集成 Clarity 的 Consent Mode V2 隐私合规方案。
>
> **请确认你的使用场景**：
> 1. **完全拒绝** (用户点击"拒绝所有") → 立即停止追踪
> 2. **仅允许分析** (用户允许统计但拒绝营销) → 无 Cookie 追踪，跨页会话断裂
> 3. **全部同意** (用户接受所有) → 完整追踪
>
> 你使用哪种 Cookie Banner？
> - 自建 React/Vue 组件
> - Cookiebot
> - OneTrust / Osano
> - Quantcast
> - 其他

**用户选择**："自建 React，需要支持三种级别"

**Skill 生成**：
> 为你生成完整的 React Cookie Banner 组件，包含 Clarity Consent Mode V2 集成：
>
> **[生成上方 React 代码片段]**
>
> **重要前置设置**：
> 在 Clarity Dashboard > Settings > Setup > Advanced Settings 中，**关闭 Cookies 选项**（必须！）
>
> **部署后验证**：
> 1. 打开浏览器控制台
> 2. 运行：`clarity('metadata', (d, u, c) => console.log(c), false, true, true)`
> 3. 应看到 `{analytics_storage: "denied/granted", ad_storage: "denied/granted"}`
>
> **法律合规说明**：
> - EEA/UK/瑞士用户：必须在 2025年10月31日前部署 [^31^]
> - 中国用户：符合《个人信息保护法》最小必要原则
> - 美国用户：符合 CCPA "Do Not Sell" 要求
