if status is-login
    # 通用路径(两个平台都需要)
    fish_add_path -a -g "$HOME/.local/bin"
    fish_add_path -a -g "$HOME/bin"
    fish_add_path -a -g "$HOME/.cargo/bin"
    fish_add_path -a -g "$HOME/go/bin"

    # ====== macOS 专用 PATH ======
    if test (uname -s) = Darwin
        # 让 Node/npm 使用 macOS 维护的 CA 证书包
        set -gx NODE_EXTRA_CA_CERTS /etc/ssl/cert.pem
        set -gx HOMEBREW_NO_AUTO_UPDATE 1

        set arch (uname -m)
        if test $arch = arm64
            fish_add_path -a -g /opt/homebrew/bin/
        else
            fish_add_path -a -g /usr/local/bin/
        end

        if test -d "$HOME/works/flutter/flutter-bin/bin"
            fish_add_path -a -g "$HOME/works/flutter/flutter-bin/bin/"
        end

        # Java:优先独立 JDK,其次 Android Studio 自带 JBR
        set _java_home "$HOME/Library/Java/jdk-17.0.13+11/Contents/Home"
        if not test -d "$_java_home"
            set _java_home "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
        end
        if test -d "$_java_home"
            set -gx JAVA_HOME "$_java_home"
            fish_add_path -a -g "$JAVA_HOME/bin"
        end
        set --erase _java_home

        set _android_home "$HOME/Library/Android/sdk"
        if test -d "$_android_home"
            set -gx ANDROID_HOME "$_android_home"
            set -gx ANDROID_SDK_ROOT "$_android_home"
            fish_add_path -a -g "$ANDROID_HOME/platform-tools"
            fish_add_path -a -g "$ANDROID_HOME/cmdline-tools/latest/bin"
            fish_add_path -a -g "$ANDROID_HOME/emulator"
            if test -d "$ANDROID_HOME/build-tools"
                for d in $ANDROID_HOME/build-tools/*
                    fish_add_path -a -g "$d"
                end
            end
        end
        set --erase _android_home
    end

    # ====== Linux 专用 PATH ======
    if test (uname -s) = Linux
        fish_add_path -a -g /usr/local/bin
        if test -d "/home/linuxbrew/.linuxbrew/bin"
            fish_add_path -a -g "/home/linuxbrew/.linuxbrew/bin"
            fish_add_path -a -g "/home/linuxbrew/.linuxbrew/sbin"
        end
        if test -d /snap/bin
            fish_add_path -a -g /snap/bin
        end
        if test -d "$HOME/.local/share/flatpak/exports/bin"
            fish_add_path -a -g "$HOME/.local/share/flatpak/exports/bin"
        end
    end
end

if status is-interactive
    abbr -a g git
    abbr -a gst 'git status -sb'
    # crush 问号快捷查询:crush 仅在 macOS 经 Homebrew 安装,只在 macOS 定义,避免 Linux 上 ? 展开后 crush command not found
    if test (uname -s) = Darwin
        abbr -a ? _crush_query
    end
    abbr -a ck 'cd -'

    set -U fish_greeting ''
    set -gx EDITOR nvim
    set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'

    # bun(两平台都有)
    if test -d "$HOME/.bun"
        set --export BUN_INSTALL "$HOME/.bun"
        set --export PATH $BUN_INSTALL/bin $PATH
    end

    # thefuck(懒加载:仅首次按 f 时才加载 Python,shell 启动零开销)
    if command -q thefuck
        function f --description "修正上一条命令"
            functions --erase f
            thefuck --alias | source
            alias f=fuck
            f $argv
        end
    end
    bind -e \cl

    # fd / bat / eza 三个平台工具(两平台,优先 Linux 替代)
    if command -q fdfind
        alias fd fdfind
    else if command -q fd
        alias fd fd
    end
    if command -q bat
        alias cat "bat --paging=auto"
    end
    if command -q eza
        alias ls eza
        alias ll "eza -l"
        alias la "eza -la --git"
        alias tree "eza -T"
    end

    # zoxide(两平台)
    if command -q zoxide
        zoxide init fish | source
    end

    # ===== 平台分支:herd(仅 macOS) =====
    if test (uname -s) = Darwin
        and test -d "$HOME/.config/herd-lite/bin"
        fish_add_path -a -g "$HOME/.config/herd-lite/bin"
        set -gx PHP_INI_SCAN_DIR "$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
    end

    # 快捷重载配置
    function rt
        source ~/.config/fish/config.fish
    end
    alias vim=nvim
    alias vi=nvim

    # ===== cd 后自动 ls (仅交互式 shell,两平台都生效) =====
    # 注意:不要加 --git —— 那会在每次 cd 时同步跑一次 git status,
    # 大仓库/未跟踪文件多时会让 cd 卡住(需 Ctrl+C 才能继续)。
    function __auto_ls_after_cd --on-variable PWD
        if status is-interactive
            if command -v eza >/dev/null 2>&1
                eza -la --group-directories-first
            else
                ls -la
            end
        end
    end
end

# ===== 懒加载 fzf =====
function __lazy_fzf --on-event fish_prompt
    if command -q fzf
        fzf --fish | source
    end
    functions -e __lazy_fzf
end

# pnpm(两平台)
if test -d "$HOME/.local/share/pnpm"
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    if not string match -q -- $PNPM_HOME $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end
end

# Antigravity CLI(两平台)
if test -d "$HOME/.local/bin"
    if not contains "$HOME/.local/bin" $PATH
        set -gx PATH "$HOME/.local/bin" $PATH
    end
end

# ===== TTY1 自动启动 sway(仅 Linux) =====
# 放在 config.fish 最末尾:确保上面所有 conf.d + config 的环境(PATH/环境变量)
# 全部加载完再 exec sway,否则 sway 及其子进程(GUI app、直接 exec 的程序)
# 只能拿到残缺环境(原 conf.d/20_sway_linux.fish 会在 conf.d 中途截断启动)
if test (uname -s) = Linux
    set TTY1 (tty)
    [ "$TTY1" = "/dev/tty1" ] && exec sway
end
