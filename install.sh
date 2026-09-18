#!/usr/bin/env bash
# install.sh - 一键安装 dotfiles 仓库中的所有应用
# 用法:
#   ./install.sh                 # 完整安装(交互式询问)
#   ./install.sh --all           # 全自动安装
#   ./install.sh --no-stow       # 只装系统包,不软链接 dotfiles
#   ./install.sh --stow-only     # 只软链接 dotfiles,不装系统包
#
# 该脚本是幂等的:可以重复运行,不会破坏现有配置。
# 支持 macOS(brew) 和 Linux(arch/pacman;debian/ubuntu 自动 fallback 到 apt)。

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 仓库根目录(脚本所在目录)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# 参数解析
AUTO_ALL=0
NO_STOW=0
STOW_ONLY=0
for arg in "$@"; do
    case $arg in
        --all) AUTO_ALL=1 ;;
        --no-stow) NO_STOW=1 ;;
        --stow-only) STOW_ONLY=1 ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
    esac
done

# 平台检测
OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM=macos ;;
    Linux)  PLATFORM=linux ;;
    *)      echo -e "${RED}不支持的平台: $OS${NC}"; exit 1 ;;
esac

# Linux 发行版检测
if [ "$PLATFORM" = "linux" ]; then
    if command -v pacman >/dev/null 2>&1; then
        LINUX_DISTRO=arch
    elif command -v apt >/dev/null 2>&1; then
        LINUX_DISTRO=debian
    elif command -v dnf >/dev/null 2>&1; then
        LINUX_DISTRO=fedora
    else
        LINUX_DISTRO=unknown
    fi
fi

echo -e "${BLUE}==> 平台:${NC} $PLATFORM${LINUX_DISTRO:+ ($LINUX_DISTRO)}"

# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------
log()   { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}warn:${NC} $*"; }
err()   { echo -e "${RED}err:${NC} $*" >&2; }
have()  { command -v "$1" >/dev/null 2>&1; }

confirm() {
    # $1 = 提示文本;返回 0 表示继续
    if [ "$AUTO_ALL" = 1 ]; then return 0; fi
    read -rp "$1 [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ---------------------------------------------------------------------------
# 1. 系统包安装
# ---------------------------------------------------------------------------
install_macos_packages() {
    log "安装 macOS 应用(Homebrew)"

    # Homebrew
    if ! have brew; then
        log "安装 Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$($(brew --prefix)/bin/brew shellenv)"
    fi

    # CLI 工具
    local brews=(
        stow
        fish
        neovim
        helix
        fzf
        eza
        fd
        bat
        zoxide
        thefuck
        lazygit
        ripgrep
        jq
        gh
        git
        asdf
        rustup-init
        btop
    )
    log "安装 brew 包: ${brews[*]}"
    brew install --quiet "${brews[@]}" || warn "部分 brew 包安装失败,继续"

    # cask 应用
    local casks=(
        alacritty
        ghostty
        raycast
        visual-studio-code
        iterm2
    )
    log "安装 brew cask: ${casks[*]}"
    brew install --cask --quiet "${casks[@]}" || warn "部分 cask 安装失败,继续"

    # 字体(alacritty 用 FiraCode Nerd Font)
    log "安装 FiraCode Nerd Font"
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask --quiet font-fira-code-nerd-font || warn "字体安装失败"
}

install_linux_packages() {
    log "安装 Linux 应用"

    local pkgs=()
    case "$LINUX_DISTRO" in
        arch)
            pkgs=(stow fish neovim helix fzf eza fd bat zoxide thefuck lazygit ripgrep jq github-cli git btop alacritty ghostty dunst wl-clipboard xclip ttf-firacode-nerd thunar thunar-archive-plugin thunar-volman)
            log "使用 pacman 安装"
            # 先批量装;失败(例如某包依赖升级会破坏其它已装包,如 emacs vs tree-sitter)则逐个装,
            # 避免一个依赖冲突阻塞整批安装。
            if ! sudo pacman -S --needed --noconfirm "${pkgs[@]}"; then
                warn "批量安装失败,逐个重试"
                for p in "${pkgs[@]}"; do
                    sudo pacman -S --needed --noconfirm "$p" || warn "跳过 $p"
                done
            fi
            ;;
        debian)
            pkgs=(stow fish neovim fzf fd-find bat zoxide ripgrep jq gh git btop alacritty)
            log "使用 apt 安装"
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:fish-shell/release-3 || true
            sudo apt update
            if ! sudo apt install -y "${pkgs[@]}"; then
                warn "批量安装失败,逐个重试"
                for p in "${pkgs[@]}"; do
                    sudo apt install -y "$p" || warn "跳过 $p"
                done
            fi
            # ubuntu 上 fd 叫 fdfind
            if have fdfind && ! have fd; then
                sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
            fi
            # eza 不在默认源,直接下二进制
            if ! have eza; then
                log "下载 eza 二进制"
                local arch
                arch=$(uname -m)
                local ver="0.18.21"
                local url="https://github.com/eza-community/eza/releases/download/v${ver}/eza-${arch}-unknown-linux-gnu.tar.gz"
                sudo mkdir -p /usr/local/bin
                sudo curl -sL "$url" | sudo tar -xz -C /usr/local/bin eza || warn "eza 安装失败"
            fi
            ;;
        fedora)
            pkgs=(stow fish neovim helix fzf eza fd bat zoxide ripgrep jq gh git btop)
            log "使用 dnf 安装"
            if ! sudo dnf install -y "${pkgs[@]}"; then
                warn "批量安装失败,逐个重试"
                for p in "${pkgs[@]}"; do
                    sudo dnf install -y "$p" || warn "跳过 $p"
                done
            fi
            ;;
        *)
            err "未识别的 Linux 发行版,跳过包安装"
            return 1
            ;;
    esac

    # Rust
    if ! have cargo; then
        log "安装 Rust"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || warn "Rust 安装失败"
    fi

}

