---
name: wapitee-survey-webhook-setup
description: >
  Wapitee Survey Webhook 推送配置助手。帮助开发/运营将网站/落地页上的
  邮箱收集表单通过 Webhook POST 推送到 Wapitee Survey 系统。
  具备中断式提问能力：引导用户从 wapitee.io/admin 获取 Webhook URL 和 Secret，
  然后生成对应技术栈（Next.js / React / Vue / HTML / Node.js）的推送代码。
  严格规范 answers 字段格式为 q_1 / q_2 / q_3，支持成功/失败回调入口。
triggers:
  - "wapitee survey webhook"
  - "survey 推送"
  - "webhook 接收"
  - "留邮箱推送"
  - "wapitee survey"
  - "survey webhook"
version: 1.0.0
---

# Wapitee Survey Webhook 推送配置助手

## 触发条件

当用户提到以下关键词时激活：
- "wapitee survey webhook"
- "survey 推送"
- "webhook 接收"
- "留邮箱推送"
- "wapitee survey"
- "survey webhook"

## 核心工作流（含中断式交互）

### 阶段 1：信息收集（中断提问模式）

**以下信息缺失任何一项都必须中断并询问用户：**

1. **Wapitee Survey 配置信息**（最高优先级）
   - [ ] `WEBHOOK_URL`: 从 wapitee.io/admin 的 Survey Setting 中复制的 Webhook 接收 URL
   - [ ] `WEBHOOK_SECRET`: 同一页面创建的验证密钥（X-Webhook-Secret）

2. **项目技术栈**
   - [ ] `FRAMEWORK`: 前端/后端框架（nextjs / react / vue / html / nodejs）

3. **表单字段映射**
   - [ ] `EMAIL_FIELD_NAME`: 前端表单中邮箱字段的变量名（例如 `email`、`userEmail`、`formData.email`）
   - [ ] `QUESTION_COUNT`: 问卷问题数量（用于生成 q_1 到 q_N 的映射）
   - [ ] 每个问题对应的前端字段名（如 `q1Answer`、`question1`、`formData.answers[0]`）

### 阶段 2：中断提问逻辑（关键）

**规则：如果以下任一条件满足，立即停止生成配置并询问用户：**

```markdown
IF 用户未提供 WEBHOOK_URL:
  → 中断并提问：
     "请按以下步骤获取 Webhook URL：
      1. 登录 wapitee.io/admin
      2. 创建或选择你要接收数据的 Survey
      3. 进入 Setting > Webhook 接收
      4. 打开 Webhook 接收开关
      5. 复制 Webhook URL 并提供给我："

IF 用户未提供 WEBHOOK_SECRET:
  → 中断并提问：
     "请在同一个 Survey 的 Webhook Setting 页面创建验证密钥（Secret），
      并将该 Secret 提供给我（用于设置 X-Webhook-Secret 请求头）："

IF 用户未提供 FRAMEWORK:
  → 中断并提问："你的项目使用什么技术栈？（nextjs / react / vue / html / nodejs）"

IF 用户未说明表单字段映射:
  → 中断并提问：
     "请告诉我前端表单中各字段的变量名，我会帮你映射到标准格式：
      - 邮箱字段叫什么？（例如：email、formData.email）
      - 问题1的答案字段叫什么？
      - 问题2的答案字段叫什么？
      - ..."
```

### 阶段 3：根据收集的信息生成配置

#### 通用规范（所有技术栈必须遵循）

**请求头 Headers：**
```json
{
  "Content-Type": "application/json",
  "X-Webhook-Secret": "{{WEBHOOK_SECRET}}"
}
```

**请求体 Body：**
```json
{
  "email": "user@example.com",
  "answers": {
    "q_1": "问题1答案",
    "q_2": "问题2答案",
    "q_3": ["多选A", "多选B"]
  },
  "source": "来源渠道",
  "metadata": { "自定义字段": "值" }
}
```

**强制规则：**
- `email` 为必填字段
- `answers` 中的键必须严格使用 `q_1`、`q_2`、`q_3` 格式
- 多选题答案用 `string[]` 数组传递
- 单选题/文本题用 `string` 传递
- `source` 和 `metadata` 为可选字段

---

#### 1. Next.js (App Router) — Server Action 推送

**适用场景**：在 Next.js 14+ App Router 中通过 Server Action 发送 Webhook，Secret 不暴露给前端。

