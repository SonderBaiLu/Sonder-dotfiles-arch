#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# 用于禁用/启用笔记本触摸板。
# 触摸板设备名与 lua/defaults.lua 中的 hl.device 保持一致。
# 用 `hyprctl devices` 可查询设备名。
# 参考 https://github.com/hyprwm/Hyprland/discussions/4283

set -euo pipefail

# 触摸板设备名与 lua/defaults.lua 中的 hl.device 保持一致。
# 如需更换设备，用 `hyprctl devices` 查询名称后同时修改 defaults.lua 与下方默认值。
notif="$HOME/.config/swaync/images/ja.png"

touchpad_device="${TOUCHPAD_DEVICE:-asue1209:00-04f3:319f-touchpad}"

touchpad_keyword="${TOUCHPAD_KEYWORD:-device:${touchpad_device}:enabled}"
status_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.status"

enable_touchpad() {
    printf "true" >"$status_file"
    notify-send -u low -i "$notif" " Enabling" " touchpad"
    hyprctl keyword "$touchpad_keyword" true -r
}

disable_touchpad() {
    printf "false" >"$status_file"
    notify-send -u low -i "$notif" " Disabling" " touchpad"
    hyprctl keyword "$touchpad_keyword" false -r
}

current_state="false"
if [[ -f "$status_file" ]]; then
    current_state="$(<"$status_file")"
fi

if [[ "$current_state" == "true" ]]; then
    disable_touchpad
else
    enable_touchpad
fi
