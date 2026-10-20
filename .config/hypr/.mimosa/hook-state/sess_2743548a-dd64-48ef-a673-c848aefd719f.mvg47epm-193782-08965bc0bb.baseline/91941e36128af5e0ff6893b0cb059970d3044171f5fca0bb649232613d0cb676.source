#!/usr/bin/env bash
# Dropdown Terminal（下拉式临时终端）
# Usage: ./Dropdown.sh [-d] <terminal_command>
# Example: ./Dropdown.sh alacritty
#          ./Dropdown.sh -d alacritty (with debug output)
#          ./Dropdown.sh "alacritty --working-directory /home/user"

DEBUG=false
SPECIAL_WS="special:scratchpad"
ADDR_FILE="/tmp/dropdown_terminal_addr"

WIDTH_PERCENT=65
HEIGHT_PERCENT=65
Y_PERCENT=10

ANIMATION_DURATION=100
SLIDE_STEPS=5
SLIDE_DELAY=5

if [ "$1" = "-d" ]; then
  DEBUG=true
  shift
fi

TERMINAL_CMD="$1"

debug_echo() {
  if [ "$DEBUG" = true ]; then
    echo "$@"
  fi
}

if [ -z "$TERMINAL_CMD" ]; then
  echo "Missing terminal command. Usage: $0 [-d] <terminal_command>"
  echo "Examples:"
  echo "  $0 alacritty"
  echo "  $0 -d alacritty (with debug output)"
  echo "  $0 'alacritty --working-directory /home/user'"
  exit 1
fi

# 查询指定地址窗口的几何信息（返回 "x y 宽 高"）
get_window_geometry() {
  local addr="$1"
  hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"'
}

# 滑入动画：窗口从目标位置上方分步移动到位（步数 SLIDE_STEPS）
animate_slide_down() {
  local addr="$1"
  local target_x="$2"
  local target_y="$3"
  local width="$4"
  local height="$5"
  local start_y=$((target_y - height - 50))
  local step_y=$(((target_y - start_y) / SLIDE_STEPS))
  hyprctl dispatch movewindowpixel "exact $target_x $start_y,address:$addr" >/dev/null 2>&1
  sleep 0.05
  for i in $(seq 1 $SLIDE_STEPS); do
    local current_y=$((start_y + (step_y * i)))
    hyprctl dispatch movewindowpixel "exact $target_x $current_y,address:$addr" >/dev/null 2>&1
    sleep 0.03
  done
  hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$addr" >/dev/null 2>&1
}

# 滑出动画：窗口向屏幕上方移动直至完全离屏
animate_slide_up() {
  local addr="$1"
  local start_x="$2"
  local start_y="$3"
  local width="$4"
  local height="$5"
  local end_y=$((start_y - height - 50))
  for i in $(seq 1 $SLIDE_STEPS); do
    local current_y=$((start_y - (end_y / SLIDE_STEPS * i)))
    hyprctl dispatch movewindowpixel "exact $start_x $current_y,address:$addr" >/dev/null 2>&1
    sleep 0.03
  done
}

# 取焦点显示器的坐标、分辨率、缩放与名称
get_monitor_info() {
  hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height) \(.scale) \(.name)"'
}

# 计算下拉终端的位置与尺寸：按显示器逻辑分辨率取百分比（宽高 65%，距顶 10%）
# 输出 "x y 宽 高 显示器名"；取不到显示器时返回 800x600 的回退值
calculate_dropdown_position() {
  local monitor_info=$(get_monitor_info)
  if [ -z "$monitor_info" ]; then echo "100 100 800 600 fallback-monitor"; return 1; fi
  local mon_x=$(echo $monitor_info | cut -d' ' -f1)
  local mon_y=$(echo $monitor_info | cut -d' ' -f2)
  local mon_width=$(echo $monitor_info | cut -d' ' -f3)
  local mon_height=$(echo $monitor_info | cut -d' ' -f4)
  local mon_scale=$(echo $monitor_info | cut -d' ' -f5)
  local mon_name=$(echo $monitor_info | cut -d' ' -f6)
  local logical_w=$((mon_width * 100 / ${mon_scale%.*} ))
  local logical_h=$((mon_height * 100 / ${mon_scale%.*} ))
  [ -z "$logical_w" ] && logical_w=$mon_width
  [ -z "$logical_h" ] && logical_h=$mon_height
  local width=$((logical_w * WIDTH_PERCENT / 100))
  local height=$((logical_h * HEIGHT_PERCENT / 100))
  local y_offset=$((logical_h * Y_PERCENT / 100))
  local x_offset=$(((logical_w - width) / 2))
  echo $((mon_x + x_offset)) $((mon_y + y_offset)) $width $height "$mon_name"
}

CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# 从状态文件读取已记录的下拉终端地址 / 所在显示器
get_terminal_address() {
  if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then cut -d' ' -f1 "$ADDR_FILE"; fi
}

get_terminal_monitor() {  if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then cut -d' ' -f2- "$ADDR_FILE"; fi
}

