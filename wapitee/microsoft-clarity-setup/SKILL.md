---
name: microsoft-clarity-setup
description: >
  Microsoft Clarity 全功能集成助手。包含：1) 极简基础埋点（单次询问 Project ID）;
  2) 智能自定义事件生成器（自然语言描述交互场景，自动生成代码并指导集成位置）。
  支持多种前端框架（HTML/Next.js/React/Vue/Nuxt），包含生产环境检测和隐私合规设置。
triggers:
  - "microsoft clarity"
  - "clarity 埋点"
  - "clarity 代码"
  - "网站热力图"
  - "自定义事件"
  - "追踪用户行为"
version: 1.1.0
---

# Microsoft Clarity 完整集成助手

## 触发条件

当用户提到以下关键词时激活：
- "microsoft clarity", "clarity 埋点", "clarity 代码", "网站热力图"
- "自定义事件", "追踪用户行为", "埋点事件", "event tracking"
- "用户点击", "鼠标悬停", "滚动追踪", "表单提交"

## Skill 场景识别指南

当用户请求 Clarity 集成时，AI 应根据页面特征自动判断场景：

| 场景 | 页面特征 | 推荐功能 | 典型标签 |
|------|---------|---------|----------|
| **前测项目** | 只有订阅表单、newsletter、无价格元素 | `identify` + Custom Tags | `customer_type: subscriber` |
| **电商项目** | 有价格、购物车、Add to Cart、结账 | `identify` + Custom Tags + 事件追踪 | `cart_value: over_100`, `funnel_stage: added_to_cart` |
| **混合场景** | 既有订阅又有购买 | `identify` + Custom Tags + 用户意图标签 | `user_intent: subscriber/buyer` |

**判断逻辑**：
1. 检查页面是否有价格显示、购物车图标、Add to Cart 按钮 → 电商场景
2. 检查是否有订阅表单、email input、无价格元素 → 前测场景
3. 两者都有 → 混合场景，使用 `user_intent` 标签区分

---

## 功能模块一：基础埋点（单次提问模式）

### 快速开始 - 仅需 Project ID

**单次询问**："请输入你的 Microsoft Clarity Project ID（tracking code）："

生成全站基础追踪代码（自动追踪所有页面、点击、滚动、热力图）。

#### 1. 原生 HTML
```html
<!-- 放到 <head> 内，仅需一次 -->
<script type="text/javascript">
    (function(c,l,a,r,i,t,y){
        c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
    })(window, document, "clarity", "script", "{{CLARITY_PROJECT_ID}}");
</script>
```

#### 2. Next.js App Router
```tsx
// app/components/Clarity.tsx
'use client';
import Script from 'next/script';

const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID;

export default function MicrosoftClarity() {
  if (process.env.NODE_ENV !== 'production' || !CLARITY_PROJECT_ID) return null;

  return (
    <Script
      id="microsoft-clarity"
      strategy="afterInteractive"
      dangerouslySetInnerHTML={{
        __html: `(function(c,l,a,r,i,t,y){c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);})(window, document, "clarity", "script", "${CLARITY_PROJECT_ID}");`,
      }}
    />
  );
}
```

#### 3. Vue 3
```typescript
// composables/useClarity.ts
import { onMounted } from 'vue';

export function useMicrosoftClarity() {
  onMounted(() => {
    const id = import.meta.env.VITE_CLARITY_PROJECT_ID;
    if (process.env.NODE_ENV !== 'production' || !id) return;

    const script = document.createElement('script');
    script.innerHTML = `(function(c,l,a,r,i,t,y){c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);})(window, document, "clarity", "script", "${id}");`;
    document.head.appendChild(script);
  });
}
```

## 功能模块二：用户识别与 Custom Tags（分组标签）

### 2A: 用户识别 — `clarity("identify")`

Clarity 的 `identify` 方法允许你将用户与一个自定义 ID 关联，便于在录屏中搜索特定用户、追踪跨设备旅程。

**关键特性：自动哈希**

与 Google/Meta 不同，**Clarity 在浏览器端自动哈希 PII**。你可以直接传入原始 email，Clarity 的 JavaScript 会在传输前自动加密。Microsoft 永远不会看到原始 PII。

| 平台 | 哈希责任方 | 说明 |
|------|-----------|------|
| **Clarity** | Clarity SDK（自动） | 直接传 raw email，SDK 自动 SHA-256 |
| Google (GA4) | 开发者（手动） | 必须自己哈希 `sha256_email_address` |
| Meta (Pixel) | 混合 | `fbevents.js` 自动哈希，但 CAPI 需手动哈希 |

