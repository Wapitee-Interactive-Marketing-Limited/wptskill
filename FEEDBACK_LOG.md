<!-- ai-directive: skill-feedback-log -->
# Wapitee Skill 实战反馈记录

> **AI 读取规则**：每次执行完 skill 任务后，AI **必须主动询问用户** "是否需要将本次遇到的问题或改进建议记录到反馈日志？"
> 只有在用户**明确同意**后，才能向本文件追加内容。AI **不得**未经用户确认擅自写入。
> 同时，在每次回答与 skill 相关的问题前，AI **应优先读取本文件**，了解团队已知的坑和最新修正。

---

## 记录格式模板

```markdown
## YYYY-MM-DD: [简短标题]

- **关联 Skill**: `skill-name`
- **问题描述**: [具体描述，越具体越好]
- **触发场景**: [用户在什么情况下遇到的]
- **影响范围**: [单个项目 / 所有 Next.js 项目 /  etc.]
- **修复方案**: [如何修复的，或计划如何修复]
- **状态**: `已修复` / `待修复` / `观察中`
- **记录人**: [谁同意记录的]
```

---

## 已记录反馈

<!-- 新记录写在这下面 -->

## 2026-05-16: GA4 skill 缺失 User-Provided Data / Enhanced Conversions 指南

- **关联 Skill**: `google-analytics`
- **问题描述**:
  1. GA4 skill 的 14 个参考文档中完全没有提到 `user_data` 对象，只讲了 `user_id`（CRM 内部 ID）。用户容易混淆这两个概念。
  2. 没有覆盖 Google Enhanced Conversions 的实现：缺少 `sha256_email_address`、`sha256_phone_number` 等字段说明。
  3. 没有提到哈希前的标准化流程，尤其是 Gmail/Googlemail 的特殊规则（去掉 `@` 前的点号）。
  4. 没有说明 Google Ads Enhanced Conversions 的配置和验证方法。
- **触发场景**: 用户需要在 GA4 中传递哈希后的用户邮箱以实现 Enhanced Conversions，但 skill 中没有相关指南。
- **影响范围**: 所有使用 GA4 skill 且需要 Google Ads 转化增强的项目
- **修复方案**:
  1. 新建 `references/user-provided-data.md`，完整覆盖 `user_data` vs `user_id` 概念澄清、`user_data` 对象结构、预哈希/自动哈希模式、SHA-256 规范化流程（含 Gmail 去点规则）、Enhanced Conversions 配置、各框架实现示例、隐私合规、Google vs Meta 哈希对比表。
  2. 更新 `SKILL.md` 决策树，新增 `user-provided-data.md` 入口和 Enhanced Conversions 工作流。
  3. 更新 `references/user-tracking.md`，在开头添加概念澄清表格区分 `user_id` 和 `user_data`。
  4. 更新 `references/gtag.md`，在 `gtag('set')` 章节添加 `user_data` 示例。
  5. 更新 `references/privacy.md`，添加 PII 哈希最佳实践和邮箱规范化代码。
  6. 更新 `references/measurement-protocol.md`，添加 server-side `user_data` 传递示例。
- **状态**: `已修复`
- **记录人**: Jacob

## 2026-05-16: Meta Pixel skill 邮箱规范化不够完善

- **关联 Skill**: `meta-pixel-tracking`
- **问题描述**:
  1. Meta Pixel skill 的邮箱哈希只做了 `trim().toLowerCase()`，缺少对 `mailto:` 前缀和 `+` 别名（如 `user+tag@example.com`）的处理。
  2. 如果浏览器端和 CAPI 服务器端的规范化不一致，会导致哈希不匹配，降低 Event Match Quality (EMQ)。
