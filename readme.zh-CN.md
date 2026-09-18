# dotfiles

**简体中文** | [English](README.md)

个人 dotfiles 仓库,包含 **Fish**、**Neovim**、**Helix**、**Ghostty**、**Alacritty**、**i3 / Sway / Waybar** 的配置,以及 **Obsidian 同步**、**agent 漂浮窗**等辅助脚本。

支持 **macOS** 和 **Linux**(Arch / Debian / Ubuntu / Fedora)。一条命令即可在空白机器上完成全部安装。

> 各配置的功能细节见 [FEATURES.md](FEATURES.md);Neovim 配置说明见 [nvim/readme.md](nvim/readme.md)。

---

## 快速开始

> 适合任何 Agent 自动化执行:克隆后运行 `./install.sh` 即可。

```bash
git clone <your-repo-url> ~/works/dotfiles
cd ~/works/dotfiles
./install.sh           # 交互式
./install.sh --all     # 全自动,不询问
```

脚本会自动完成:

1. **系统包** — macOS 用 Homebrew,Linux 用发行版自带包管理器
2. **Oh My Tmux!** — 克隆上游到 `~/.tmux`,软链 `~/.tmux.conf`
3. **Stow 软链接** — `fish/ nvim/ helix/ alacritty/ ghostty/ fcitx5/ i3/ sway/ waybar/` 全部链接到 `~/.config/`
4. **Fish 插件** — Fisher + 4 个插件(写进 `fish_plugins`;部分插件文件已 vendored 在仓库内)
5. **Neovim 插件** — lazy.nvim 首次启动自动拉取
6. **环境变量文件** — `conf.d/_99_dotfiles_env.fish`(代理 / fcitx)
7. **Linux 附加** — Thunar 设为默认文件管理器;可选安装 Vicinae 启动器

### 参数

| 参数 | 说明 |
|---|---|
| `./install.sh` | 交互式安装(默认) |
| `./install.sh --all` | 全自动,跳过所有确认 |
| `./install.sh --stow-only` | 只软链接 dotfiles,不装系统包 |
| `./install.sh --no-stow` | 只装系统包,不链接 dotfiles |
| `./install.sh -h` | 查看帮助 |

---

## 仓库结构

```
dotfiles/
├── install.sh                # 一键安装脚本(本仓库入口)
├── README.md                 # 英文说明(默认)
├── readme.zh-CN.md           # 本文件
├── FEATURES.md               # 各配置的功能细节与用法
├── alacritty/                # alacritty.toml + themes/(配色方案)
├── ghostty/                  # ghostty/config
├── fish/                     # Fish shell 配置
│   ├── config.fish
│   ├── fish_variables
│   ├── completions/          # bun / copilot / fisher / fzf 等补全
│   ├── conf.d/               # 模块化配置(编号排序:OS 检测、PATH、工具链、fzf、快捷键…)
│   └── functions/            # 自定义函数 + vendored 插件(git 别名、bass、fzf 包装等)
├── nvim/                     # Neovim 配置(lazy.nvim)
│   ├── init.lua
│   ├── lazy-lock.json        # 插件版本锁
│   └── lua/{config,plugins}/
├── helix/                   # Helix 编辑器(config.toml + themes/)
├── fcitx5/                   # fcitx5 输入法(config、profile、conf/*.conf)
├── i3/                       # i3 窗口管理器配置
├── sway/                     # Sway 窗口管理器配置
├── waybar/                   # Waybar 状态栏(config + style.css)
├── scripts/                  # 独立脚本
│   ├── agent-float-toggle.sh   # sway Alt+G 漂浮 agent 聊天窗(仅 Linux)
│   └── obsidian-gdrive-sync.sh # Obsidian vault ↔ Google Drive 双向同步(rclone bisync)
└── systemd/user/             # systemd 用户单元
    └── obsidian-sync.{service,timer}  # 定时跑上面的同步脚本
```

---

## 安装的内容

### macOS(Homebrew)

