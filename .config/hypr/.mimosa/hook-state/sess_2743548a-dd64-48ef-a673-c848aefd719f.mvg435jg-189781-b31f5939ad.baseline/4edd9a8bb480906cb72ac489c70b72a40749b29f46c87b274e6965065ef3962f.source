#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# 用于切换键盘布局。布局列表在 lua/layout.lua 的 input.kb_layout 中配置。

notif_icon="input-keyboard"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# 忽略列表：命中这些模式的设备不参与布局切换（如蓝牙音箱的媒体键伪装成键盘）
# Refined ignore list with patterns or specific device names
ignore_patterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device 
  Name"
)

# Function to get keyboard names
# 列出所有键盘设备名（hyprctl -j + jq）
get_keyboard_names() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

# Function to check if a device matches any ignore pattern
# 判断设备名是否命中忽略列表
is_ignored() {
  local device_name=$1
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$device_name" == *"$pattern"* ]]; then
      return 0 # Device matches ignore pattern
    fi
  done
  return 1 # Device does not match any ignore pattern
}

# Function to get current layout info
# 读取第一台非忽略键盘的布局/变体映射表与活动索引。
# Stores values in layout_mapping, variant_mapping and layout_index
# 结果写入全局变量：layout_mapping（布局表）、variant_mapping（变体表）、layout_index（当前索引）
get_current_layout_info() {
  local found_kb=false

  # Read from the first non-ignored layout
  # 只取第一台非忽略设备（多键盘布局通常一致）
  while read -r name; do
    if ! is_ignored "$name"; then
      found_kb=true
      local layout_mapping_str=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).layout')
      IFS="," read -r -a layout_mapping <<<"$layout_mapping_str"

      local variant_mapping_str=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).variant')
      IFS="," read -r -a variant_mapping <<<"$variant_mapping_str"

      layout_index=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).active_layout_index')
      break
    fi
  done <<< "$(get_keyboard_names)"

  $found_kb && return 0
  return 1
}

# Function to change keyboard layout
# 对所有非忽略键盘执行切换；任何一台失败都置 error_found 并返回 1
change_layout() {
  local error_found=false

  while read -r name; do
    if is_ignored "$name"; then
      echo "Skipping ignored device: $name"
      continue
    fi

    echo "Switching layout for $name to $new_layout..."
    hyprctl switchxkblayout "$name" "$next_index"
    if [ $? -ne 0 ]; then
      echo "Error while switching layout for $name." >&2
      error_found=true
    fi
  done <<<"$(get_keyboard_names)"

  $error_found && return 1
  return 0
}


# Stores values in layout_mapping, variant_mapping and layout_index
# 主流程：先读当前布局（失败则报错退出），status 打印当前值，switch 计算下一个布局并切换+通知
if ! get_current_layout_info; then
  echo "Could not get current layout information." >&2
  echo "There might not be any keyboards available, \
    or some were unnecessarily set as ignored." >&2
  notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
  echo "Exiting $0 $@" >&2
  exit 1
fi

current_layout=${layout_mapping[$layout_index]}
current_variant=${variant_mapping[$layout_index]}

if [[ "$1" == "status" ]]; then
  echo "$current_layout${current_variant:+($current_variant)}"
elif [[ "$1" == "switch" ]]; then
  echo "Current layout: $current_layout($current_variant)"

  layout_count=${#layout_mapping[@]}
  echo "Number of layouts: $layout_count"

  next_index=$(( (layout_index + 1) % layout_count ))
  new_layout="${layout_mapping[$next_index]}"
  new_variant="${variant_mapping[$next_index]}"
  echo "Next layout: $new_layout"

  # Execute layout change and notify
  # 执行切换：成功则弹通知，失败则报错退出
  if ! change_layout; then
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
    echo "Layout change failed." >&2
    exit 1
  else
    notify-send -u low -i "$notif_icon" " kb_layout: $new_layout${new_variant:+($new_variant)}"
    echo "Layout change notification sent."
  fi
else
  echo "Usage: $0 {status|switch}"
fi
