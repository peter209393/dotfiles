#!/bin/sh
# Obsidian vault <-> Google Drive 双向同步(rclone bisync)
# 安装: 见 ../../readme 或 systemd/user/obsidian-sync.timer
# 用法:
#   obsidian-sync.sh          正常双向同步
#   obsidian-sync.sh --resync 以本地为准重建同步基线(本地丢失/首次)
#
# ⚠️ 大整理(批量删除/移动)后不要直接等 timer!rclone 的 --resync 会先把
#    云端文件合并回本地(不删云端多余),垃圾会被复活。正确顺序:
#    1. systemctl --user stop obsidian-sync.timer   # 先停
#    2. 整理本地 + git 提交留痕
#    3. rclone sync ~/Obsidian-Vault "gdrive:Learning_and_Research/Obsidian-Vault" \
#         --filter-from ~/.cache/obsidian-sync.filter   # 清理云端多余
#    4. systemctl --user start obsidian-sync.timer    # 再启(脚本会自动重建基线)
set -eu

VAULT="$HOME/Obsidian-Vault"
REMOTE="gdrive:Learning_and_Research/Obsidian-Vault"
LOG="$HOME/.local/state/obsidian-sync.log"

# 不参与同步的内容:
#  .git            两边是同一 GitHub 仓库的独立克隆,各自管理
#  node_modules    AI 工具依赖,体积大且机器相关
#  .smart-env      Smart Connections 插件的向量缓存(机器相关)
#  workspace.json  Obsidian 窗口布局(机器相关)
FILTER='- /.git/**
- /.opencode/node_modules/**
- /.smart-env/**
- /.trash/**
- /.obsidian/workspace.json*
- **/node_modules/**
'

mkdir -p "$(dirname "$LOG")"

# flock 防止定时任务重叠
exec 9>/tmp/obsidian-sync.lock
flock -n 9 || { echo "$(date '+%F %T') [skip] 已有同步在运行" >>"$LOG"; exit 0; }

# bisync 不支持进程替换,过滤规则落盘为真实文件
FILTER_FILE="$HOME/.cache/obsidian-sync.filter"
mkdir -p "$(dirname "$FILTER_FILE")"
printf '%s\n' "$FILTER" >"$FILTER_FILE"

echo "$(date '+%F %T') [start] bisync $VAULT <-> $REMOTE" >>"$LOG"

# 首次运行(无基线)自动 resync;之后正常双向
if ! rclone bisync "$VAULT" "$REMOTE" \
    --filters-file "$FILTER_FILE" \
    --conflict-resolve newer \
    --conflict-suffix "conflict-{DateOnly}" \
    --max-delete 25 \
    --log-file "$LOG" --log-level INFO 2>>"$LOG"; then
    # 基线丢失(比如长期未同步/单侧大变动)时自动重建
    echo "$(date '+%F %T') [resync] 重建同步基线(以本地为准)" >>"$LOG"
    rclone bisync "$VAULT" "$REMOTE" --resync \
        --filters-file "$FILTER_FILE" \
        --max-delete 25 \
        --log-file "$LOG" --log-level INFO 2>>"$LOG"
fi

echo "$(date '+%F %T') [done]" >>"$LOG"
