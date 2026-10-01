#!/usr/bin/env bash
# 按窗口记忆键盘布局（Tak0's Per-Window Switch）
# 每个窗口地址对应一份布局记录（~/.cache/kb_layout_per_window）：
# 切换时只对当前窗口生效并写入记录，焦点移动时自动恢复该窗口的布局，
# 实现按窗口而非全局的布局切换，与 KeyboardLayout.sh 的全局切换互补。

# This is for changing kb_layouts. Set kb_layouts in
# 布局列表从 Hyprland 运行时读取（见下方 LAYOUTS）

MAP_FILE="$HOME/.cache/kb_layout_per_window"
ICON="input-keyboard"
SCRIPT_NAME="$(basename "$0")"
LISTENER_PIDFILE="$HOME/.cache/kb_layout_per_window.listener.pid"

# Ensure map file exists
# 确保布局记录文件存在（touch 幂等）
touch "$MAP_FILE"

# 从 Hyprland 运行时读取已配置的键盘布局列表。
# （原脚本解析 configs/SystemSettings.conf，该文件已迁移为 lua/layout.lua，
#   这里改用 hyprctl 读取运行时值，与 KeyboardLayout.sh 的做法保持一致。）
LAYOUTS="$(hyprctl getoption input:kb_layout 2>/dev/null | awk 'NR==1{print $2}')"
kb_layouts=(${LAYOUTS//,/ })
count=${#kb_layouts[@]}
if [[ $count -eq 0 ]]; then
  echo "Error: cannot read kb_layout from Hyprland" >&2
  exit 1
fi

# Get current active window ID
# 取当前活动窗口地址（activewindow -j 的 address 字段）
get_win() {
  hyprctl activewindow -j | jq -r '.address // .id'
}

# Get available keyboards
# 列出所有键盘设备
get_keyboards() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

# Save window-specific layout
# 保存窗口专属布局：先删掉该窗口旧记录再追加，避免重复条目
save_map() {
  local W=$1 L=$2
  grep -v "^${W}:" "$MAP_FILE" >"$MAP_FILE.tmp"
  echo "${W}:${L}" >>"$MAP_FILE.tmp"
  mv "$MAP_FILE.tmp" "$MAP_FILE"
}

# Load layout for window (fallback to default)
# 读取窗口布局；无记录时回退到列表里的第一个布局
load_map() {
  local W=$1
  local E
  E=$(grep "^${W}:" "$MAP_FILE")
  [[ -n "$E" ]] && echo "${E#*:}" || echo "${kb_layouts[0]}"
}

# Switch layout for all keyboards to layout index
# 把所有键盘切到指定布局索引（单窗口记忆需要动物理键盘布局）
do_switch() {
  local IDX=$1
  for kb in $(get_keyboards); do
    hyprctl switchxkblayout "$kb" "$IDX" 2>/dev/null
  done
}

# Toggle layout for current window only
# 只针对当前窗口切到下一个布局，并把结果写入记录
cmd_toggle() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local CUR=$(load_map "$W")
  local i NEXT
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$CUR" ]]; then
      i=$idx
      break
    fi
  done
  NEXT=$(((i + 1) % count))
  do_switch "$NEXT"
  save_map "$W" "${kb_layouts[NEXT]}"
  notify-send -u low -i "$ICON" "kb_layout: ${kb_layouts[NEXT]}"
}

# Restore layout on focus
# 焦点变化时：把布局切回该窗口记录的值（无记录则回退默认）
cmd_restore() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local LAY=$(load_map "$W")
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$LAY" ]]; then
      do_switch "$idx"
      break
    fi
  done
}

# Listen to focus events and restore window-specific layouts
# 监听 Hyprland socket2 事件流：遇 activewindow（焦点变化）即恢复布局
subscribe() {
  local SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [[ -S "$SOCKET2" ]] || {
    echo "Error: Hyprland socket not found." >&2
    return 1
  }

  socat -u UNIX-CONNECT:"$SOCKET2" - | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

# Ensure only one listener
# 保证只有一个监听进程：PID 文件存在且进程存活则跳过
start_listener_once() {
  if [[ -f "$LISTENER_PIDFILE" ]]; then
    local existing_pid
    existing_pid=$(cat "$LISTENER_PIDFILE" 2>/dev/null || true)
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
      return
    fi
  fi

  subscribe &
  echo $! >"$LISTENER_PIDFILE"
}

start_listener_once

# CLI
# 命令行入口：无参或 toggle 切换当前窗口布局
case "$1" in
toggle | "") cmd_toggle ;;
*)
  echo "Usage: $SCRIPT_NAME [toggle]" >&2
  exit 1
  ;;
esac
