#!/usr/bin/env bash
# 净化版 GameMode.sh: 移除 ~/.config/rofi/.current_wallpaper 路径依赖
# Game Mode. Toggles Hyprland animations + decorations
notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"

    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    swww kill
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
    swww-daemon --format xrgb
    # 旧路径 ~/.config/rofi/.current_wallpaper 已不存在;
    # swww 的"当前壁纸"由 waypaper / noctalia wallpaper 模块控制, 此处不强制指定
    ${SCRIPTSDIR}/WallustSwww.sh
    sleep 0.5
    hyprctl reload
    ${SCRIPTSDIR}/Refresh.sh
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
hyprctl reload