#!/usr/bin/env bash
set -euo pipefail

# Hyprsunset toggle（夜间模式开关）
# 阶段一：仅手动切换，无定时计划。
# 图标：
# - 关闭：亮太阳
# - 开启：优先日落图标，缺字体时退回蓝色太阳
#
# 可用环境变量自定义：
#   HYPRSUNSET_TEMP      目标色温，默认 4500 (K)
#   HYPRSUNSET_ICON_MODE 图标模式 sunset|blue（默认 sunset）

STATE_FILE="$HOME/.cache/.hyprsunset_state"
TARGET_TEMP="${HYPRSUNSET_TEMP:-4500}"
ICON_MODE="${HYPRSUNSET_ICON_MODE:-sunset}"

ensure_state() {
  [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"
}

# Render icons using pango markup to allow colorization
# status 子命令输出 JSON（text/class/tooltip），供面板小部件渲染
icon_off() {
  # universally available sun symbol
  # 通用的太阳字符，任何字体都有
  printf "☀"
}

icon_on() {
  case "$ICON_MODE" in
    sunset)
      # sunset emoji (falls back to tofu if no emoji font)
      # 日落 emoji（缺 emoji 字体时会显示为方块）
      printf "🌇"
      ;;
    blue)
      # no color in text; rely on CSS .on to style if desired
      # 文本本身不带颜色，着色交给面板按 class 处理
      printf "☀"
      ;;
    *)
      printf "☀"
      ;;
  esac
}

cmd_toggle() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  # Always stop any running hyprsunset first to avoid CTM manager conflicts
  # 先杀掉在跑的 hyprsunset：色温映射（CTM）全局唯一，双实例会互相冲突
  if pgrep -x hyprsunset >/dev/null 2>&1; then
    pkill -x hyprsunset || true
    # give it a moment to release the CTM manager
    # 稍候片刻等它释放 CTM
    sleep 0.2
  fi

if [[ "$state" == "on" ]]; then
    # Turning OFF: set identity and exit
    # 关闭：以 -i（恒等色温）短暂启动再结束，让屏幕回到原生色温
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -i >/dev/null 2>&1 &
      # if hyprsunset persists, stop it shortly after applying identity
      # 恒等参数生效后立刻结束进程
      sleep 0.3 && pkill -x hyprsunset || true
    fi
    echo off > "$STATE_FILE"
    notify-send -u low "夜间模式：已关闭" || true
  else
    # Turning ON: start hyprsunset at target temp in background
    # 开启：后台以目标色温启动 hyprsunset 常驻
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    fi
    echo on > "$STATE_FILE"
    notify-send -u low "夜间模式：已开启" "${TARGET_TEMP}K 色温" || true
  fi
}

cmd_status() {
  ensure_state
  # Prefer live process detection; fall back to state file
  # 优先以进程是否存活为准（防止状态文件与实际不一致），文件仅作后备
  if pgrep -x hyprsunset >/dev/null 2>&1; then
    onoff="on"
  else
    onoff="$(cat "$STATE_FILE" || echo off)"
  fi

  if [[ "$onoff" == "on" ]]; then
    txt="<span size='18pt'>$(icon_on)</span>"
    cls="on"
    tip="Night light on @ ${TARGET_TEMP}K"
  else
    txt="<span size='16pt'>$(icon_off)</span>"
    cls="off"
    tip="Night light off"
  fi
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$txt" "$cls" "$tip"
}

cmd_init() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  if [[ "$state" == "on" ]]; then
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    fi
  fi
}

case "${1:-}" in
  toggle) cmd_toggle ;;
  status) cmd_status ;;
  init) cmd_init ;;
  *) echo "usage: $0 [toggle|status|init]" >&2; exit 2 ;;
 esac
