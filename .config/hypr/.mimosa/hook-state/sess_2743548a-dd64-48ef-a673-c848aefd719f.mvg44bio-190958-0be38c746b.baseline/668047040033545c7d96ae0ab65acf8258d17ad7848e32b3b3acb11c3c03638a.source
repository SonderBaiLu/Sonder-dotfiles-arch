#!/usr/bin/env bash
# ==============================================================================
# 模块名称: Hyprland 截图调度服务 (ScreenShot.sh)
# 架构层级: 系统基础设施层 / 外部事件执行器
# 职责说明: 负责 Wayland 图形环境下的画面捕获、动态时间戳命名持久化、剪贴板注入及交互通知
# 外部依赖: grim, slurp, jq, wl-copy, notify-send, swappy
# ==============================================================================

set -o pipefail

# ------------------------------------------------------------------------------
# 1. 基础环境与持久化路径解析
# ------------------------------------------------------------------------------
# 解析系统 XDG 截图目录，若未配置则回退至用户家目录
TARGET_DIR="/home/qicat/Pictures/Screenshots"

# 确保目标持久化目录存在
[[ -d "${TARGET_DIR}" ]] || mkdir -p "${TARGET_DIR}"

# 通知图标使用 freedesktop 标准图标名，随图标主题（Papirus）自动匹配

# ------------------------------------------------------------------------------
# 2. 动态时间戳与命名生成器
# ------------------------------------------------------------------------------
# 动态获取时间戳函数（按执行瞬间生成，避免延时截图使用启动时间；规避 %b 本地化中文月份干扰）
get_timestamp() {
  date "+%Y-%m-%d_%H-%M-%S"
}

# ------------------------------------------------------------------------------
# 3. 桌面通知通信协议定义
# ------------------------------------------------------------------------------
notify_cmd_base="notify-send -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify"
notify_cmd_shot="${notify_cmd_base} -i camera-photo"
notify_cmd_shot_win="${notify_cmd_base} -i camera-photo"
notify_cmd_NOT="notify-send -u low -i dialog-error"

# 通知与用户交互响应处理函数
notify_view() {
  local mode="$1"
  local target_path="$2"
  local extra_info="$3"

  case "${mode}" in
  active)
    if [[ -e "${target_path}" ]]; then
      local resp
      resp=$(timeout 5 ${notify_cmd_shot_win} "窗口截图已保存:" " ${extra_info}")
      case "${resp}" in
      action1) xdg-open "${target_path}" & ;;
      action2) rm -f "${target_path}" & ;;
      esac
    else
      ${notify_cmd_NOT} "窗口截图失败:" " ${extra_info} 未能保存"
    fi
    ;;

  swappy)
    local resp
    resp=$(${notify_cmd_shot} "截图捕获完成" "已写入剪贴板，可进入编辑器调整")
    case "${resp}" in
    action1)
      swappy -f "${target_path}"
      rm -f "${target_path}"
      ;;
    action2)
      rm -f "${target_path}"
      ;;
    esac
    ;;

  *)
    if [[ -e "${target_path}" ]]; then
      local resp
      resp=$(timeout 5 ${notify_cmd_shot} "截图已保存" "文件: $(basename "${target_path}")")
      case "${resp}" in
      action1) xdg-open "${target_path}" & ;;
      action2) rm -f "${target_path}" & ;;
      esac
    else
      ${notify_cmd_NOT} "截图失败" "未能生成图像文件"
    fi
    ;;
  esac
}

# 倒计时通知派发
countdown() {
  local total_sec="$1"
  for sec in $(seq "${total_sec}" -1 1); do
    notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "camera-photo" "正在准备截图" "倒计时: ${sec} 秒"
    sleep 1
  done
}

# ------------------------------------------------------------------------------
# 4. 捕获动作实现
# ------------------------------------------------------------------------------

# 立即捕获全屏
shotnow() {
  local current_time file target_path
  current_time=$(get_timestamp)
  file="Screenshot_${current_time}.png"
  target_path="${TARGET_DIR}/${file}"

  grim - | tee "${target_path}" | wl-copy
  sleep 1
  notify_view "default" "${target_path}"
}

