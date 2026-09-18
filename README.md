# dotfiles

[简体中文](readme.zh-CN.md) | **English**

Personal dotfiles for **Fish**, **Neovim**, **Ghostty**, **Alacritty**, **i3 / Sway / Waybar**, plus helper scripts for **Obsidian sync** and a **floating agent window**.

Works on **macOS** and **Linux** (Arch / Debian / Ubuntu / Fedora). One command sets up a blank machine.

> For details on each config, see [FEATURES.md](FEATURES.md). For the Neovim config, see [nvim/readme.md](nvim/readme.md).

---

## Quick Start

> Agent-friendly: clone the repo and run `./install.sh`.

```bash
git clone <your-repo-url> ~/works/dotfiles
cd ~/works/dotfiles
./install.sh           # interactive
./install.sh --all     # fully automatic, no prompts
```

The script does:

1. **System packages** — Homebrew on macOS; the distro package manager on Linux.
2. **Oh My Tmux!** — clones upstream into `~/.tmux` and symlinks `~/.tmux.conf`.
3. **Stow symlinks** — links `fish/ nvim/ helix/ alacritty/ ghostty/ fcitx5/ i3/ sway/ waybar/` into `~/.config/`.
4. **Fish plugins** — Fisher plus 4 plugins (written to `fish_plugins`; some plugin files are vendored in this repo).
5. **Neovim plugins** — lazy.nvim fetches them on first start.
6. **Env file** — `conf.d/_99_dotfiles_env.fish` (proxy / fcitx).
7. **Linux extras** — sets Thunar as the default file manager; optional Vicinae launcher.

### Options

| Option | What it does |
|---|---|
| `./install.sh` | Interactive install (default) |
| `./install.sh --all` | Fully automatic, skip all prompts |
| `./install.sh --stow-only` | Only symlink dotfiles, skip system packages |
| `./install.sh --no-stow` | Only install system packages, skip symlinking |
| `./install.sh -h` | Show help |

---

## Repository Layout

```
dotfiles/
├── install.sh                # One-shot installer (entry point)
├── README.md                 # This file (default, English)
├── readme.zh-CN.md           # Chinese readme
├── FEATURES.md               # Feature-by-feature guide for every config
├── alacritty/                # alacritty.toml + themes/ (colour schemes)
├── ghostty/                  # ghostty/config
├── fish/                     # Fish shell config
│   ├── config.fish
│   ├── fish_variables
│   ├── completions/          # completions for bun / copilot / fisher / fzf, etc.
│   ├── conf.d/               # modular configs (numbered: OS detect, PATH, toolchains, fzf, key bindings…)
│   └── functions/            # custom functions + vendored plugins (git aliases, bass, fzf wrappers, etc.)
├── nvim/                     # Neovim config (lazy.nvim)
│   ├── init.lua
│   ├── lazy-lock.json        # plugin version lock
│   └── lua/{config,plugins}/
├── helix/                   # Helix editor (config.toml + themes/)
├── fcitx5/                   # fcitx5 input method (config, profile, conf/*.conf)
├── i3/                       # i3 window manager config
├── sway/                     # Sway window manager config
├── waybar/                   # Waybar status bar (config + style.css)
├── scripts/                  # standalone scripts
│   ├── agent-float-toggle.sh   # sway Alt+G floating agent chat window (Linux only)
│   └── obsidian-gdrive-sync.sh # Obsidian vault <-> Google Drive two-way sync (rclone bisync)
└── systemd/user/             # systemd user units
    └── obsidian-sync.{service,timer}  # runs the sync script on a schedule
```

---

## What Gets Installed

### macOS (Homebrew)

**Brew formulae:** `stow fish neovim helix fzf eza fd bat zoxide thefuck lazygit ripgrep jq gh git asdf rustup-init btop`

**Brew casks:** `alacritty ghostty raycast visual-studio-code iterm2 font-fira-code-nerd-font`

**Fish plugins (via Fisher):** `jorgebucaran/fisher`, `PatrickF1/fzf.fish`, `jorgebucaran/fish-git-prompt`, `jethrokuan/z`, `edc/bass`

**Neovim plugins (via lazy.nvim):** every plugin pinned in [`nvim/lazy-lock.json`](nvim/lazy-lock.json) (blink.cmp, fff, catppuccin, nvim-treesitter, conform.nvim, mason.nvim, LSP servers, octo.nvim, and more).

### Linux (Arch / Debian / Fedora)

**Packages:** almost the same list as macOS, minus `asdf rustup-init`; the distro adds `dunst wl-clipboard xclip ttf-firacode-nerd thunar thunar-archive-plugin thunar-volman` (Arch also installs `alacritty ghostty`). Rust comes from the `rustup` script; on Debian, `fd` is symlinked from `fdfind` and `eza` is downloaded from GitHub releases. [`install.sh`](install.sh) is the source of truth.

---

## Manual Install (Step by Step)

For fine control or debugging, run the steps in order.

### 1. System packages

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
# fd is called fdfind in the ubuntu repos
sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
# eza: download from a GitHub release
curl -sL https://github.com/eza-community/eza/releases/latest/download/eza-x86_64-unknown-linux-gnu.tar.gz \
  | sudo tar -xz -C /usr/local/bin eza