**基本用法：**

```javascript
// 用户登录后、提交表单后、购买后触发
window.clarity("identify", "alex@gmail.com");

// 或用内部用户 ID（Shopify Customer ID）
window.clarity("identify", "shopify_customer_98723");
```

**何时触发：**

| 场景 | 触发时机 | 推荐 ID |
|------|---------|---------|
| 用户登录 | 登录成功后 | 内部用户 ID 或 email |
| 提交订阅表单 | 表单提交成功后 | email |
| 完成购买 | 订单确认页 | Shopify Customer ID 或 email |
| 注册用户 | 注册成功后 | 用户 ID |

**各框架实现：**

**React / Next.js：**
```tsx
// hooks/useClarityIdentify.ts
export function useClarityIdentify(userId: string | undefined) {
  useEffect(() => {
    if (userId && typeof window !== 'undefined' && window.clarity) {
      window.clarity("identify", userId);
    }
  }, [userId]);
}

// 在登录/用户状态组件中使用
function UserProfile({ user }) {
  useClarityIdentify(user?.email); // Clarity 自动哈希
  return <div>...</div>;
}
```

**原生 JavaScript：**
```javascript
// 在表单提交成功后调用
document.getElementById('subscribe-form').addEventListener('submit', function(e) {
  const email = document.getElementById('email').value;
  if (window.clarity && email) {
    window.clarity("identify", email); // 自动哈希，无需处理
  }
});
```

---

### 2B: Custom Tags — 用户分组与行为标记

Custom Tags 允许你为会话打上业务标签，随后在 Clarity Dashboard 中按标签筛选热力图和录屏。

**核心 API：**

```javascript
window.clarity("set", "tag_name", "tag_value");
```

**AI 场景自动识别：**

Skill 应根据页面特征自动判断场景，推荐对应的标签策略：

#### 场景 A：前测项目（Pre-Test / Lead Generation）

**页面特征**：只有订阅表单、 newsletter signup、无价格/购物车元素

**推荐标签：**

```javascript
// 用户提交订阅表单后
window.clarity("set", "customer_type", "subscriber");

// 如果用户来自特定广告渠道
window.clarity("set", "traffic_source", "facebook_ad");

// 用户完成问卷
window.clarity("set", "engagement_level", "form_completed");
```

**Dashboard 筛选用途：**
- 只看 "subscriber" 用户的热力图 → 优化订阅转化
- 对比 "form_completed" vs "bounced" 的行为差异

#### 场景 B：电商项目（Ecommerce）

**页面特征**：有价格显示、Add to Cart 按钮、购物车、结账流程

**推荐标签：**

```javascript
// 根据购物车金额分组
window.clarity("set", "cart_value", "over_100");   // 或 "under_100", "empty"

// 用户类型
window.clarity("set", "customer_type", "new_visitor");  // 或 "returning", "purchaser"

// 购买阶段
window.clarity("set", "funnel_stage", "added_to_cart"); // 或 "checkout_started", "purchased"
```

**Dashboard 筛选用途：**
- 对比 "cart_value: over_100" vs "cart_value: empty" 的热力图差异
- 看 "funnel_stage: purchased" 用户的完整录屏，找出转化路径

#### 场景 C：混合场景（落地页 + 电商）

**页面特征**：既有订阅入口，又有产品购买

**推荐标签：**

```javascript
// 先标记用户主要意图
window.clarity("set", "user_intent", "subscriber");  // 或 "buyer", "browser"

// 再标记价值层级
window.clarity("set", "value_tier", "high_value");   // 基于行为或金额判断
```

---

### 2C: 完整集成示例（前测项目）

**场景**：用户填写 newsletter 订阅表单，需要标记为 subscriber 并识别用户

```tsx
// components/SubscribeForm.tsx
'use client';
import { useState } from 'react';

export default function SubscribeForm() {
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // 1. 你的表单提交逻辑（API call）
    // await api.subscribe(email);

    // 2. 标记用户为 subscriber
    if (typeof window !== 'undefined' && window.clarity) {
      window.clarity("set", "customer_type", "subscriber");
      window.clarity("identify", email); // Clarity 自动哈希
    }

    setSubmitted(true);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Enter your email"
        required
      />
      <button type="submit">Subscribe</button>
      {submitted && <p>Thank you for subscribing!</p>}
    </form>
  );
}
```

---

### 2D: 完整集成示例（电商项目）

**场景**：用户将商品加入购物车，需要根据购物车金额打标签

