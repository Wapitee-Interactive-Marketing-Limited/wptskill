---
name: wapitee-watermark
description: >
  在网站项目的浏览器控制台（Browser Console）中尽早打印 Wapitee ASCII Logo
  与品牌信息，支持 React / Next.js / Vue / Nuxt / Svelte / Astro / 纯 HTML 等框架。
  确保水印在应用初始化时第一时间出现，且不影响页面性能。
triggers:
  - "wapitee 水印"
  - "watermark"
  - "添加水印"
  - "console logo"
  - "console 水印"
version: 1.2.0
---

# Wapitee Watermark Skill

## 触发条件

当用户提到以下内容时激活本 skill：
- "添加 Wapitee 水印"
- "帮我加 watermark"
- "console 里打印 Wapitee logo"
- "给网站加个 console 水印"

## 核心原则

1. **尽早加载**：水印代码必须在应用**最早可执行的入口**运行，确保打开 DevTools 时立刻可见。
2. **零副作用**：只操作 `console.log`，不修改 DOM、不阻塞渲染、不影响性能。
3. **全框架覆盖**：根据项目技术栈生成对应的注入位置和代码。
4. **品牌一致性**：ASCII Logo、文案、颜色必须严格使用 Wapitee 规范。

## 品牌规范（不可修改）

### ASCII Logo

```
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
```

### Console 输出内容

1. **ASCII Art** — 颜色 `#E42767`，粗体
2. **"🚀 Crafted with ❤️ by Wapitee "** — 颜色 `#E42767`，`font-size: 14px`，粗体
3. **第三行文案** — 颜色 `#E42767`，`font-size: 14px`，粗体（**由用户选择，不再固定**）
4. **"Contact us 👉 hi@wapitee.io "** — 颜色 `#E42767`，`font-size: 14px`，粗体

### 第三行文案选择规则

在注入水印前，**必须询问用户**第三行文案写什么：

> Wapitee 水印第三行可以写一句品牌副标题，你想写什么？
>
> 建议选项（选一个，或自定义）：
> 1. **Wapitee Market Validation Service** (Recommended)
> 2. Credit to Max & Jacob
> 3. Powered by Wapitee
> 4. 其他（请直接输入你想写的文案）

- 如果用户未回复，**默认使用**：`Wapitee Market Validation Service`
- 如果用户说"随便"、"你决定"、"默认"，**使用**：`Wapitee Market Validation Service`
- 如果用户输入了自定义文案，**直接采用用户输入**（保持原样，不做大小写转换）

## 执行流程

```
1. 扫描项目结构和提供的代码
2. 判断前端框架（Next.js / React / Vue / Nuxt / Svelte / Astro / 纯 HTML / 其他）
3. 检测水印代码是否已存在
   IF 存在 → 跳过，不重复注入
   IF 不存在 → 继续
4. 询问用户第三行文案（见上文"第三行文案选择规则"）
   IF 用户未回复或说默认 → 使用 "Wapitee Market Validation Service"
   IF 用户给出自定义文案 → 直接使用
5. 根据框架选择最佳注入位置（越早越好）
6. 生成对应框架的水印代码（将 THIRD_LINE_TEXT 替换为用户选择的文案）
7. 输出完整修改后的文件 + 变更摘要 + 检查清单
```

## 注入位置优先级（按框架）

