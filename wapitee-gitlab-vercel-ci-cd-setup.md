---
name: gitlab-vercel-ci-cd-setup
description: >
  交互式 GitLab CE (Self-Managed) + Vercel CI/CD 集成配置助手。
  用于帮助用户在自建 GitLab 和 Vercel 之间建立自动化部署流程。
  具备中断式提问能力：当缺少 VERCEL_TOKEN、GITLAB_URL、PROJECT_ID 等必要信息时，
  会主动暂停并询问用户输入，确保配置准确性。
  生成包含 .gitlab-ci.yml、环境变量设置指南和 Vercel CLI 配置脚本的完整方案。
triggers:
  - "gitlab vercel 集成"
  - "自建 gitlab 部署到 vercel"
  - "gitlab ci/cd vercel"
  - "self-hosted gitlab vercel deployment"
  - "gitlab ce vercel"
version: 1.0.0
---

# GitLab CE + Vercel CI/CD 集成配置向导

## 触发条件

当用户提到以下关键词时激活：
- "gitlab vercel 集成"
- "自建 gitlab 部署到 vercel"
- "gitlab ci/cd vercel"
- "self-hosted gitlab vercel deployment"
- "社区版 gitlab vercel"
- "gitlab ce vercel"

## 核心工作流（含中断式交互）

### 阶段 1：信息收集（中断提问模式）

必须按顺序确认以下信息，**缺失任何一项都必须中断并询问用户**：

1. **GitLab 信息**
   - [ ] `GITLAB_URL`: 自建 GitLab 地址（如 https://gitlab.company.com）
   - [ ] `IS_GROUP_VARIABLE`: 是否使用 Group 级别共享变量（true/false）

2. **Vercel 凭证**（最高优先级检查）
   - [ ] `VERCEL_TOKEN`: Vercel Access Token（必须用户提供）
   - [ ] `VERCEL_ORG_ID`: Vercel Team ID（个人用户则为个人 ID）
   - [ ] `VERCEL_PROJECT_ID`: 具体项目的 Project ID

3. **项目技术栈**
   - [ ] `FRAMEWORK`: 前端框架（nextjs/nuxt/react/vue/static）
   - [ ] `BUILD_OUTPUT_DIR`: 构建输出目录（如 .next、dist、.output）

### 阶段 2：中断提问逻辑（关键）

**规则：如果以下任一条件满足，立即停止生成配置并询问用户：**

```markdown
IF 用户未提供 VERCEL_TOKEN:
  → 中断并提问："请提供你的 Vercel Access Token（从 https://vercel.com/account/tokens 创建）："

IF 用户未提供 GITLAB_URL:
  → 中断并提问："你的自建 GitLab 地址是什么？（例如：https://gitlab.yourcompany.com）："

IF 用户未确认 Vercel PROJECT_ID:
  → 中断并提问：
     "你需要为这个项目创建 Vercel Project 并获取 Project ID。
      请先在本地执行：
      1. npm install -g vercel
      2. vercel login
      3. vercel link
      然后提供 .vercel/project.json 中的 projectId："

IF 用户未提供 FRAMEWORK:
  → 中断并提问："你的前端项目使用什么框架？（nextjs/nuxt/react/vue/other）："
```

### 阶段 3：根据收集的信息生成配置

#### 1. GitLab CI/CD 模板（.gitlab-ci.yml）

```yaml
stages:
  - build
  - deploy

variables:
  # 缓存配置
  npm_config_cache: "$CI_PROJECT_DIR/.npm"
  VERCEL_ORG_ID: $VERCEL_ORG_ID
  VERCEL_PROJECT_ID: $VERCEL_PROJECT_ID

# 安装依赖并构建
build:
  stage: build
  image: node:20
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .npm/
  script:
    - npm ci
    - npm run build
    # 生成 Vercel 配置
    - npx vercel build --token=$VERCEL_TOKEN --yes
  artifacts:
    expire_in: 1 hour
    paths:
      - .vercel/output

# 生产环境部署（main/master 分支）
deploy:production:
  stage: deploy
  image: node:20
  script:
    - npm install -g vercel
    - vercel deploy --prebuilt --prod --token=$VERCEL_TOKEN --yes
  dependencies:
    - build
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# 预览环境部署（其他分支/MR）
deploy:preview:
  stage: deploy
  image: node:20
  script:
    - npm install -g vercel
    - vercel deploy --prebuilt --token=$VERCEL_TOKEN --yes
  dependencies:
    - build
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
```

#### 2. 环境变量设置脚本（用于 Group 级别配置）

如果你选择 **Group 级别共享变量**（推荐用于多项目管理）：

```bash
#!/bin/bash
# setup-group-variables.sh
# 在 GitLab Group 设置中批量配置共享变量

GITLAB_GROUP_ID="your-group-id"
GITLAB_URL="{{GITLAB_URL}}"
PRIVATE_TOKEN="{{GITLAB_PRIVATE_TOKEN}}"  # 需要用户在 GitLab 生成

# 1. 设置共享的 ORG_ID（整个团队共用）
curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN"   --data "key=VERCEL_ORG_ID&value={{VERCEL_ORG_ID}}&masked=true&protected=true"   "$GITLAB_URL/api/v4/groups/$GITLAB_GROUP_ID/variables"

echo "✅ Group 级别变量设置完成"
echo "⚠️  每个项目仍需单独设置 VERCEL_PROJECT_ID"
```