- **触发场景**: 用户邮箱包含 `+` 别名（常见于 Gmail 用户用 `+` 做标签分类），或从某些系统获取的邮箱带有 `mailto:` 前缀。
- **影响范围**: 所有使用 meta-pixel-tracking skill 的落地页项目
- **修复方案**:
  1. 新增 `normalizeEmail()` 函数，在原有 trim + lowercase 基础上增加：去除 `mailto:` 前缀、去除 `+` 别名（`user+tag@example.com` → `user@example.com`）。
  2. 更新 skill 中的 Plain HTML 和 React/Next.js 代码示例，使用新的 `normalizeEmail()` 函数。
  3. 更新数据规范化规则表格、Hard Rules、Post-Deployment Checklist，明确规范化步骤。
- **状态**: `已修复`
- **记录人**: Jacob

## 2026-04-16: Meta Pixel skill 误判 Subscribe 按钮为 Lead 触发点，且缺少邮箱哈希

- **关联 Skill**: `meta-pixel-tracking`
- **问题描述**:
  1. `meta-pixel-tracking` skill 在检测 Lead 触发点时，会把文本为 "Subscribe" 的按钮直接识别为 Lead 转化点，但现实中很多 Subscribe 按钮只是打开弹窗/显示隐藏表单，并非真正提交用户邮箱。
  2. skill 没有要求将用户邮箱通过 SHA-256 哈希后传给 Meta 的 `em` 参数，导致 Lead 事件的 Advanced Matching 和 Event Match Quality 不足。
- **触发场景**: 用户页面有一个 "Subscribe" 按钮，点击后弹出邮箱输入表单，用户在表单内填写并提交邮箱。skill 容易把 Lead 事件错误地挂在按钮上而非表单提交上。
- **影响范围**: 所有使用该 skill 的落地页项目（尤其是含 modal/popup 表单的项目）
- **修复方案**:
  1. 在 skill 的 "Detect Lead Conversion Action" 规则中增加**关键判断**：如果按钮只是打开 popup/modal/hidden form（如 `setShowForm(true)`、`data-toggle="modal"`），**禁止**在此处挂 Lead，必须继续搜索内部的真实表单并挂在 `onSubmit` 上。
  2. 新增 "Advanced Matching & Email Hashing" 章节，提供客户端 `hashEmail()` 实现（基于 `crypto.subtle.digest('SHA-256')`），并要求 Lead 事件必须包含规范化（trim + lowercase）后的 SHA-256 邮箱哈希 `em`。
  3. 同步更新 Execution Flow、Hard Rules、Post-Deployment Checklist 和代码示例（HTML / React / Next.js）。
- **状态**: `已修复`
- **记录人**: Jacob

## 2026-04-16: CTA Lead 事件被死逻辑拦截，且 SurveyModal 缺少 Lead 与 Advanced Matching

- **关联 Skill**: `meta-pixel-tracking`
- **问题描述**:
  1. `CTA.tsx` 表单的 `handleSubmit` 检查了 `email.trim()`，但表单根本没有 email input，导致提交被拦截，`fbq('track', 'Lead')` 永远无法执行。
  2. 真正的用户转化发生在 `SurveyModal.tsx` 提交成功后，但此处完全没有调用 `fbq('track', 'Lead')`。
  3. 没有通过 Advanced Matching 把用户邮箱传给 Meta，导致 Event Match Quality 较低。
- **触发场景**: 用户点击 CTA 的 Subscribe → 打开问卷弹窗 → 填写问卷并提交邮箱。
- **影响范围**: 单个项目 (spirolandingpage)
- **修复方案**:
  1. 清理 `CTA.tsx` 的无效 email state 与拦截逻辑，改为纯打开弹窗。
  2. 在 `SurveyModal.tsx` API 提交成功后触发 `fbq('track', 'Lead')`。
  3. 使用 `crypto.subtle.digest('SHA-256', ...)` 将邮箱小写归一化后哈希，通过事件第四个参数 `{ em: hashedEmail }` 传给 Meta Advanced Matching。
  4. 明确跳过 Cookie Consent，确保数据始终传输给 Facebook（用户知情并承担风险）。
- **状态**: `已修复`
- **记录人**: Jacob

