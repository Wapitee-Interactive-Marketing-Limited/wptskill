---
name: wapitee-watermark
description: "在任意 Web 项目的 <head> 中通过一行 <script> 引入 Wapitee 官方 console 彩蛋脚本，零配置注入品牌水印（ASCII Logo + 文案），覆盖 Next.js、React、Vue、Nuxt 与纯 HTML"
---

# Wapitee Watermark

## Overview

Wapitee Watermark 通过一行 `<script>` 引入官方托管的 console 彩蛋脚本，在浏览器 DevTools Console 中输出 Wapitee ASCII Logo 与品牌文案。所有视觉资产（Logo、颜色 `#E42767`、文案、字号）已在 CDN 脚本内固化，**项目侧无需嵌入任何 ASCII art 或 console.log 代码**。注入位置应放在 `<head>` 的最前面，确保打开 DevTools 时第一时间可见。

官方脚本地址：

```
https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js
```

## When to Use This Skill

- 用户提到"加 Wapitee 水印 / watermark / console 水印 / console logo"等触发词
- 新项目初始化（Next.js / Vite / Nuxt / 纯 HTML）希望注入品牌水印
- 现有项目排查水印缺失
- 已有项目使用过旧版"内联 ASCII art"方案，希望迁移到 CDN 单脚本方案

## Core Instructions

### Step 1: Detect framework and existing watermark

注入前先扫描项目，判断技术栈并检查是否已存在水印。

判断框架的常见特征：

| 框架 | 关键文件 / 依赖 |
|------|----------------|
| Next.js (App Router) | `app/layout.tsx`、含 `app/` 目录 |
| Next.js (Pages Router) | `pages/_document.tsx` / `pages/_app.tsx` |
| React (Vite / CRA) | `index.html` + `vite.config.*` 或 `react-scripts` |
| Vue 3 (Vite) | `index.html` + `src/main.js` 含 `createApp` |
| Nuxt 3 | `nuxt.config.ts`、`app.vue` |
| 纯 HTML | 仅有 `index.html`，无前端框架依赖 |

检测水印是否已注入，匹配以下任一特征即视为已存在：

- 字符串 `console-easter-egg`
- 字符串 `Wapitee-Interactive-Marketing-Limited`
- 旧版残留：`Crafted with ❤️ by Wapitee` / `hi@wapitee.io`

若已存在，直接输出"Wapitee console watermark 已存在，跳过注入"，**不重复注入**。
若检测到旧版内联 ASCII 代码，建议同时清理掉，统一改用 CDN 单脚本方案。

### Step 2: Inject the CDN script into `<head>`

按框架选择对应入口的 `<head>`，在最前面插入一行 `<script>`：

```html
<script src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js"></script>
```

下面给出每种框架的精确插入位置。

---

#### Next.js (App Router)

在 `app/layout.tsx` 的 `<head>` 中加入 `<script>`。

```tsx
// app/layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <script
          src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

---

#### Next.js (Pages Router)

在 `pages/_document.tsx` 的 `<Head>` 中加入。

```tsx
// pages/_document.tsx
import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        <script src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
```

---

#### React (Vite / CRA)

直接编辑 `index.html`，在 `<head>` 中加入 `<script>`。

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>App</title>
    <script src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

---

#### Vue 3 (Vite)

同样编辑根目录的 `index.html`。

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>App</title>
    <script src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js"></script>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
```

---

#### Nuxt 3

在 `nuxt.config.ts` 的 `app.head.script` 中声明。

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  app: {
    head: {
      script: [
        {
          src: "https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js",
        },
      ],
    },
  },
});
```

---

#### 纯 HTML

直接在 `<head>` 中加入。

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Wapitee</title>
    <script src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js"></script>
  </head>
  <body></body>
</html>
```

---

#### 其他 / 未知框架

无法识别框架时，统一回退到 HTML 模板：让用户把下面这一行复制粘贴到项目入口 HTML 的 `<head>` 内。

```html
<script src="https://cdn.jsdelivr.net/gh/Wapitee-Interactive-Marketing-Limited/console-easter-egg@main/index.js"></script>
```

### Step 3: Verify the watermark

注入完成后输出以下结构化结果：

```
### 变更摘要
- 框架: [Next.js / React / Vue / ...]
- 注入位置: [文件路径]
- 状态: [已注入 / 已存在，跳过 / 已从旧版迁移到 CDN]

### Post-Deployment Checklist
- [ ] 打开浏览器 DevTools → Console，确认 Wapitee Logo 与文案已显示
- [ ] Logo 颜色为 #E42767（洋红色）
- [ ] 文案顺序：Logo → "Crafted with ❤️ by Wapitee" → "Contact us 👉 hi@wapitee.io"
- [ ] 刷新页面，水印在加载早期出现
- [ ] 项目中只引入了一次该 CDN 脚本（无重复）
- [ ] 旧版内联 ASCII / console.log 代码已清理（如有）

### 更新后的代码
[完整修改后的文件内容，而非 diff]
```

## Best Practices

- **始终使用官方 CDN 链接**：所有视觉资产（Logo、颜色、文案）由 CDN 脚本统一维护，禁止 fork 后自托管，否则品牌升级时无法同步。
- **放在 `<head>` 最前面**：紧跟 `<meta charset>` 之后，确保 DevTools 打开时立刻可见。
- **不加 `async` / `defer`**：脚本仅做 `console.log`，体积极小，无阻塞担忧；保留默认行为可让水印更早出现。
- **优先在 HTML 模板（`index.html` / `_document.tsx` / `nuxt.config.ts`）注入**：而非组件 `useEffect` / `onMounted`，避免 hydration 之后才打印。
- **迁移旧版项目时清理内联代码**：若项目里残留旧版 ASCII art / `console.log` 代码，建议删除后改用 CDN 单脚本方案。

## Common Pitfalls

| 问题 | 解决方案 |
|------|----------|
| 水印没出现 | 检查是否真的写在了 HTML 模板的 `<head>` 内（不要写到组件 JSX 里），并确认 CDN 链接可访问 |
| 水印出现两次 | 项目同时存在 CDN 引入 + 旧版内联代码；删除旧版内联部分，仅保留 CDN |
| Next.js App Router 中 ESLint 报 "use `<Script>` from next/script" | 这是建议性警告；远程 `<script>` 直接写在 `<head>` 是合规的，可在该行加 `// eslint-disable-next-line @next/next/no-sync-scripts`，或改用 `next/script` 的 `<Script strategy="beforeInteractive" />` |
| Nuxt 中通过 `useHead` 写在组件里水印延迟出现 | 改在 `nuxt.config.ts` 的 `app.head.script` 中声明，让 SSR 输出 HTML 时就已包含 |
| jsDelivr 偶发不可达 | 该方案依赖 jsDelivr CDN；若内网环境无法访问，需自行镜像该 JS 到可访问域名后替换 `src` |

## Hard Rules (Never Violate)

- **NEVER** 修改、复制或 fork CDN 脚本的内容到本地内联（破坏品牌一致性 & 升级链路）
- **NEVER** 重复引入：同一项目里只能有一份 `<script src=".../console-easter-egg@main/index.js">`
- **NEVER** 改写 ASCII Logo、品牌色 `#E42767` 或文案——所有视觉规范由 CDN 脚本固化
- **ALWAYS** 把 `<script>` 放在 HTML 模板的 `<head>` 中，而非组件生命周期里
- **ALWAYS** 在迁移旧项目时同步删除旧版内联水印代码
- **ALWAYS** 输出完整修改后文件，而非仅 diff