```tsx
// components/AddToCartButton.tsx
'use client';

export default function AddToCartButton({ product, cartTotal }: { product: any; cartTotal: number }) {
  const handleAddToCart = () => {
    // 1. 你的加购逻辑
    // await api.addToCart(product.id);

    // 2. 根据购物车金额打标签
    if (typeof window !== 'undefined' && window.clarity) {
      const newTotal = cartTotal + product.price;
      const valueTier = newTotal > 100 ? 'over_100' : newTotal > 0 ? 'under_100' : 'empty';

      window.clarity("set", "cart_value", valueTier);
      window.clarity("set", "funnel_stage", "added_to_cart");
    }
  };

  return <button onClick={handleAddToCart}>Add to Cart</button>;
}
```

---

## 功能模块三：智能自定义事件生成器（核心功能）

当用户说类似以下的话时激活：
- "当用户 hover 这里时触发..."
- "点击按钮时记录..."
- "滚动到这个区域时发送..."
- "用户停留超过 X 秒时..."

### 交互流程

**阶段 1：理解用户意图**

分析用户描述，提取以下要素：
- **触发方式**: hover / click / scroll-into-view / time-on-page / custom
- **目标元素**: CSS 选择器 或 组件引用
- **事件名称**: clarity("event", "EVENT_NAME") 中的 EVENT_NAME
- **条件限制**: 是否只触发一次 / 是否延迟 / 是否可见性检测

**阶段 2：中断式提问（如果信息不完整）**

如果用户描述不够具体，询问：
```markdown
- "你提到的 '这里' 具体是指哪个元素？请提供 CSS 类名或 ID（如 .pricing-card 或 #signup-btn）"
- "这个事件应该只触发一次，还是每次交互都触发？"
- "是否需要延迟触发？比如用户 hover 超过 2 秒才算真正感兴趣？"
```

**阶段 3：生成代码 + 集成指导**

根据技术栈提供完整的代码和具体的插入位置。

---

### 自定义事件生成案例库

#### 案例 1：Hover 追踪（用户请求的场景）

**用户描述**: "当用户鼠标 hover 价格卡片时触发 engage_interest"

**提取要素**:
- 触发: mouseenter/hover
- 目标: .pricing-card
- 事件名: engage_interest
- 限制: 延迟 2 秒触发（避免误触）

**生成的代码方案**：

**React 方案**:
```tsx
// components/PricingCard.tsx 或直接在对应组件中
import { useRef, useEffect } from 'react';

export default function PricingCard() {
  const cardRef = useRef<HTMLDivElement>(null);
  const hasTriggered = useRef(false);
  const timerRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    const card = cardRef.current;
    if (!card || typeof window === 'undefined' || !window.clarity) return;

    const handleMouseEnter = () => {
      // 延迟 2 秒，确认是真正有意的 hover
      timerRef.current = setTimeout(() => {
        if (!hasTriggered.current) {
          window.clarity("event", "engage_interest");
          hasTriggered.current = true; // 只触发一次
        }
      }, 2000);
    };

    const handleMouseLeave = () => {
      // 提前离开则取消计时
      if (timerRef.current) clearTimeout(timerRef.current);
    };

    card.addEventListener('mouseenter', handleMouseEnter);
    card.addEventListener('mouseleave', handleMouseLeave);

    return () => {
      card.removeEventListener('mouseenter', handleMouseEnter);
      card.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, []);

  return (
    <div ref={cardRef} className="pricing-card">
      {/* 你的卡片内容 */}
    </div>
  );
}
```

**Vue 3 方案**:
```vue
<template>
  <div ref="cardRef" class="pricing-card">
    <!-- 卡片内容 -->
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const cardRef = ref(null);
let hasTriggered = false;
let timer = null;

onMounted(() => {
  if (!cardRef.value || typeof window === 'undefined' || !window.clarity) return;

  const handleEnter = () => {
    timer = setTimeout(() => {
      if (!hasTriggered) {
        window.clarity("event", "engage_interest");
        hasTriggered = true;
      }
    }, 2000);
  };

  const handleLeave = () => {
    if (timer) clearTimeout(timer);
  };

  cardRef.value.addEventListener('mouseenter', handleEnter);
  cardRef.value.addEventListener('mouseleave', handleLeave);

  onUnmounted(() => {
    if (cardRef.value) {
      cardRef.value.removeEventListener('mouseenter', handleEnter);
      cardRef.value.removeEventListener('mouseleave', handleLeave);
    }
    if (timer) clearTimeout(timer);
  });
});
</script>
```