| 框架 | 最佳注入位置 | 原因 |
|------|-------------|------|
| **Next.js (App Router)** | `app/layout.tsx` 顶部 或 `app/providers.tsx` 首行 | Root Layout 最先执行 |
| **Next.js (Pages Router)** | `pages/_app.tsx` / `pages/_app.js` 的组件体首行 | 每个页面共享的入口 |
| **React (Vite/CRA)** | `src/main.tsx` 或 `src/index.tsx` 的 `ReactDOM.createRoot` 之前 | 应用挂载前执行 |
| **Vue 3** | `src/main.js` 的 `createApp()` 之后、`app.mount()` 之前 | 应用初始化阶段 |
| **Nuxt 3** | `app.vue` 的 `<script setup>` 首行 或 `plugins/wapitee-watermark.client.ts` | 客户端插件最早执行 |
| **Svelte / SvelteKit** | `src/app.html` 的 `<head>` 内联脚本 或 `src/routes/+layout.svelte` | 服务端/客户端最早入口 |
| **Astro** | `src/layouts/Layout.astro` 的 `<head>` 内联 `<script>` | 页面渲染前执行 |
| **纯 HTML** | `<head>` 内的第一个 `<script>` | 页面解析时最早执行 |
| **其他 / 未知框架** | 直接给出可复制的 `<script>` 片段，让用户自行粘贴到项目入口 | 通用 fallback |

## 实现代码

### 浏览器兼容说明

Edge 浏览器的 DevTools Console 对部分 Unicode box-drawing 字符（如 `╗`、`╔`、`║`）的等宽渲染存在偏差，会导致 ASCII Logo 错位。因此水印代码需要**先检测浏览器**，再输出对应版本：

- **非 Edge 浏览器**（Chrome / Safari / Firefox 等）：使用原始 Unicode box-drawing 版本
- **Edge 浏览器**：使用纯标准 ASCII 字符版本（`/`、`\`、`|`、`_`），避免渲染错位

### 通用水印函数（所有框架共用）

```javascript
(function printWapiteeWatermark() {
  if (typeof window === "undefined") return;

  const isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);

  const asciiArt = isEdge
    ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
            `
    : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
            `;

  console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
  console.log(
    "%c🚀 Crafted with ❤️ by Wapitee ",
    "color: #E42767; font-size: 14px; font-weight: bold;"
  );
  console.log(
    "%cTHIRD_LINE_TEXT",
    "color: #E42767; font-size: 14px; font-weight: bold;"
  );
  console.log(
    "%cContact us 👉 hi@wapitee.io ",
    "color: #E42767; font-size: 14px; font-weight: bold;"
  );
})();
```

### Next.js 14 App Router

```tsx
// app/layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function(){
                if (typeof window === "undefined") return;
                var isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
                var asciiArt = isEdge
                  ? \`
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
                  \`
                  : \`
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
                  \`;
                console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
                console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
                console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
                console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");
              })();
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

> **原因**：放在 `<head>` 的内联脚本中，确保 SSR/ hydration 之前就已经在浏览器控制台输出。

### Next.js Pages Router

```tsx
// pages/_app.tsx
import type { AppProps } from "next/app";

if (typeof window !== "undefined") {
  const isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
  const asciiArt = isEdge
    ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
            `
    : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
            `;

  console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
  console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
  console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
  console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");
}