#### 3. 项目初始化辅助脚本

```bash
#!/bin/bash
# init-project.sh
# 用于快速初始化新项目

PROJECT_NAME=$1
GITLAB_PROJECT_ID=$2
GITLAB_URL="{{GITLAB_URL}}"
PRIVATE_TOKEN="{{GITLAB_PRIVATE_TOKEN}}"

echo "🚀 初始化项目: $PROJECT_NAME"

# 1. 链接 Vercel 项目
cd $PROJECT_NAME
vercel link --yes --token={{VERCEL_TOKEN}}
PROJECT_ID=$(cat .vercel/project.json | grep -o '"projectId":"[^"]*' | cut -d'"' -f4)

# 2. 自动设置 GitLab 变量
curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN"   --data "key=VERCEL_PROJECT_ID&value=$PROJECT_ID&masked=true&protected=true"   "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/variables"

echo "✅ 项目 $PROJECT_NAME 初始化完成"
echo "Project ID: $PROJECT_ID 已自动配置到 GitLab"
```

#### 4. 给用户的操作清单

```
✅ 已完成配置生成，请按以下步骤操作：

1. 【在 GitLab 中】
   - 进入 Project → Settings → CI/CD → Variables
   - 添加以下变量（全部设为 Masked + Protected）：
     * VERCEL_TOKEN = {{VERCEL_TOKEN}}
     * VERCEL_ORG_ID = {{VERCEL_ORG_ID}} 
     * VERCEL_PROJECT_ID = {{VERCEL_PROJECT_ID}}

2. 【在项目根目录】
   - 创建文件 .gitlab-ci.yml（内容已在上文提供）
   - 可选：添加 vercel.json 自定义构建设置

3. 【测试部署】
   - git push origin main
   - 查看 GitLab CI/CD Pipelines 页面
   - 检查 Vercel Dashboard 是否出现新部署
```

## 交互示例

**用户说**："帮我设置 GitLab 到 Vercel 的自动部署"

**Skill 响应**：
> 我来帮你配置自建 GitLab + Vercel 的 CI/CD 集成。首先我需要确认几个必要信息：
>
> 1. **你的自建 GitLab 地址是什么？**（例如：https://gitlab.yourcompany.com）
> 2. **你的 Vercel Access Token 是什么？**（从 https://vercel.com/account/tokens 创建，需要 full access）
> 3. **这个项目是否已经链接到 Vercel？**（是否已有 projectId？）
>
> 请提供以上信息，我会为你生成完整的配置文件。

**用户提供信息后**：
> 收到！基于你提供的信息：
> - GitLab: {{GITLAB_URL}}
> - Vercel Team: {{VERCEL_ORG_ID}}
> - 技术栈: {{FRAMEWORK}}
>
> 正在为你生成配置...

## 技术原理说明

### 为什么需要 `--prebuilt`？

自建 GitLab CE 无法使用 Vercel 原生的 Git 集成（该功能仅限 GitLab.com），因此通过以下流程实现：

1. **GitLab Runner 构建**：在 GitLab CI 中执行 `vercel build`，在 GitLab 服务器上完成构建
2. **产物上传**：通过 `vercel deploy --prebuilt` 只上传 `.vercel/output` 目录
3. **源代码安全**：Vercel 云端看不到源代码，只能看到构建产物

### 分支策略

- **main/master**: 自动部署到 Vercel Production 环境
- **其他分支**: 生成 Preview Deployment，URL 格式为 `https://<project>-git-<branch>-<team>.vercel.app`

## 故障排查指南

### 常见问题 1："Error: Project not found"
**原因**: VERCEL_PROJECT_ID 错误或项目未链接
**解决**: 在项目目录执行 `vercel link` 重新获取 projectId

### 常见问题 2："Error: Invalid token"
**原因**: VERCEL_TOKEN 无效或过期
**解决**: 前往 https://vercel.com/account/tokens 重新创建 Token

### 常见问题 3：构建失败但本地正常
**原因**: GitLab Runner 环境缺少必要依赖
**解决**: 在 `build` job 的 `before_script` 中添加系统依赖安装

```yaml
build:
  before_script:
    - apt-get update && apt-get install -y libcairo2-dev libjpeg-dev  # 示例：Canvas 依赖
```

### 常见问题 4：部署成功但页面 404
**原因**: 构建输出目录配置错误
**解决**: 检查 `FRAMEWORK` 对应的输出目录是否正确：
- Next.js: `.next`
- Nuxt: `.output`
- Vite/Vue/React: `dist`

## 限制与提示

- **中断机制**：此 Skill 设计为对话式交互，不假设任何默认值
- **安全第一**：所有 Token 建议设置为 Masked，避免在日志中泄露
- **权限要求**：需要 GitLab Maintainer 权限才能设置 CI/CD Variables
- **Vercel 限额**：注意 Vercel Hobby 计划的构建限额，CI/CD 部署也会消耗额度
- **多项目管理**：建议使用 Group 级别变量共享 VERCEL_ORG_ID，减少重复配置
