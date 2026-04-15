---
name: wapitee-gitlab-push
description: >
  Wapitee 内部 GitLab 服务器的默认配置与 Push 工作流助手。
  自动处理 SSH 配置（端口 8822）、密钥检查、git push/pull/clone 操作。
  所有 commit message 强制使用中文规范格式。
triggers:
  - "git push"
  - "gitlab"
  - "git.wapitee.io"
  - "8822"
  - "wapitee 内部服务器"
version: 1.0.0
---

# GitLab 配置（Wapitee 内部服务器）

## 重要：默认 Git 远端

除非用户明确指定使用 GitHub 或其他服务，否则所有 git 操作（push、pull、clone）均默认使用 Wapitee 内部 GitLab 服务器。

- **GitLab 地址：** `https://git.wapitee.io`
- **SSH 地址格式：** `git@git.wapitee.io:<用户名>/<项目名>.git`
- **SSH 端口：** `8822`（非默认的 22 端口，这是最容易出错的地方）
- **技术支持：** `jacob@wapitee.io`

## SSH 配置要求

在执行任何 git 操作前，确认 `~/.ssh/config` 中包含以下配置。如果没有，自动写入：

```
Host git.wapitee.io
    HostName git.wapitee.io
    Port 8822
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

写入后设置权限：`chmod 600 ~/.ssh/config`

## Push 工作流

当用户要求推送代码时，按以下顺序执行：

1. **检查 SSH 配置** — 确认 `~/.ssh/config` 已包含上述 8822 端口配置，若无则自动添加。
2. **检查 SSH 密钥** — 确认 `~/.ssh/id_ed25519` 存在。若不存在，生成密钥并将公钥内容展示给用户，提示用户前往 `https://git.wapitee.io → Preferences → SSH Keys` 手动添加，等待用户确认后再继续。
3. **测试连接** — 执行 `ssh -T git@git.wapitee.io`，确认返回 `Welcome to GitLab`。
4. **执行 Git 操作** — 按需执行 `git add`、`git commit`、`git push`。

## Commit Message 规范

- **必须使用中文**
- 格式：`<类型>: <清晰的中文描述>`
- 常用类型：`feat`（新功能）、`fix`（修复）、`docs`（文档）、`style`（样式）、`refactor`（重构）、`chore`（杂项）
- 示例：
  - `feat: 新增用户登录页面`
  - `fix: 修复首页在移动端的布局错位`
  - `docs: 更新项目 README 说明`

## 常见错误处理

| 错误信息 | 原因 | 解决方法 |
|---|---|---|
| `Permission denied (publickey)` | 公钥未添加到 GitLab 或 SSH 配置缺少 8822 端口 | 重新检查 `~/.ssh/config` 并确认公钥已在 GitLab 添加 |
| `port 22: Connection refused` | SSH 配置缺少 `Port 8822` | 检查并修复 `~/.ssh/config` |
| `Could not resolve hostname` | 网络或 DNS 问题 | 检查网络连接，或联系 `jacob@wapitee.io` |
