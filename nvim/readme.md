# PR Review Workflow

## 快速开始

### 查看所有 PR
- `<leader>pr` - 列出当前仓库的所有 Pull Requests
- `<leader>po` - 列出并 checkout PR
- `<leader>pi` - 列出 GitHub Issues

### PR Review 工作流

#### 1. 查看并切换到 PR
```
<leader>po -> 选择 PR -> Enter (checkout PR 分支)
```

#### 2. 查看 PR 详情和文件变更
- `:Octo pr open <PR编号>` - 打开 PR 详情面板
- `:Octo pr files <PR编号>` - 查看变更文件列表
- `<leader>pf` - 在 PR 中查看变更文件
- `<leader>pc` - 查看 PR 的 commits
- `<leader>pd` - 查看 PR diff

#### 3. 代码审查（添加评论）
- 在 diff 视图中：`<leader>ca` - 添加评论
- 在 diff 视图中：`<leader>sa` - 添加建议（会自动生成代码片段）
- `]c` / `[c` - 在评论之间导航
- `]t` / `[t` - 在评论线程之间导航

#### 4. 提交 Review 决定
- `<leader>pa` - Approve PR
- `<leader>pr` - Request Changes
- `<leader>psm` - Squash and Merge
- `<leader>pm` - Merge PR

#### 5. 回复评论
- 在评论上按 `<leader>ca` 添加回复

### 其他常用命令
- `<C-b>` - 在浏览器中打开当前 PR/Issue
- `<C-y>` - 复制当前 PR/Issue 的 URL
- `<leader>aa` - 添加 assignee
- `<leader>la` / `<leader>ld` - 添加/移除 label
- `<leader>gi` - 跳转到关联的 issue

### Reaction 快捷键
- `<leader>rp` - 🎉 Hooray
- `<leader>rh` - ❤️ Heart
- `<leader>re` - 👀 Eyes
- `<leader>r+` - 👍 Thumbs up
- `<leader>r-` - 👎 Thumbs down
- `<leader>rr` - 🚀 Rocket
- `<leader>rl` - 😄 Laugh

## 工作流示例

1. **开始审查**：`<leader>po` 选择要审查的 PR
2. **查看文件**：使用 `gf` 跳转到具体文件，或 `<leader>pf` 查看变更文件
3. **添加评论**：在需要审查的代码行上按 `<leader>ca`
4. **提出建议**：按 `<leader>sa` 提供代码改进建议
5. **提交决定**：审查完成后按 `<leader>pa` 批准，或 `<leader>pr` 要求修改

## 依赖
- `gh` CLI 工具（确保已安装并登录）
- GitHub 访问权限
- 仓库必须已 git clone 到本地

# keymap

## Buffer
<C-i> Prev Buffer
<C-o> Next Buffer
<Space-b-d> Close Buffer


## Window 

<\> Vsplit
<C-h> Go to left window
<C-l> Go to right window


## Common
    using neovide for UI support is provade fast & annimations & copy parse etc

cd ~/works/%s Change work dir to the target

