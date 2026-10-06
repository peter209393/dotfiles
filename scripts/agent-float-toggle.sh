#!/bin/sh
# Alt+G: 显示/隐藏 agent 漂浮聊天窗口;未启动则拉起 pi
# 同时兼容 hyprland 与 sway;macOS 直接退出
[ "$(uname -s)" = Linux ] || exit 0

# 防止快速连按并发执行:窗口未 map 时会误判 absent,重复 spawn 多个 pi 卡死
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/agent-float-toggle.lock"
flock -n 9 || exit 0

PI=$HOME/.asdf/installs/nodejs/lts/bin/pi
AGENT_DIR=$HOME/works/ai/agent

spawn_agent() {
    mkdir -p "$AGENT_DIR"
    # foot server 未启动则先拉起(sway 会话没有自动启动;footclient 会一直阻塞等 server)
    if ! pgrep -x foot >/dev/null 2>&1; then
        foot --server >/dev/null 2>&1 &
    fi
    # 用登录 fish 包一层:完整加载用户 shell config(PATH/环境变量)后再 exec pi
    footclient --app-id agent-float --working-directory="$AGENT_DIR" \
        fish --login -c "exec $PI" >/dev/null 2>&1 &
}

# 等待窗口 map 完成(持锁期间连按直接退出,避免重复 spawn)
wait_mapped() {
    i=0
    while [ $i -lt 50 ]; do
        "$@" 2>/dev/null | grep -q agent-float && return 0
        sleep 0.1
        i=$((i+1))
    done
    return 1
}

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    # hyprland:窗口由 windowrule 固定进 special:agent,切换该工作区即显隐
    addr=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
cs=json.load(sys.stdin)
m=[c['address'] for c in cs if c.get('class')=='agent-float']
print(m[0] if m else '')
")
    if [ -n "$addr" ]; then
        hyprctl dispatch togglespecialworkspace agent >/dev/null
    else
        spawn_agent
        wait_mapped hyprctl clients -j
        hyprctl dispatch togglespecialworkspace agent >/dev/null
    fi
    exit 0
fi

if command -v swaymsg >/dev/null 2>&1; then
    state=$(swaymsg -t get_tree 2>/dev/null | python3 -c "
import json,sys
t=json.load(sys.stdin)
def find(n, scratch):
    if n.get('app_id')=='agent-float':
        return 'hidden' if scratch else 'visible'
    s = scratch or n.get('name') in ('__i3','__i3_scratch')
    for c in n.get('nodes',[])+n.get('floating_nodes',[]):
        r=find(c,s)
        if r: return r
    return None
print(find(t,False) or 'absent')
")
    case "$state" in
        visible) swaymsg '[app_id="agent-float"] move scratchpad' >/dev/null ;;
        hidden)  swaymsg '[app_id="agent-float"] scratchpad show' >/dev/null ;;
        absent)
            spawn_agent
            wait_mapped swaymsg -t get_tree
            ;;
    esac
fi
