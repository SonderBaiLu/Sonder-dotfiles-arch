#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic

# 获取当前音量（静音或音量为 0 时返回 "Muted"）
get_volume() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        echo "Muted"
        return
    fi

    local volume
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq 0 ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

# 按音量档位返回对应图标名（freedesktop 标准名，随主题渲染）
get_icon() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        echo "audio-volume-muted"
        return
    fi

    current=$(pamixer --get-volume)
    if [[ "$current" -le 30 ]]; then
        echo "audio-volume-low"
    elif [[ "$current" -le 60 ]]; then
        echo "audio-volume-medium"
    else
        echo "audio-volume-high"
    fi
}

# 弹出音量通知。
# string:x-canonical-private-synchronous 让同类通知互相替换而非逐条堆叠；int:value 画出进度条。
notify_user() {
    local muted="$(pamixer --get-mute)"
    local level="$(pamixer --get-volume)"

    if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif \
            -u low -i "$(get_icon)" \
            " Volume:" " Muted"
    else
        notify-send -e -h int:value:"$level" -h string:x-canonical-private-synchronous:volume_notif \
            -u low -i "$(get_icon)" \
            " Volume Level:" " ${level}%"
    fi
}

# 提高音量（静音状态下先解除静音再调）
inc_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -i "$1" --allow-boost --set-limit 150 && notify_user
    fi
}

# 降低音量（静音状态下先解除静音再调）
dec_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -d "$1" && notify_user
    fi
}

# 切换音量静音
toggle_mute() {
	if [ "$(pamixer --get-mute)" == "false" ]; then
		pamixer -m && notify-send -e -u low -i "audio-volume-muted" " Mute"
	elif [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && notify-send -e -u low -i "$(get_icon)" " Volume:" " Switched ON"
	fi
}

# 切换麦克风静音
toggle_mic() {
	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
		pamixer --default-source -m && notify-send -e -u low -i "microphone-sensitivity-muted" " Microphone:" " Switched OFF"
	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer --default-source -u && notify-send -e -u low -i "microphone-sensitivity-high" " Microphone:" " Switched ON"
	fi
}
# 返回麦克风当前状态对应的图标名
get_mic_icon() {
    local muted="$(pamixer --default-source --get-mute)"
    local current="$(pamixer --default-source --get-volume)"
    if [[ "$muted" == "true" || "$current" -eq "0" ]]; then
        echo "microphone-sensitivity-muted"
    else
        echo "microphone-sensitivity-high"
    fi
}

# 获取麦克风音量（静音或 0 时返回 "Muted"）
get_mic_volume() {
    if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
        echo "Muted"
        return
    fi

    local volume
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq 0 ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

# 弹出麦克风音量通知（同音量通知一样走替换式更新）
notify_mic_user() {
    local muted="$(pamixer --default-source --get-mute)"
    local level="$(pamixer --default-source --get-volume)"
    local icon message

    if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
        icon="microphone-sensitivity-muted"
        notify-send -e -h "string:x-canonical-private-synchronous:volume_notif" \
            -u low -i "$icon" \
            " Mic Level:" " Muted"
    else
        icon="microphone-sensitivity-high"
        notify-send -e -h int:value:"$level" -h "string:x-canonical-private-synchronous:volume_notif" \
            -u low -i "$icon" \
            " Mic Level:" " ${level}%"
    fi
}

# 提高麦克风音量（步长 5，静音时先解除）
inc_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -i 5 && notify_mic_user
    fi
}

# 降低麦克风音量（步长 5，静音时先解除）
dec_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -d 5 && notify_mic_user
    fi
}

# 命令行分发：各选项由 binds.lua 的音量/麦克风快捷键调用
case "$1" in
"--get")
  get_volume
  ;;
"--inc")
  inc_volume 5
  ;;
"--inc-precise")
  inc_volume 1
  ;;
"--dec")
  dec_volume 5
  ;;
"--dec-precise")
  dec_volume 1
  ;;
"--toggle")
  toggle_mute
  ;;
"--toggle-mic")
  toggle_mic
  ;;
"--get-icon")
  get_icon
  ;;
"--get-mic-icon")
  get_mic_icon
  ;;
"--mic-inc")
  inc_mic_volume
  ;;
"--mic-dec")
  dec_mic_volume
  ;;
*)
  get_volume
  ;;
esac
