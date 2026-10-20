#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)
# 从壁纸目录随机选一张：awww 未运行时先拉起守护进程，
# 对焦点显示器带过渡动画地应用壁纸，随后交给 WallustAwww.sh 重新取色、Refresh.sh 重载。

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# 候选壁纸列表与随机抽取（find -L 跟随符号链接目录）
PICS=($(find -L "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}


# Transition config
# 过渡动画参数：帧率 / 切换类型（random=随机特效）/ 时长（秒）/ 贝塞尔缓动
FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"


# awww 未运行（query 失败）则先启动守护进程，再对焦点显示器设置随机壁纸
awww query || awww-daemon --format xrgb && awww img -o $focused_monitor ${RANDOMPICS} $AWWW_PARAMS

wait $!
"$SCRIPTSDIR/WallustAwww.sh" &&

wait $!
sleep 2
"$SCRIPTSDIR/Refresh.sh"