**Brew formulae:** `stow fish neovim helix fzf eza fd bat zoxide thefuck lazygit ripgrep jq gh git asdf rustup-init btop`

**Brew casks:** `alacritty ghostty raycast visual-studio-code iterm2 font-fira-code-nerd-font`

**Fish 插件(经 Fisher):** `jorgebucaran/fisher`、`PatrickF1/fzf.fish`、`jorgebucaran/fish-git-prompt`、`jethrokuan/z`、`edc/bass`

**Neovim 插件(经 lazy.nvim):** 见 [`nvim/lazy-lock.json`](nvim/lazy-lock.json) 锁定的所有插件(blink.cmp、fff、catppuccin、nvim-treesitter、conform.nvim、mason.nvim、LSP servers、octo.nvim 等)。

### Linux(Arch / Debian / Fedora)

**包:** 与 macOS 列表基本相同,去掉 `asdf rustup-init`,按发行版加入 `dunst wl-clipboard xclip ttf-firacode-nerd thunar thunar-archive-plugin thunar-volman`(Arch 还含 `alacritty ghostty`)。Rust 工具链经 `rustup` 脚本安装,Debian 上 `fd` 软链自 `fdfind`、`eza` 从 GitHub 下载二进制。以 [`install.sh`](install.sh) 为准。

---

## 手动安装(分步)

如需精细控制或调试,按顺序执行以下命令。

### 1. 系统包

**macOS:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install stow fish neovim helix fzf eza fd bat zoxide thefuck lazygit ripgrep jq gh git asdf rustup-init btop
brew install --cask alacritty ghostty raycast visual-studio-code iterm2 font-fira-code-nerd-font
```

**Arch Linux:**

```bash
sudo pacman -S --needed stow fish neovim helix fzf eza fd bat zoxide thefuck lazygit ripgrep jq github-cli git btop alacritty ghostty dunst wl-clipboard xclip ttf-firacode-nerd thunar thunar-archive-plugin thunar-volman
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

**Debian / Ubuntu:**

```bash
sudo apt update
sudo apt install -y stow neovim fzf fd-find bat zoxide ripgrep jq gh git btop alacritty
sudo add-apt-repository -y ppa:fish-shell/release-3 && sudo apt update && sudo apt install -y fish
# fd 在 ubuntu 仓库里叫 fdfind
sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
# eza:从 GitHub release 下载
curl -sL https://github.com/eza-community/eza/releases/latest/download/eza-x86_64-unknown-linux-gnu.tar.gz \
  | sudo tar -xz -C /usr/local/bin eza
```

**Fedora:** `sudo dnf install -y stow fish neovim helix fzf eza fd bat zoxide ripgrep jq gh git btop`,Rust 同上。

### 2. Oh My Tmux!

```bash
git clone --depth 1 https://github.com/gpakosz/.tmux.git ~/.tmux
ln -sf .tmux/.tmux.conf ~/.tmux.conf
```

### 3. 软链接 dotfiles

```bash
cd ~/works/dotfiles
mkdir -p ~/.config
for pkg in fish nvim helix alacritty ghostty fcitx5 i3 sway waybar; do
    mkdir -p ~/.config/$pkg
    stow --restow --target=$HOME/.config/$pkg $pkg
done
```

### 4. Fish 插件

```bash
# 写入插件列表
cat > ~/.config/fish/fish_plugins <<'EOF'
PatrickF1/fzf.fish
jorgebucaran/fish-git-prompt
jethrokuan/z
edc/bass
EOF

# 安装 fisher 自身 + 上述插件
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"
```

### 5. Neovim 插件

首次打开 `nvim` 即可,`lazy.nvim` 会自动检测 `lua/plugins/` 下所有插件并安装。
也可手动同步:

```bash
nvim --headless "+Lazy! sync" +qa
```

### 6. 代理 / 输入法环境变量(可选)

`install.sh` 会生成 `~/.config/fish/conf.d/_99_dotfiles_env.fish`,默认是注释状态。
按需取消注释,例如启用代理:

