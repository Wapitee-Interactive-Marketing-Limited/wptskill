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

### `microsoft-clarity-setup`
- **文件**：`microsoft-clarity-setup.md`
- **作用**：Microsoft Clarity 基础埋点与智能自定义事件生成
- **核心能力**：
  - 生成基础追踪代码（HTML / Next.js / React / Vue / Nuxt）
  - 根据自然语言描述自动生成自定义事件代码（hover / click / scroll / form）
- **必备信息**：Clarity Project ID（基础埋点模式）

---

## 给团队的使用方式

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