```typescript
// app/actions/survey.ts
'use server';

const WEBHOOK_URL = process.env.WAPITEE_SURVEY_WEBHOOK_URL;
const WEBHOOK_SECRET = process.env.WAPITEE_SURVEY_WEBHOOK_SECRET;

export async function submitSurvey(data: {
  email: string;
  answers: Record<string, string | string[]>;
  source?: string;
  metadata?: Record<string, unknown>;
}) {
  if (!WEBHOOK_URL || !WEBHOOK_SECRET) {
    throw new Error('Webhook URL or Secret is not configured');
  }

  const payload = {
    email: data.email,
    answers: data.answers,
    source: data.source ?? 'website',
    metadata: data.metadata ?? {},
  };

  const res = await fetch(WEBHOOK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Webhook-Secret': WEBHOOK_SECRET,
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => 'Unknown error');
    throw new Error(`Webhook failed: ${res.status} ${errorText}`);
  }

  return { success: true };
}
```

```typescript
// app/components/SurveySubmitButton.tsx
'use client';
import { submitSurvey } from '../actions/survey';

export default function SurveySubmitButton({ formData }: { formData: any }) {
  const handleSubmit = async () => {
    try {
      // 字段映射：将前端表单字段映射为 q_1, q_2...
      const answers = {
        q_1: formData.{{Q1_FIELD}},
        q_2: formData.{{Q2_FIELD}},
        q_3: formData.{{Q3_FIELD}}, // 多选时确保为 string[]
      };

      await submitSurvey({
        email: formData.{{EMAIL_FIELD}},
        answers,
        source: 'landing_page',
      });

      // TODO: 项目层面在这里处理成功回调（如 toast、跳转）
      console.log('提交成功');
    } catch (err) {
      // TODO: 项目层面在这里处理失败回调（如重试、报错提示）
      console.error('提交失败', err);
    }
  };

  return <button onClick={handleSubmit}>提交</button>;
}
```

```
// .env.local
WAPITEE_SURVEY_WEBHOOK_URL={{WEBHOOK_URL}}
WAPITEE_SURVEY_WEBHOOK_SECRET={{WEBHOOK_SECRET}}
```

---

#### 2. React (客户端直接推送)

**适用场景**：纯 React SPA，从浏览器直接发送 Webhook。

```typescript
// lib/surveyWebhook.ts
const WEBHOOK_URL = '{{WEBHOOK_URL}}';
const WEBHOOK_SECRET = '{{WEBHOOK_SECRET}}';

export async function submitSurvey(data: {
  email: string;
  answers: Record<string, string | string[]>;
  source?: string;
  metadata?: Record<string, unknown>;
}) {
  const payload = {
    email: data.email,
    answers: data.answers,
    source: data.source ?? 'website',
    metadata: data.metadata ?? {},
  };

  const res = await fetch(WEBHOOK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Webhook-Secret': WEBHOOK_SECRET,
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => 'Unknown error');
    throw new Error(`Webhook failed: ${res.status} ${errorText}`);
  }

  return { success: true };
}
```

```typescript
// 使用示例
import { submitSurvey } from './lib/surveyWebhook';

async function handleFormSubmit(formData: any) {
  try {
    await submitSurvey({
      email: formData.{{EMAIL_FIELD}},
      answers: {
        q_1: formData.{{Q1_FIELD}},
        q_2: formData.{{Q2_FIELD}},
      },
      source: 'react_app',
    });
    // TODO: 成功回调
  } catch (err) {
    // TODO: 失败回调
  }
}
```

---

#### 3. Vue 3 (客户端直接推送)

```typescript
// composables/useSurveyWebhook.ts
const WEBHOOK_URL = '{{WEBHOOK_URL}}';
const WEBHOOK_SECRET = '{{WEBHOOK_SECRET}}';

export async function submitSurvey(payload: {
  email: string;
  answers: Record<string, string | string[]>;
  source?: string;
  metadata?: Record<string, unknown>;
}) {
  const res = await fetch(WEBHOOK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Webhook-Secret': WEBHOOK_SECRET,
    },
    body: JSON.stringify({
      ...payload,
      source: payload.source ?? 'website',
      metadata: payload.metadata ?? {},
    }),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => 'Unknown error');
    throw new Error(`Webhook failed: ${res.status} ${text}`);
  }

  return { success: true };
}
```

```vue
<script setup>
import { submitSurvey } from '@/composables/useSurveyWebhook';

async function handleSubmit(formData) {
  try {
    await submitSurvey({
      email: formData.{{EMAIL_FIELD}},
      answers: {
        q_1: formData.{{Q1_FIELD}},
        q_2: formData.{{Q2_FIELD}},
      },
      source: 'vue_app',
    });
    // TODO: 成功回调
  } catch (err) {
    // TODO: 失败回调
  }
}
</script>
```

---

#### 4. 原生 HTML + JavaScript

```html
<script>
const WEBHOOK_URL = '{{WEBHOOK_URL}}';
const WEBHOOK_SECRET = '{{WEBHOOK_SECRET}}';

async function submitSurvey(formData) {
  const payload = {
    email: formData.{{EMAIL_FIELD}},
    answers: {
      q_1: formData.{{Q1_FIELD}},
      q_2: formData.{{Q2_FIELD}},
    },
    source: 'html_page',
  };

  try {
    const res = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Secret': WEBHOOK_SECRET,
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      throw new Error(`Webhook failed: ${res.status}`);
    }

    // TODO: 成功回调
    console.log('提交成功');
  } catch (err) {
    // TODO: 失败回调
    console.error('提交失败', err);
  }
}
</script>
```

