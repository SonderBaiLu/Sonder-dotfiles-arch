#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# 关闭当前活动窗口：对窗口所属 PID 执行 kill（杀掉整个进程，多窗口应用会全部关闭）。

# Copied from Discord post. Thanks to @Zorg


# 从 hyprctl activewindow 文本里抠出活动窗口的 PID
active_pid=$(hyprctl activewindow | grep -o 'pid: [0-9]*' | cut -d' ' -f2)

if [[ -z "$active_pid" || ! "$active_pid" =~ ^[0-9]+$ ]]; then
  notify-send -u low -i "dialog-error" "Kill Active Window" "No active window PID found."
  exit 1
fi

# 关闭活动窗口进程
kill "$active_pid"