# 延迟 5 秒捕获
shot5() {
  countdown 5
  sleep 1
  local current_time file target_path
  current_time=$(get_timestamp)
  file="Screenshot_${current_time}.png"
  target_path="${TARGET_DIR}/${file}"

  grim - | tee "${target_path}" | wl-copy
  notify_view "default" "${target_path}"
}

# 延迟 10 秒捕获
shot10() {
  countdown 10
  sleep 1
  local current_time file target_path
  current_time=$(get_timestamp)
  file="Screenshot_${current_time}.png"
  target_path="${TARGET_DIR}/${file}"

  grim - | tee "${target_path}" | wl-copy
  notify_view "default" "${target_path}"
}

# 兼容旧逻辑：基于文本解析活动窗口几何坐标
shotwin() {
  local w_pos w_size current_time file target_path
  w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
  w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed 's/,/x/g')

  current_time=$(get_timestamp)
  file="Screenshot_${current_time}_window.png"
  target_path="${TARGET_DIR}/${file}"

  grim -g "${w_pos} ${w_size}" - | tee "${target_path}" | wl-copy
  notify_view "default" "${target_path}"
}

# 交互式矩形区域框选
shotarea() {
  local geometry tmpfile current_time file target_path
  geometry=$(slurp 2>/dev/null) || exit 0
  tmpfile=$(mktemp --suffix=.png)

  grim -g "${geometry}" - >"${tmpfile}"

  if [[ -s "${tmpfile}" ]]; then
    current_time=$(get_timestamp)
    file="Screenshot_${current_time}.png"
    target_path="${TARGET_DIR}/${file}"

    wl-copy <"${tmpfile}"
    mv "${tmpfile}" "${target_path}"
    notify_view "default" "${target_path}"
  else
    rm -f "${tmpfile}"
  fi
}

# 精确基于 Hyprland IPC JSON 捕获活动窗口并提取应用名
shotactive() {
  local active_json active_class current_time file target_path geometry
  active_json=$(hyprctl -j activewindow 2>/dev/null)

  # 提取窗口类名并清洗特殊字符
  active_class=$(echo "${active_json}" | jq -r '(.class // "Unknown")' | sed 's/[^a-zA-Z0-9._-]/_/g')
  geometry=$(echo "${active_json}" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')

  current_time=$(get_timestamp)
  file="Screenshot_${current_time}_${active_class}.png"
  target_path="${TARGET_DIR}/${file}"

  grim -g "${geometry}" "${target_path}"
  wl-copy <"${target_path}"
  sleep 1
  notify_view "active" "${target_path}" "${active_class}"
}

# 框选区域，保存到本地目录并直接打开 Swappy 编辑
shotedit() {
  local geometry current_time file target_path
  geometry=$(slurp 2>/dev/null) || exit 0
  current_time=$(get_timestamp)
  file="Screenshot_${current_time}.png"
  target_path="${TARGET_DIR}/${file}"

  grim -g "${geometry}" - >"${target_path}"

  if [[ -s "${target_path}" ]]; then
    wl-copy <"${target_path}"
    swappy -f "${target_path}" &
    notify_view "default" "${target_path}"
  else
    rm -f "${target_path}"
  fi
}

# 区域选取并派发至 Swappy 交互式标注
shotswappy() {
  local geometry tmpfile
  geometry=$(slurp 2>/dev/null) || exit 0
  tmpfile=$(mktemp --suffix=.png)

  grim -g "${geometry}" - >"${tmpfile}"

  if [[ -s "${tmpfile}" ]]; then
    wl-copy <"${tmpfile}"
    notify_view "swappy" "${tmpfile}"
  else
    rm -f "${tmpfile}"
  fi
}

# ------------------------------------------------------------------------------
# 5. CLI 指令分发入口
# ------------------------------------------------------------------------------
case "$1" in
--now)
  shotnow
  ;;
--in5)
  shot5
  ;;
--in10)
  shot10
  ;;
--win)
  shotwin
  ;;
--area)
  shotarea
  ;;
--active)
  shotactive
  ;;
--swappy)
  shotswappy
  ;;
--edit)
  shotedit
  ;;
*)
  echo -e "可用选项 : --now | --in5 | --in10 | --win | --area | --active | --swappy | --edit"
  exit 1
  ;;
esac

exit 0
