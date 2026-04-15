<!-- ai-directive: skill-registry -->
# Wapitee Skill Registry

> **AI 读取规则**：当用户发起任何请求时，**优先读取本文件**，根据用户意图匹配下方技能列表，然后再读取对应的具体 skill 文件。不要直接猜测该用哪个 skill。

---

## Skill 速查表

| 匹配优先级 | 触发场景（关键词/意图） | Skill 文件名 | Skill 名称 |
|:---|:---|:---|:---|
| **P0** | 用户提到 `git push`、`commit`、Wapitee 内部 GitLab、SSH 配置（端口 8822） | `wapitee-gitlab-push.md` | `wapitee-gitlab-push` |
| **P0** | 用户提到 `gitlab vercel` 集成、自建 GitLab 部署到 Vercel、CI/CD 配置 | `wapitee-gitlab-vercel-ci-cd-setup.md` | `gitlab-vercel-ci-cd-setup` |
| **P0** | 用户提到 Meta Pixel / Facebook Pixel / `fbq` / Lead 追踪 / Pixel ID | `meta-pixel-tracking-with-privacy-v2.md` | `meta-pixel-tracking` |
| **P0** | 用户提到 Google Analytics 4 / `ga4` / `gtag` / GA4 埋点 / 需要 Meta-GA4 事件对照 | `google-analytics-4-setup.md` | `google-analytics-4-setup` |
| **P1** | 用户提到 `clarity` + `gdpr`、`隐私`、`cookie banner`、`consent mode`、`同意管理` | `microsoft-clarity-gdpr-control.md` | `microsoft-clarity-gdpr-control` |
| **P1** | 用户提到 `clarity 埋点`、`自定义事件`、`热力图`、`追踪用户行为`、`event tracking`（不含隐私/Consent 关键词） | `microsoft-clarity-setup.md` | `microsoft-clarity-setup` |

---

## 冲突解决规则

当有多个 skill 可能匹配时，按以下规则决策：

### 1. Microsoft Clarity 二选一

```
IF 用户输入包含 (gdpr OR 隐私 OR cookie banner OR consent OR 合规 OR 同意):
    → 使用 microsoft-clarity-gdpr-control.md
ELSE IF 用户输入包含 (埋点 OR 自定义事件 OR 热力图 OR 追踪 OR tracking OR event):
    → 使用 microsoft-clarity-setup.md
ELSE:
    → 询问用户具体需求（隐私合规 vs 基础埋点/自定义事件）
```

### 2. GitLab 二选一

```
IF 用户输入包含 (vercel OR ci/cd OR 部署 OR deployment OR gitlab-ci.yml):
    → 使用 wapitee-gitlab-vercel-ci-cd-setup.md
ELSE IF 用户输入包含 (push OR commit OR ssh OR 8822 OR git.wapitee.io):
    → 使用 wapitee-gitlab-push.md
ELSE:
    → 询问用户是内部 GitLab 操作还是 Vercel CI/CD 配置
```

### 3. Meta + GA4 组合场景

```
IF 用户输入同时包含 (meta OR facebook OR fbq) AND (ga4 OR google analytics OR gtag):
    → 同时读取 meta-pixel-tracking.md 和 google-analytics-4-setup.md
    → 特别注意：Meta 事件使用 PascalCase，GA4 事件使用 snake_case
    → 为同一业务场景生成两套正确命名的事件代码
```

---

## Skill 清单（详细版）

### `wapitee-gitlab-push`
- **文件**：`wapitee-gitlab-push.md`
- **作用**：Wapitee 内部 GitLab 的默认配置与 push 工作流
- **核心能力**：
  - 自动检查/写入 `~/.ssh/config`（端口 8822）
  - 生成 ed25519 SSH 密钥并提示用户添加到 GitLab
  - 执行 `git add / commit / push`（commit message 强制中文）
- **必备信息**：无（会自动检查环境）

### `gitlab-vercel-ci-cd-setup`
- **文件**：`wapitee-gitlab-vercel-ci-cd-setup.md`
- **作用**：自建 GitLab CE 与 Vercel 的自动化部署集成
- **核心能力**：
  - 交互式收集 `VERCEL_TOKEN`、`GITLAB_URL`、`PROJECT_ID` 等必要信息
  - 生成 `.gitlab-ci.yml`、环境变量设置脚本、项目初始化脚本
- **必备信息**：`VERCEL_TOKEN`、`GITLAB_URL`、`VERCEL_ORG_ID`、`VERCEL_PROJECT_ID`、`FRAMEWORK`