# 已记录的窗口是否仍然存在
terminal_exists() {
  local addr=$(get_terminal_address)
  if [ -n "$addr" ]; then
    hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)' >/dev/null 2>&1
  else return 1; fi
}

# 窗口当前是否停靠在 scratchpad 特殊工作区（收起状态）
terminal_in_special() {
  local addr=$(get_terminal_address)
  if [ -n "$addr" ]; then
    hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and .workspace.name == "special:scratchpad")' >/dev/null 2>&1
  else return 1; fi
}

# 在 scratchpad 生成下拉终端：对比生成前后的窗口列表拿到新窗口地址，
# 记录地址与显示器后播放滑入动画
spawn_terminal() {
  local pos_info=$(calculate_dropdown_position)
  local target_x=$(echo $pos_info | cut -d' ' -f1)
  local target_y=$(echo $pos_info | cut -d' ' -f2)
  local width=$(echo $pos_info | cut -d' ' -f3)
  local height=$(echo $pos_info | cut -d' ' -f4)
  local monitor_name=$(echo $pos_info | cut -d' ' -f5)
  local windows_before=$(hyprctl clients -j)
  local count_before=$(echo "$windows_before" | jq 'length')
  hyprctl dispatch exec "[float; size $width $height; workspace special:scratchpad silent] $TERMINAL_CMD"
  sleep 0.1
  local windows_after=$(hyprctl clients -j)
  local count_after=$(echo "$windows_after" | jq 'length')
  local new_addr=""
  if [ "$count_after" -gt "$count_before" ]; then
    new_addr=$(comm -13 <(echo "$windows_before" | jq -r '.[].address' | sort) <(echo "$windows_after" | jq -r '.[].address' | sort) | head -1)
  fi
  if [ -z "$new_addr" ] || [ "$new_addr" = "null" ]; then
    new_addr=$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[-1] | .address')
  fi
  if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
    echo "$new_addr $monitor_name" >"$ADDR_FILE"
    sleep 0.2
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$new_addr"
    hyprctl dispatch pin "address:$new_addr"
    animate_slide_down "$new_addr" "$target_x" "$target_y" "$width" "$height"
    return 0
  fi
  return 1
}

# 主流程：窗口已存在 → 跨显示器归位后做显示/收起切换；不存在 → 新建
if terminal_exists; then
  TERMINAL_ADDR=$(get_terminal_address)
  focused_monitor=$(get_monitor_info | awk '{print $6}')
  dropdown_monitor=$(get_terminal_monitor)
  if [ "$focused_monitor" != "$dropdown_monitor" ]; then
    pos_info=$(calculate_dropdown_position)
    target_x=$(echo $pos_info | cut -d' ' -f1)
    target_y=$(echo $pos_info | cut -d' ' -f2)
    width=$(echo $pos_info | cut -d' ' -f3)
    height=$(echo $pos_info | cut -d' ' -f4)
    monitor_name=$(echo $pos_info | cut -d' ' -f5)
    hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$TERMINAL_ADDR"
    hyprctl dispatch resizewindowpixel "exact $width $height,address:$TERMINAL_ADDR"
    echo "$TERMINAL_ADDR $monitor_name" >"$ADDR_FILE"
  fi
  if terminal_in_special; then
    pos_info=$(calculate_dropdown_position)
    target_x=$(echo $pos_info | cut -d' ' -f1)
    target_y=$(echo $pos_info | cut -d' ' -f2)
    width=$(echo $pos_info | cut -d' ' -f3)
    height=$(echo $pos_info | cut -d' ' -f4)
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$TERMINAL_ADDR"
    hyprctl dispatch pin "address:$TERMINAL_ADDR"
    hyprctl dispatch resizewindowpixel "exact $width $height,address:$TERMINAL_ADDR"
    animate_slide_down "$TERMINAL_ADDR" "$target_x" "$target_y" "$width" "$height"
    hyprctl dispatch focuswindow "address:$TERMINAL_ADDR"
  else
    geometry=$(get_window_geometry "$TERMINAL_ADDR")
    if [ -n "$geometry" ]; then
      curr_x=$(echo $geometry | cut -d' ' -f1)
      curr_y=$(echo $geometry | cut -d' ' -f2)
      curr_width=$(echo $geometry | cut -d' ' -f3)
      curr_height=$(echo $geometry | cut -d' ' -f4)
      animate_slide_up "$TERMINAL_ADDR" "$curr_x" "$curr_y" "$curr_width" "$curr_height"
      sleep 0.1
      hyprctl dispatch pin "address:$TERMINAL_ADDR"
      hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$TERMINAL_ADDR"
    else
      hyprctl dispatch pin "address:$TERMINAL_ADDR"
      hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$TERMINAL_ADDR"
    fi
  fi
else
  if spawn_terminal; then
    TERMINAL_ADDR=$(get_terminal_address)
    if [ -n "$TERMINAL_ADDR" ]; then hyprctl dispatch focuswindow "address:$TERMINAL_ADDR"; fi
  fi
fi