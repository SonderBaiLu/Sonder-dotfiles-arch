#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Monitor backlights (if supported) using brightnessctl

notification_timeout=1000
step=10  # INCREASE/DECREASE BY THIS VALUE

# 读取当前亮度：brightnessctl -m 机器可读输出的第 4 列（去百分号）
get_brightness() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

# 弹出亮度通知：int:value 在通知里画进度条，private-synchronous 让通知原地更新
send_notification() {
    local brightness=$1

    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h int:value:"$brightness" \
        -u low \
        -i "display-brightness-symbolic" \
        "Screen" "Brightness: ${brightness}%"
}

# 调整亮度并通知；新值钳制在 5–100 之间（下限避免调到全黑）
change_brightness() {
    local delta=$1
    local current new

    current=$(get_brightness)
    new=$((current + delta))

    # Clamp between 5 and 100
    (( new < 5 )) && new=5
    (( new > 100 )) && new=100

    brightnessctl set "${new}%"

    send_notification "$new"
}

# Main
case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "$step"
        ;;
    "--dec")
        change_brightness "-$step"
        ;;
    *)
        get_brightness
        ;;
esac