export default function MyApp({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
```

### React (Vite / CRA)

```tsx
// src/main.tsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

// Wapitee Console Watermark
const isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
const asciiArt = isEdge
  ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
            `
  : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
            `;
console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

### Vue 3

```javascript
// src/main.js
import { createApp } from "vue";
import App from "./App.vue";

const isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
const asciiArt = isEdge
  ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
            `
  : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
            `;
console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");

createApp(App).mount("#app");
```

### Nuxt 3

```ts
// plugins/wapitee-watermark.client.ts
export default defineNuxtPlugin(() => {
  const isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
  const asciiArt = isEdge
    ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
            `
    : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
            `;
  console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
  console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
  console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
  console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");
});
```

> Nuxt 自动识别 `.client.ts` 后缀，只在浏览器端运行。

### SvelteKit

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  if (typeof window !== "undefined") {
    const isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
    const asciiArt = isEdge
      ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
            `
      : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
            `;
    console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
    console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
    console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
    console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");
  }
</script>

<slot />
```

### Astro

```astro
---
// src/layouts/Layout.astro
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Wapitee</title>
    <script is:inline>
      (function(){
        var isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
        var asciiArt = isEdge
          ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
        `
          : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
        `;
        console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
        console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
        console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
        console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");
      })();
    </script>
  </head>
  <body>
    <slot />
  </body>
</html>
```

### 纯 HTML

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Wapitee</title>
    <script>
      (function(){
        var isEdge = typeof navigator !== "undefined" && /Edg/.test(navigator.userAgent);
        var asciiArt = isEdge
          ? `
 __          __  _      ____       _     _ _
 \\ \\        / / | |    |  _ \\     | |   | | |
  \\ \\  /\\  / /__| |__  | |_) | ___| |__ | | |_
   \\ \\/  \\/ / _ \\ '_ \\ |  _ < / _ \\ '_ \\| | __|
    \\  /\\  /  __/ |_) || |_) |  __/ |_) | | |_
     \\/  \\/ \\___|_.__/ |____/ \\___|_.__/|_|\\__|
        `
          : `
 ██╗    ██╗ █████╗ ██████╗ ██╗████████╗███████╗███████╗
 ██║    ██║██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██╔════╝
 ██║ █╗ ██║███████║██████╔╝██║   ██║   █████╗  █████╗
 ██║███╗██║██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██╔══╝
 ╚███╔███╔╝██║  ██║██║     ██║   ██║   ███████╗███████╗
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝
        `;
        console.log("%c" + asciiArt, "color: #E42767; font-weight: bold;");
        console.log("%c🚀 Crafted with ❤️ by Wapitee ", "color: #E42767; font-size: 14px; font-weight: bold;");
        console.log("%cTHIRD_LINE_TEXT", "color: #E42767; font-size: 14px; font-weight: bold;");
        console.log("%cContact us 👉 hi@wapitee.io ", "color: #E42767; font-size: 14px; font-weight: bold;");
      })();
    </script>
  </head>
  <body></body>
</html>
```

## 检测是否已存在

在注入前，AI 必须扫描代码中是否已存在以下任一特征：
- `"Crafted with ❤️ by Wapitee"`
- `"hi@wapitee.io"`
- `███████╗`（ASCII Logo 的尾部特征）

如果检测到，则**不重复注入**，并在输出中说明：
> "Wapitee console watermark 已存在，跳过注入。"

## 输出格式

```
### 变更摘要

- **框架**: [Next.js / React / Vue / ...]
- **注入位置**: [文件路径]
- **状态**: [已注入 / 已存在，跳过]

### Post-Deployment Checklist

- [ ] 打开浏览器 DevTools → Console，确认 Wapitee Logo 和文案已显示
- [ ] 确认 Logo 颜色为 `#E42767`（洋红色）
- [ ] 确认文案顺序正确：Logo → "Crafted with..." → 第三行文案 → "Contact us..."
- [ ] 刷新页面，确认水印在页面加载早期即出现
- [ ] 确认没有重复输出（同一 Logo 只出现一次）
- [ ] 在 **Edge 浏览器** 中打开 Console，确认 Logo 没有错位或变形（Edge 会显示纯 ASCII 版本）

### 更新后的代码

[输出完整修改后的文件内容]
```

## 硬规则（Never Violate）

- **NEVER** 修改 ASCII Logo 的字符内容或排版
- **NEVER** 修改品牌颜色 `#E42767` 和输出文案
- **NEVER** 重复注入：同一项目里只能有一份 watermark 代码
- **ALWAYS** 将水印放在应用**最早可执行的入口**
- **ALWAYS** 在 SSR 框架中使用 `typeof window !== "undefined"` 检查或 `.client` 插件，避免服务端报错
- **ALWAYS** 优先使用内联 `<script>` 或模块顶层代码，而不是 `useEffect` / `onMounted` 等延迟生命周期
- **ALWAYS** 在水印代码中包含 Edge 浏览器检测与纯 ASCII 备用版本，防止 Logo 在 Edge Console 中错位
- **ALWAYS** 输出完整的修改后文件，而非仅给出 diff
