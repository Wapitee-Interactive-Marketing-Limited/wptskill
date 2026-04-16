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

