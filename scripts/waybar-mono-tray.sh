#!/bin/bash
# waybar 启动包装:先保证 SNI 单色代理抢到 watcher 名,再启动 waybar
# (托盘图标由应用直发位图,必须抢在 waybar 之前占用 watcher 才能重着色;
#  详见同目录 sni-mono-proxy.py 的头部注释)

marker=org.mono.SniWatcher
proxy=/home/peter/dotfiles/scripts/sni-mono-proxy.py

if ! busctl --user list 2>/dev/null | grep -q "$marker"; then
    setsid "$proxy" >/dev/null 2>&1 &
    # 最多等 2 秒;代理拿不到名(异常)也不阻塞 waybar 启动,只是托盘保持彩色
    for _ in $(seq 1 20); do
        busctl --user list 2>/dev/null | grep -q "$marker" && break
        sleep 0.1
    done
fi

exec waybar "$@"