```fish
set -gx http_proxy http://127.0.0.1:7897
set -gx https_proxy http://127.0.0.1:7897
set -gx all_proxy socks5://127.0.0.1:7897
```

Linux 上 fcitx 输入法变量会在文件里自动启用(由 `install.sh` 写入)。

---

## 附加组件

### Obsidian ↔ Google Drive 同步(仅 Linux)

前提:已配置 rclone remote `gdrive`。仓库需位于 `~/dotfiles`(systemd 单元用绝对路径)。

```bash
mkdir -p ~/.config/systemd/user
ln -s ~/dotfiles/systemd/user/obsidian-sync.service ~/.config/systemd/user/
ln -s ~/dotfiles/systemd/user/obsidian-sync.timer   ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now obsidian-sync.timer
```

日志在 `~/.local/state/obsidian-sync.log`。批量整理 vault 前先停 timer,操作顺序见 `scripts/obsidian-gdrive-sync.sh` 头部注释。

### Agent 漂浮窗(仅 Linux / sway)

`sway/config` 里 `Alt+G` 绑定 `scripts/agent-float-toggle.sh`:未启动则拉起 `pi`,已启动则在 scratchpad 显示/隐藏。脚本路径为绝对路径,仓库位置不同需自行调整。

### 机密文件(不入库)

`fish/conf.d/local.fish` 已加入 `.gitignore`:私钥、API token 等真实值只存在本机。
新机器上复制 `local.fish.example` 为 `local.fish` 并填入真实值;sway 的
voice-type 令牌同样从这里导出(环境变量)。

---

## 平台差异

| 组件 | macOS | Linux |
|---|---|---|
| 包管理器 | Homebrew | pacman / apt / dnf |
| 窗口管理器 | Raycast | i3 / Sway |
| 状态栏 | macOS 菜单栏 | Waybar |
| 终端 | Alacritty / Ghostty | Alacritty / Ghostty(Arch) |
| Fish 路径 | `/opt/homebrew/bin/fish`(arm64) | `/usr/bin/fish` |
| Rust | `rustup-init`(brew) | `rustup`(脚本) |
| 附加脚本 | — | agent 漂浮窗、Obsidian 同步 |

`config.fish` 用 `uname -s` 自动分支,共用一份配置。

---

## 验证安装

```bash
# 检查版本
fish --version
nvim --version | head -1
alacritty --version
ghostty +version
hx --version
stow --version

# 关键命令应存在
command -v fzf eza fd bat zoxide lazygit gh

# 重启 fish
exec fish

# neovim 插件状态
nvim +":Lazy" +qa

# LSP server
nvim +":Mason" +qa
```

---

## 卸载

```bash
cd ~/works/dotfiles
for pkg in fish nvim helix alacritty ghostty fcitx5 i3 sway waybar; do
    stow --delete --target=$HOME/.config/$pkg $pkg
done

# Obsidian 同步(Linux)
systemctl --user disable --now obsidian-sync.timer
rm ~/.config/systemd/user/obsidian-sync.{service,timer}
```

系统包用对应包管理器卸载:`brew uninstall <pkg>` / `sudo pacman -Rns <pkg>` / `sudo apt remove <pkg>`。

---

## 故障排查

- **stow 报错 `existing target is not a symlink`** — 目标目录里已有同名文件,先 `stow --delete` 或手动备份后删除。
- **fisher 找不到** — Fisher 4 改用 `fisher.fish` 单独脚本;仓库已 vendored 在 `fish/functions/`,`install.sh` 会自动处理。
- **nvim 插件装不上** — 检查 `git` / 网络 / 代理;`nvim +":Lazy clean" +":Lazy install" +qa` 重试。
- **alacritty 字体方块** — 确认 `font-fira-code-nerd-font` 已安装(参见各平台安装命令)。
- **Obsidian 同步失败** — 看 `~/.local/state/obsidian-sync.log`;授权过期则 `rclone config reconnect gdrive:`;基线损坏用 `obsidian-gdrive-sync.sh --resync`。