# ---------------------------------------------------------------------------
# 2. Stow 软链接 dotfiles
# ---------------------------------------------------------------------------
stow_packages() {
    log "使用 stow 软链接 dotfiles"

    if ! have stow; then
        err "stow 未安装,无法链接 dotfiles"
        return 1
    fi

    # 各包的 stow 目标
    declare -A targets=(
        [fish]="$HOME/.config/fish"
        [nvim]="$HOME/.config/nvim"
        [helix]="$HOME/.config/helix"
        [alacritty]="$HOME/.config/alacritty"
        [ghostty]="$HOME/.config/ghostty"
        [fcitx5]="$HOME/.config/fcitx5"
        [i3]="$HOME/.config/i3"
        [sway]="$HOME/.config/sway"
        [waybar]="$HOME/.config/waybar"
        [tmux]="$HOME"
    )

    for pkg in fish nvim helix alacritty ghostty fcitx5 i3 sway waybar tmux; do
        if [ -d "$pkg" ]; then
            local target="${targets[$pkg]}"
            log "stow $pkg -> $target"
            mkdir -p "$target"
            stow --restow --target="$target" "$pkg"
        else
            warn "$pkg 目录不存在,跳过"
        fi
    done
}

# ---------------------------------------------------------------------------
# 2b. Oh My Tmux!(上游克隆 + ~/.tmux.conf 软链;本地自定义由 stow 的 tmux 包提供)
# ---------------------------------------------------------------------------
install_oh_my_tmux() {
    log "安装 Oh My Tmux!"
    # 上游仓库克隆到家目录(幂等:已存在则跳过)
    if [ ! -d "$HOME/.tmux/.git" ]; then
        rm -rf "$HOME/.tmux"
        git clone --depth 1 https://github.com/gpakosz/.tmux.git "$HOME/.tmux" \
            || { warn "Oh My Tmux! 克隆失败"; return 1; }
    fi
    # ~/.tmux.conf 指向上游主配置;~/.tmux.conf.local 由 stow 软链接提供
    if [ ! -L "$HOME/.tmux.conf" ]; then
        ln -sf .tmux/.tmux.conf "$HOME/.tmux.conf"
    fi
}

