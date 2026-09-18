#!/bin/sh
# Alt+G: 显示/隐藏 agent 漂浮聊天窗口;未启动则拉起 pi
# 仅 Linux(sway)生效:macOS 无 sway,直接退出;
# Alt+G 绑定在 sway config 里,macOS 根本不加载 sway,天然不会注册快捷键
[ "$(uname -s)" = Linux ] || exit 0
command -v swaymsg >/dev/null 2>&1 || exit 0

# sway 环境的 PATH 可能不含 asdf(下次登录才修复),用绝对路径兜底
PI=$HOME/.asdf/installs/nodejs/lts/bin/pi
AGENT_DIR=$HOME/works/ai/agent

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
        mkdir -p "$AGENT_DIR"
        # 用登录 fish 包一层:完整加载用户 shell config(PATH/环境变量)后再 exec pi
        # 直接在脚本里后台拉起(不用 swaymsg exec,避开它的分词问题)
        alacritty --class agent-float --working-directory "$AGENT_DIR" \
            -e fish --login -c "exec $PI" >/dev/null 2>&1 &
        ;;
esac