**原生 JavaScript 方案** (用于 HTML 或简单项目):
```javascript
// 放到 base code 后面，或 DOMContentLoaded 事件中
document.querySelectorAll('.pricing-card').forEach(card => {
  let hasTriggered = false;
  let timer;

  card.addEventListener('mouseenter', () => {
    timer = setTimeout(() => {
      if (!hasTriggered && window.clarity) {
        window.clarity("event", "engage_interest");
        hasTriggered = true; // 每个卡片只记录一次
      }
    }, 2000);
  });

  card.addEventListener('mouseleave', () => {
    clearTimeout(timer);
  });
});
```

---

#### 案例 2：点击追踪（精确追踪 CTA）

**用户描述**: "当用户点击'立即咨询'按钮时触发 contact_click"

**生成的代码**：

**React (事件委托模式 - 性能更好)**:
```tsx
// 在父组件或 _app.tsx 中
useEffect(() => {
  const handleClick = (e) => {
    const target = e.target.closest('[data-clarity-event="contact"]');
    if (target && window.clarity) {
      window.clarity("event", "contact_click");
    }
  };

  document.addEventListener('click', handleClick);
  return () => document.removeEventListener('click', handleClick);
}, []);

// 在 JSX 中标记按钮
<button data-clarity-event="contact">立即咨询</button>
```

**Vue 3 (指令封装 - 可复用)**:
```typescript
// directives/clarity.ts
export const vClarity = {
  mounted(el, binding) {
    el._clarityHandler = () => {
      if (window.clarity) window.clarity("event", binding.value);
    };
    el.addEventListener('click', el._clarityHandler);
  },
  unmounted(el) {
    el.removeEventListener('click', el._clarityHandler);
  }
};

// 使用
<button v-clarity="'contact_click'">立即咨询</button>
```

---

#### 案例 3：滚动进入视口追踪（阅读深度）

**用户描述**: "当用户滚动看到'客户评价'区域时触发 viewed_testimonials"

**生成的代码**：

**React + Intersection Observer**:
```tsx
import { useEffect, useRef } from 'react';

export default function Testimonials() {
  const sectionRef = useRef<HTMLElement>(null);
  const hasTriggered = useRef(false);

  useEffect(() => {
    if (!sectionRef.current || typeof window === 'undefined') return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting && !hasTriggered.current && window.clarity) {
            window.clarity("event", "viewed_testimonials");
            hasTriggered.current = true;
            observer.disconnect(); // 只触发一次
          }
        });
      },
      { threshold: 0.5 } // 50% 可见时触发
    );

    observer.observe(sectionRef.current);
    return () => observer.disconnect();
  }, []);

  return (
    <section ref={sectionRef} id="testimonials">
      {/* 客户评价内容 */}
    </section>
  );
}
```

---

#### 案例 4：表单填写深度（多步骤表单）

**用户描述**: "追踪用户是否填完了表单的第几步，分别触发 form_step_1, form_step_2, form_step_3"

**生成的代码**：

```typescript
// hooks/useFormTracking.ts (React)
export function useFormTracking(step: number) {
  useEffect(() => {
    if (window.clarity) {
      window.clarity("event", `form_step_${step}`);
    }
  }, [step]);
}

// 在组件中使用
const [currentStep, setCurrentStep] = useState(1);
useFormTracking(currentStep);
```

---

### 事件命名规范建议

向用户提供以下命名建议：

| 场景 | 推荐命名格式 | 示例 |
|------|-------------|------|
| 页面浏览深度 | page_depth_[百分比] | page_depth_50, page_depth_100 |
| 内容互动 | engage_[内容类型] | engage_video, engage_calculator |
| 转化相关 | conversion_[动作] | conversion_signup, conversion_purchase |
| 点击 CTA | click_[按钮名称] | click_pricing_cta, click_demo_request |
| 表单进度 | form_step_[编号] | form_step_1, form_step_completed |
| 用户留存 | return_[天数] | return_7d, return_30d |

**注意**：Clarity 事件名只能包含字母、数字和下划线，建议全部小写。

---

### Post-Deployment Checklist:

