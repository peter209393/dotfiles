# ===== Herd-Lite (PHP 开发环境) - 仅 macOS =====
# Linux 不用 herd,跳过
if test (uname -s) = Darwin
    if test -d "$HOME/.config/herd-lite/bin"
        fish_add_path -a -g "$HOME/.config/herd-lite/bin"
        set -gx PHP_INI_SCAN_DIR "$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
    end
end