---

#### 5. Node.js / Express 后端转发

```javascript
// routes/survey.js
const express = require('express');
const router = express.Router();

const WEBHOOK_URL = process.env.WAPITEE_SURVEY_WEBHOOK_URL;
const WEBHOOK_SECRET = process.env.WAPITEE_SURVEY_WEBHOOK_SECRET;

router.post('/submit-survey', async (req, res) => {
  try {
    const { email, answers, source, metadata } = req.body;

    const payload = {
      email,
      answers,
      source: source || 'nodejs_app',
      metadata: metadata || {},
    };

    const webhookRes = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Secret': WEBHOOK_SECRET,
      },
      body: JSON.stringify(payload),
    });

    if (!webhookRes.ok) {
      const text = await webhookRes.text().catch(() => 'Unknown error');
      return res.status(502).json({ error: `Upstream webhook failed: ${webhookRes.status} ${text}` });
    }

    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

```
# .env
WAPITEE_SURVEY_WEBHOOK_URL={{WEBHOOK_URL}}
WAPITEE_SURVEY_WEBHOOK_SECRET={{WEBHOOK_SECRET}}
```

---

## 字段映射示例

**假设前端表单字段名为：**
- 邮箱：`userEmail`
- 问题1：`companyName`
- 问题2：`budgetRange`
- 问题3：`interests`（多选，数组）

**映射后的标准格式：**
```json
{
  "email": "user@example.com",
  "answers": {
    "q_1": "companyName 的值",
    "q_2": "budgetRange 的值",
    "q_3": ["interests 数组的值"]
  }
}
```

**重要：** 无论前端字段名是什么，`answers` 的键必须严格为 `q_1`, `q_2`, `q_3`... Wapitee Survey 后端会根据这些 key 做问题名称的 mapping。

---

## 交互示例

**用户说**："我要把落地页的 survey 数据推到 wapitee survey"

**Skill 响应**：
> 我来帮你配置 Wapitee Survey 的 Webhook 推送。
>
> **请先完成以下步骤并提供信息：**
> 1. 登录 [wapitee.io/admin](https://wapitee.io/admin)
> 2. 创建或选择你要接收数据的 Survey
> 3. 进入 **Setting > Webhook 接收**
> 4. 打开 **Webhook 接收** 开关
> 5. 复制 **Webhook URL** 和 **Secret** 提供给我
> 6. 告诉我你的技术栈（nextjs / react / vue / html / nodejs）
> 7. 告诉我前端表单中邮箱字段和各问题字段的名称
>
> 请按顺序提供以上信息，我会为你生成完整的推送代码。

---

## 故障排查

### 常见问题 1："Unauthorized" 或 "Invalid Secret"
**原因**: `X-Webhook-Secret` 请求头缺失或与 Survey 后台配置不一致
**解决**: 重新复制 Secret，检查环境变量或代码中的拼写

### 常见问题 2："email is required"
**原因**: 请求体中缺少 `email` 字段
**解决**: 确认前端表单正确采集了邮箱，并传入了 `email` 字段

### 常见问题 3：answers 里的问题没有对应上
**原因**: 使用了前端原始字段名，而不是 `q_1`, `q_2` 格式
**解决**: 严格按照本 skill 的规范，将前端字段值映射到 `q_1`, `q_2`, `q_3` 键名

### 常见问题 4：多选题只收到一个值
**原因**: 多选答案没有以 `string[]` 数组格式发送
**解决**: 确保多选字段在传给 `answers.q_N` 时是一个数组

### Post-Deployment Checklist:

- [ ] **Webhook 配置确认**：Wapitee Survey 后台已开启 Webhook 接收，URL 和 Secret 正确
- [ ] **环境变量设置**：`WAPITEE_SURVEY_WEBHOOK_URL` 和 `WAPITEE_SURVEY_WEBHOOK_SECRET` 已配置（Next.js/Node.js 场景）
- [ ] **字段映射检查**：`answers` 中的键严格为 `q_1`, `q_2`, `q_3`... 而非前端原始字段名
- [ ] **必填字段校验**：`email` 字段在请求体中存在且格式正确
- [ ] **多选格式确认**：多选题答案以 `string[]` 传递，单选/文本以 `string` 传递
- [ ] **成功回调验证**：提交成功后触发了项目层面的成功回调逻辑
- [ ] **失败回调验证**：断网或 Secret 错误时触发了项目层面的失败回调逻辑
- [ ] **端到端测试**：从真实表单提交一次，在 Wapitee Survey 后台确认数据已接收
