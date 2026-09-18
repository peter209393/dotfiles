# ===== Crush (Charm 终端 AI 助手) - 仅 macOS =====
# crush 经 Homebrew 安装:
#   Apple Silicon -> /opt/homebrew/bin/crush
#   Intel Mac     -> /usr/local/bin/crush
#
# 背景:11_path_macos.fish 只在 login shell 里把 Homebrew 路径加入 PATH。
#      从 GUI / 其它 shell 直接拉起的非 login 交互式 fish 里,PATH 上没有
#      Homebrew bin,于是 crush 报 "command not found" 无法运行。
#      这里在所有 macOS fish 里兜底确保 Homebrew bin 在 PATH 上,
#      crush 即可正常运行(fish_add_path 幂等,不会重复/乱序)。
# Linux 不经此路径安装 crush,跳过。
if test (uname -s) = Darwin
    set _crush_brew_bin
    switch (uname -m)
        case arm64
            set _crush_brew_bin /opt/homebrew/bin
        case '*'
            set _crush_brew_bin /usr/local/bin
    end
    if test -n "$_crush_brew_bin" -a -d "$_crush_brew_bin"
        fish_add_path -g "$_crush_brew_bin"
    end
    set --erase _crush_brew_bin
end
