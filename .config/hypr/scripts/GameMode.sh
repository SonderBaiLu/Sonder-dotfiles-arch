#!/usr/bin/env bash
# Game Mode. Toggles Hyprland animations + decorations
# 游戏模式：开启时关掉动画/阴影/模糊/间隙/圆角并杀死壁纸守护进程以释放 GPU；
# 退出时重启 awww-daemon、重新跑 wallust 上色并 reload 恢复原观感。
notif="applications-games"
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
    awww kill
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
    awww-daemon --format xrgb
    # 当前壁纸由 noctalia wallpaper 模块控制，此处不强制指定
    ${SCRIPTSDIR}/WallustAwww.sh
    sleep 0.5
    hyprctl reload
    ${SCRIPTSDIR}/Refresh.sh
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
hyprctl reload