# ---------------------------------------------------------------------------
# 3. Fish 插件
# ---------------------------------------------------------------------------
install_fish_plugins() {
    log "安装 Fish 插件"

    # Fisher:本仓库 fish/functions/fisher.fish 在 stow 后即为可用函数。
    # 若不可用则从官方脚本安装。
    # 注意:fisher 是 fish 函数而非 bash 命令,因此用 `fish -c "type -q fisher"` 检测,
    # 不要用 `have fisher`(在 bash 里永远为假,会误触发安装并与仓库自带文件冲突)。
    if ! fish -c "type -q fisher" 2>/dev/null; then
        log "安装 Fisher"
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" \
            || warn "Fisher 安装失败,跳过插件安装"
    fi

    # fish_plugins 文件是 fisher 的标准插件列表机制
    cat > "$HOME/.config/fish/fish_plugins" <<'EOF'
PatrickF1/fzf.fish
jorgebucaran/fish-git-prompt
jethrokuan/z
edc/bass
EOF

    # 本仓库已将插件文件直接内置(vendored)在 fish/functions 与 fish/conf.d 下,
    # stow 后这些文件就已就位并可正常使用。Fisher 4 不会覆盖已存在的文件,
    # 因此对已 vendored 的插件运行 `fisher update` 只会报 "conflicting files"。
    # 这里用 __z.fish(jethrokuan/z 的文件)作为 vendored 标记:
    #   - 已 vendored:插件已在位,跳过 fisher 重装,避免误导性报错。
    #   - 未 vendored:交给 fisher 正常安装(适合全新、非 vendored 的机器)。
    if [ -f "$HOME/.config/fish/functions/__z.fish" ]; then
        log "插件文件已随仓库就位(vendored),跳过 fisher 重装"
    else
        fish -c "fisher update" || warn "fisher 插件安装失败"
    fi
}

# ---------------------------------------------------------------------------
# 4. Neovim 插件
# ---------------------------------------------------------------------------
install_nvim_plugins() {
    log "安装 Neovim 插件(lazy.nvim 会自动拉取)"
    if have nvim; then
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "neovim 插件同步失败,首次打开 nvim 时会自动安装"
    else
        warn "nvim 未安装,跳过插件安装"
    fi
}

# ---------------------------------------------------------------------------
# 5. 代理 / fcitx / 输入法环境变量(可选)
# ---------------------------------------------------------------------------
write_env_extras() {
    local env_file="$HOME/.config/fish/conf.d/_99_dotfiles_env.fish"
    log "写入环境变量到 $env_file"
    mkdir -p "$(dirname "$env_file")"
    cat > "$env_file" <<'EOF'
# 由 install.sh 生成,可自由编辑
# 代理(取消注释启用)
# set -gx http_proxy http://127.0.0.1:7897
# set -gx https_proxy http://127.0.0.1:7897
# set -gx all_proxy socks5://127.0.0.1:7897

# 中文输入法(Linux)
if test (uname -s) = Linux
    set -gx QT_IM_MODULE fcitx
    set -gx XMODIFIERS @im=fcitx
    set -gx SDL_IM_MODULE fcitx
    set -gx GLFW_IM_MODULE ibus
end
EOF
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
main() {
    echo -e "${BLUE}==> 仓库:${NC} $REPO_ROOT"

    if [ "$STOW_ONLY" = 1 ]; then
        install_oh_my_tmux
        stow_packages
        install_fish_plugins
        install_nvim_plugins
        write_env_extras
        log "完成"
        exit 0
    fi

    if [ "$NO_STOW" != 1 ]; then
        if [ "$PLATFORM" = "macos" ]; then
            install_macos_packages
        else
            install_linux_packages
        fi
    fi

    install_oh_my_tmux
    stow_packages
    install_fish_plugins
    install_nvim_plugins
    write_env_extras

    # 默认文件管理器(Linux)
    if [ "$PLATFORM" = "linux" ] && have thunar && have xdg-mime; then
        xdg-mime default thunar.desktop inode/directory || true
    fi

    # Vicinae(Linux GUI 启动器)
    if [ "$PLATFORM" = "linux" ] && confirm "安装 Vicinae 启动器?"; then
        curl -fsSL https://vicinae.com/install.sh | bash || warn "Vicinae 安装失败"
    fi

    log "全部完成。重启 fish 即可生效:exec fish"
}

main "$@"
