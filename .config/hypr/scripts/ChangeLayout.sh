#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly
# 布局二选一切换：master 与 dwindle 之间来回，同时重配 SUPER+J/K 的循环方式。

notif="input-keyboard"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

# init 模式先把布局值取反再走一遍切换逻辑：
# 目的不是真切换布局，而是让启动时先把 SUPER+J/K 重置为全局循环
# （与 KeybindsLayoutInit.sh 的行为一致），避免与布局相关绑定叠加。
if [ "$1" = "init" ]; then
  if [ "$LAYOUT" = "master" ]; then
    LAYOUT="dwindle"
  else
    LAYOUT="master"
  fi
fi

case $LAYOUT in
# 当前是 master → 切到 dwindle，J/K 恢复为全局循环
"master")
  hyprctl keyword general:layout dwindle
  hyprctl keyword unbind SUPER,J
  hyprctl keyword unbind SUPER,K
  hyprctl keyword bind SUPER,J,cyclenext
  hyprctl keyword bind SUPER,K,cyclenext,prev
  hyprctl keyword bind SUPER,O,togglesplit
  notify-send -e -u low -i "$notif" " Dwindle Layout"
  ;;
# 当前是 dwindle → 切到 master，J/K 改为布局内循环（layoutmsg）
"dwindle")
  hyprctl keyword general:layout master
  hyprctl keyword unbind SUPER,J
  hyprctl keyword unbind SUPER,K
  hyprctl keyword unbind SUPER,O
  hyprctl keyword bind SUPER,J,layoutmsg,cyclenext
  hyprctl keyword bind SUPER,K,layoutmsg,cycleprev
  notify-send -e -u low -i "$notif" " Master Layout"
  ;;
*) ;;

esac
