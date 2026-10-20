#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for keyboard backlights (if supported) using brightnessctl

# 读取键盘背光亮度（"*" 通配所有 kbd_backlight 设备，多台键盘取合并值）
get_kbd_backlight() {
	echo $(brightnessctl -d '*::kbd_backlight' -m | cut -d, -f4)
}

# 弹出键盘背光通知（int:value 画进度条）
notify_user() {
	notify-send -e -h string:x-canonical-private-synchronous:brightness_notif -h int:value:$current -u low -i "keyboard-brightness-symbolic" "Keyboard" "Brightness:$current%"
}

# 设置背光，刷新 $current 后通知
change_kbd_backlight() {
	brightnessctl -d *::kbd_backlight set "$1" && current=$(get_kbd_backlight | sed 's/%//') && notify_user
}

# Execute accordingly
case "$1" in
	"--get")
		get_kbd_backlight
		;;
	"--inc")
		change_kbd_backlight "+30%"
		;;
	"--dec")
		change_kbd_backlight "30%-"
		;;
	*)
		get_kbd_backlight
		;;
esac