- [ ] **生产环境确认**：代码在生产环境执行（开发环境通常被过滤）
- [ ] **控制台验证**：运行 `window.clarity("event", "test_event")`，然后在 Dashboard > Smart Events 查看
- [ ] **Network 验证**：打开 DevTools > Network，筛选 "clarity.ms"，触发事件后确认 payload 包含 `e:你的事件名`
- [ ] **事件命名检查**：确认事件名只包含字母、数字、下划线，且大小写拼写正确
- [ ] **等待时间**：Clarity 数据通常有 30 分钟延迟，不要过早判断未生效
- [ ] **SPA 路由**：如果是 React/Vue SPA，确认 useEffect/onMounted 中正确重建了事件监听器
- [ ] **用户识别验证**：提交表单/登录后，在 Clarity Dashboard > Recordings 中搜索用户 ID，确认能定位到该用户的录屏
- [ ] **Custom Tags 验证**：在 Dashboard > Filters > Custom Tags 中查看标签是否正确显示，确认能按标签筛选录屏和热力图
- [ ] **场景标签一致性**：确认同一用户会话中的 Custom Tags 没有冲突（例如不会同时标记为 subscriber 和 purchaser）

---

### Frustration Metrics 快速参考

Clarity 内置的 Frustration Filters 帮你快速定位用户体验问题，无需观看随机录屏：

| 指标 | 说明 | 排查场景 |
|------|------|----------|
| **Rage Clicks** | 用户短时间内多次点击同一元素 | 按钮无响应、链接失效、加载过慢 |
| **Dead Clicks** | 用户点击了不可点击的元素 | 设计误导（看起来像按钮的文本/图片） |
| **JavaScript Errors** | 用户遇到 JS 报错 | 结账流程崩溃、表单验证失败、API 错误 |
| **Excessive Scrolling** | 用户反复上下滚动 | 找不到内容、页面布局混乱 |
| **Quick Backs** | 用户快速返回上一页 | 内容不符预期、加载失败 |

**使用方式**：Dashboard > Recordings > Filters > Frustration > 勾选对应指标

---

## 技术原理与限制

### 自动追踪 vs 自定义事件

| 特性 | Base Code（自动） | Custom Events（手动） |
|------|------------------|---------------------|
| 安装 | 一次即可 | 按需添加到特定元素 |
| 数据粒度 | 通用（点击、滚动） | 业务逻辑（"完成注册"） |
| 触发时机 | Clarity 决定 | 开发者完全控制 |
| 是否需要代码 | 不需要 | 需要编写事件监听 |
| 支持属性参数 | ❌ 不支持 | ❌ 目前仍不支持 |

### 重要限制 [参考官方文档]

1. **事件非追溯性**：今天创建的事件无法查看昨天的数据
2. **无参数传递**：只能记录 "发生了一次购买"，不能记录 "购买了 iPhone 15 Pro"
3. **延迟**：数据通常在 30 分钟内出现在 Dashboard
4. **采样**：高流量网站可能被采样（Clarity 每天最多记录 100K 会话）

---

## 完整交互示例

**用户**: "我想在用户鼠标悬停在价格卡片超过 2 秒时，触发一个 engage_interest 事件"

**Skill**:
> 理解！你要追踪的是 **Hover 意图**（延迟 2 秒，防误触），目标元素是 **价格卡片**，事件名 **engage_interest**。
>
> 请告诉我：
> 1. 价格卡片的 CSS 类名是什么？（例如 `.pricing-card` 或 `.price-section`）
> 2. 每个卡片只触发一次，还是允许重复触发？

**用户**: "类名是 .pricing-card，每个卡片只触发一次"

**Skill**:
> 收到！为你的 React 项目生成以下代码：
> 
> **[生成上方 React 代码片段]**
> 
> **集成步骤**：
> 1. 复制上面的 hook 到你的组件
> 2. 确保 PricingCard 组件有 `ref={cardRef}` 
> 3. 部署后，在 Clarity Dashboard > Smart Events > Custom Events 中查看 "engage_interest" 事件统计
>
> **验证方法**：部署后在控制台输入 `window.clarity("event", "test")`，然后查看 Network 面板是否有 clarity.ms 的请求发出。

---

## 故障排查

### 问题：自定义事件没出现在 Dashboard
**检查清单**：
- [ ] 代码在生产环境执行（开发环境被过滤）
- [ ] `window.clarity` 存在且是函数
- [ ] 事件名拼写正确（大小写敏感）
- [ ] 等待至少 30 分钟（Clarity 数据有延迟）

### 问题：事件触发太多次
**解决**: 添加 `hasTriggered` 标志（如示例代码所示），或使用 `once: true` 的 EventListener 选项。

### 问题：SPA 路由切换后事件失效
**解决**: 确保事件监听在组件 mount 时重新绑定，使用 React useEffect / Vue onMounted 清理和重建监听器。
