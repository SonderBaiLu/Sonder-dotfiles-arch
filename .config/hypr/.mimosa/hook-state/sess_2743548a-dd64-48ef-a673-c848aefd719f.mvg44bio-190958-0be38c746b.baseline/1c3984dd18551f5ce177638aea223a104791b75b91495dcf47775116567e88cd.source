#!/usr/bin/env bash
# Overview 切换：通过 quickshell IPC 调起 noctalia 的 overview
set -euo pipefail

# noctalia 运行中 → 直接走 IPC 切换
if pgrep -x quickshell >/dev/null 2>&1; then
  if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# IPC 未就绪时冷启动 quickshell 的 overview 实例后重试一次
if command -v qs >/dev/null 2>&1; then
  qs -c overview >/dev/null 2>&1 &
  sleep 0.6
  if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

notify-send "Overview" "Quickshell 不可用，无法切换 overview" -u low 2>/dev/null || true
exit 1
