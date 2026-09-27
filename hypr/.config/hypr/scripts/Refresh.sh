#!/usr/bin/env bash
# 净化版 Refresh.sh: 移除 kitty SIGUSR1 调用, 保留 Noctalia/Hyprland 重载
noctalia-shell ipc reload >/dev/null 2>&1 || true
hyprctl reload >/dev/null 2>&1 || true