### `meta-pixel-tracking`
- **文件**：`meta-pixel-tracking-with-privacy-v2.md`
- **作用**：Meta (Facebook) Pixel 的隐私合规安装与事件追踪
- **核心能力**：
  - 注入 Pixel base code、PageView、Lead 转化
  - GDPR / ePrivacy / CCPA 合规控制（Consent Mode、Limited Data Use）
  - 支持 Standard / Basic Consent / Advanced Consent 三种模式
- **必备信息**：Pixel ID（如缺失会中断并询问）

### `microsoft-clarity-gdpr-control`
- **文件**：`microsoft-clarity-gdpr-control.md`
- **作用**：Microsoft Clarity 的隐私合规与 Cookie Banner 集成
- **核心能力**：
  - Consent Mode V2 控制代码（延迟加载、同意级别切换、无 Cookie 模式）
  - 与 Cookiebot、OneTrust、Osano 或自建 Banner 集成
- **必备信息**：用户选择的同意级别（拒绝 / 仅分析 / 全部同意）

### `google-analytics-4-setup`
- **文件**：`google-analytics-4-setup.md`
- **作用**：Google Analytics 4 基础埋点、标准事件生成、以及 Meta-GA4 事件命名对照
- **核心能力**：
  - 生成 gtag 基础代码与 Consent Mode V2 配置
  - 提供完整的 Meta ↔ GA4 标准事件对照表（避免命名混用）
  - 支持多平台统一 consent 控制层
- **必备信息**：GA4 Measurement ID（如缺失会中断并询问）

### `microsoft-clarity-setup`
- **文件**：`microsoft-clarity-setup.md`
- **作用**：Microsoft Clarity 基础埋点与智能自定义事件生成
- **核心能力**：
  - 生成基础追踪代码（HTML / Next.js / React / Vue / Nuxt）
  - 根据自然语言描述自动生成自定义事件代码（hover / click / scroll / form）
- **必备信息**：Clarity Project ID（基础埋点模式）

---

## 给团队的使用方式

### 核心原则：用户直接提需求，AI 自动匹配

**你不需要手动 @skill 或告诉 AI 该用哪个文件。** 只要在系统 Prompt 中配置好规则，AI 会自己先读 `README.md`，然后根据你的需求自动选择正确的 skill。如果需求涉及多个 skill（比如同时埋 Meta + GA4），AI 会自动组合执行。

### 系统 Prompt 配置（推荐）

```
You have access to the following skill directory: /Users/jacobg/Desktop/wapitee-skill

Before answering any user request:
1. Read /Users/jacobg/Desktop/wapitee-skill/README.md to determine which skill to use
2. Read /Users/jacobg/Desktop/wapitee-skill/FEEDBACK_LOG.md for any known issues or lessons learned
3. Then read the matched skill file(s)
4. Follow the instructions in that skill strictly
5. After generating the output, present the Post-Deployment Checklist from the skill
6. Ask the user: "是否需要将本次遇到的问题或改进建议记录到 FEEDBACK_LOG.md？"
```

### 组合调用示例

| 用户说的话 | AI 的行为 |
|:---|:---|
| "帮我加 Meta Pixel" | 读 `meta-pixel-tracking.md` → 生成代码 → 输出自检清单 |
| "我要同时做 Meta Pixel 和 GA4，还有 Cookie Banner" | 读 `meta-pixel-tracking.md` + `google-analytics-4-setup.md` + `microsoft-clarity-gdpr-control.md` → 生成统一 consent 控制层 + 各平台正确的事件命名 |
| " push 代码到 GitLab" | 读 `wapitee-gitlab-push.md` → 检查 SSH → 执行 push |

### 反馈日志的用法

`FEEDBACK_LOG.md` 是团队的共同知识库：
- **读取**：AI 每次回答前会自动读取，避免重复踩坑。
- **写入**：AI 不会自动写。它会在完成任务后**主动问你** "要不要记一条反馈？"，只有你同意，它才会追加。

### 方式 A：Prompt 引用（推荐）

在系统 Prompt 或 Project Instructions 中加入：

```
You have access to the following skill directory: /Users/jacobg/Desktop/wapitee-skill

Before answering any user request:
1. Read /Users/jacobg/Desktop/wapitee-skill/README.md to determine which skill to use
2. Then read the matched skill file
3. Follow the instructions in that skill strictly
```

### 方式 B：Claude Code 项目级配置

如果使用 Claude Code，可以在项目根目录的 `.claude/CLAUDE.md` 或类似配置中引用本注册表。

---

## 新增 Skill 规范

1. 复制 `SKILL_TEMPLATE.md` 作为起点
2. 文件名使用小写英文，单词间用连字符 `-`
3. **必须**包含标准 YAML frontmatter（`name`、`description`、`triggers`、`version`）
4. 完成后**更新本 README.md** 的速查表和详细清单
5. 若与现有 skill 场景重叠，必须在 README 中补充冲突解决规则
