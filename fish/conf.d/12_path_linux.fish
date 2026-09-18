# ===== Linux 专用 =====
# 触发条件:uname -s = Linux
# 内容:常见 Linux 包管理器路径、wayland/sway 工具
# 注意:这个仓库原版是 home 路径写成 /home/peter,这里改成 $HOME 适配多机器
if status is-login
    and test (uname -s) = Linux

    # 用户级 bin(常见于 ~/.local/bin,已经在 10_path_common 里加过)
    # 这里放 Linux 独有的:系统级 /usr/local/bin,以及 armbian/debian 常见路径
    fish_add_path -a -g "/usr/local/bin"

    # Linuxbrew(非 mac)
    if test -d "/home/linuxbrew/.linuxbrew/bin"
        fish_add_path -a -g "/home/linuxbrew/.linuxbrew/bin"
        fish_add_path -a -g "/home/linuxbrew/.linuxbrew/sbin"
    end

    # snap(部分发行版)
    if test -d "/snap/bin"
        fish_add_path -a -g "/snap/bin"
    end

    # Flatpak user
    if test -d "$HOME/.local/share/flatpak/exports/bin"
        fish_add_path -a -g "$HOME/.local/share/flatpak/exports/bin"
    end
end