```

**Fedora:** `sudo dnf install -y stow fish neovim helix fzf eza fd bat zoxide ripgrep jq gh git btop`; install Rust as above.

### 2. Oh My Tmux!

```bash
git clone --depth 1 https://github.com/gpakosz/.tmux.git ~/.tmux
ln -sf .tmux/.tmux.conf ~/.tmux.conf
```

### 3. Symlink the dotfiles

```bash
cd ~/works/dotfiles
mkdir -p ~/.config
for pkg in fish nvim helix alacritty ghostty fcitx5 i3 sway waybar; do
    mkdir -p ~/.config/$pkg
    stow --restow --target=$HOME/.config/$pkg $pkg
done
```

### 4. Fish plugins

```bash
# Write the plugin list
cat > ~/.config/fish/fish_plugins <<'EOF'
PatrickF1/fzf.fish
jorgebucaran/fish-git-prompt
jethrokuan/z
edc/bass
EOF

# Install fisher itself plus the plugins above
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"
```

### 5. Neovim plugins

Open `nvim` once; `lazy.nvim` detects everything under `lua/plugins/` and installs it.
To sync manually:

```bash
nvim --headless "+Lazy! sync" +qa
```

### 6. Proxy / input-method env vars (optional)

`install.sh` writes `~/.config/fish/conf.d/_99_dotfiles_env.fish` with everything commented out.
Uncomment as needed, for example to enable a proxy:

```fish
set -gx http_proxy http://127.0.0.1:7897
set -gx https_proxy http://127.0.0.1:7897
set -gx all_proxy socks5://127.0.0.1:7897
```

On Linux, the fcitx input-method vars in that file are enabled automatically (written by `install.sh`).

---

## Extras

### Obsidian <-> Google Drive sync (Linux only)

Prerequisite: an rclone remote named `gdrive`. The repo must live at `~/dotfiles` (the systemd unit uses an absolute path).

```bash
mkdir -p ~/.config/systemd/user
ln -s ~/dotfiles/systemd/user/obsidian-sync.service ~/.config/systemd/user/
ln -s ~/dotfiles/systemd/user/obsidian-sync.timer   ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now obsidian-sync.timer
```

Logs go to `~/.local/state/obsidian-sync.log`. Before a big vault reorganization, stop the timer first; see the header comments in `scripts/obsidian-gdrive-sync.sh` for the correct order.

### Floating agent window (Linux / sway only)

`sway/config` binds `Alt+G` to `scripts/agent-float-toggle.sh`: it starts `pi` if not running, and shows/hides it in a scratchpad otherwise. The script path is absolute; adjust it if the repo lives elsewhere.

### Secrets (not tracked)

`fish/conf.d/local.fish` is gitignored: real private keys and API tokens stay on
the machine only. On a new machine, copy `local.fish.example` to `local.fish`
and fill in real values; the sway voice-type tokens are exported from here too
(environment variables).

---

## Platform Differences

| Component | macOS | Linux |
|---|---|---|
| Package manager | Homebrew | pacman / apt / dnf |
| Window management | Raycast | i3 / Sway |
| Status bar | macOS menu bar | Waybar |
| Terminal | Alacritty / Ghostty | Alacritty / Ghostty (Arch) |
| Fish path | `/opt/homebrew/bin/fish` (arm64) | `/usr/bin/fish` |
| Rust | `rustup-init` (brew) | `rustup` (script) |
| Extra scripts | — | agent float window, Obsidian sync |

`config.fish` branches on `uname -s`, so one config serves both platforms.

---

## Verify the Install

```bash
# Check versions
fish --version
nvim --version | head -1
alacritty --version
ghostty +version
hx --version
stow --version

# Key commands should exist
command -v fzf eza fd bat zoxide lazygit gh

# Restart fish
exec fish

# Neovim plugin status
nvim +":Lazy" +qa

# LSP servers
nvim +":Mason" +qa
```

---

## Uninstall

```bash
cd ~/works/dotfiles
for pkg in fish nvim helix alacritty ghostty fcitx5 i3 sway waybar; do
    stow --delete --target=$HOME/.config/$pkg $pkg
done

# Obsidian sync (Linux)
systemctl --user disable --now obsidian-sync.timer
rm ~/.config/systemd/user/obsidian-sync.{service,timer}
```

Remove system packages with the matching manager: `brew uninstall <pkg>` / `sudo pacman -Rns <pkg>` / `sudo apt remove <pkg>`.

---

## Troubleshooting

- **stow fails with `existing target is not a symlink`** — a file with the same name exists in the target dir. Run `stow --delete` first, or back it up and remove it.
- **fisher not found** — Fisher 4 ships as a standalone `fisher.fish` script; this repo vendors it under `fish/functions/`, and `install.sh` handles it automatically.
- **Neovim plugins fail to install** — check `git`, the network, and the proxy; retry with `nvim +":Lazy clean" +":Lazy install" +qa`.
- **Alacritty shows squares for glyphs** — make sure `font-fira-code-nerd-font` is installed (see the per-platform install commands).
- **Obsidian sync fails** — check `~/.local/state/obsidian-sync.log`; if the token expired, run `rclone config reconnect gdrive:`; if the baseline is broken, run `obsidian-gdrive-sync.sh --resync`.
