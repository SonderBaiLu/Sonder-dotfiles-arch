#!/usr/bin/env bash
# Polkit authentication agent - 净化版 (仅 hyprpolkitagent)
# 你的系统仅 /usr/lib/hyprpolkitagent 可用
AGENT=/usr/lib/hyprpolkitagent
if [[ -x "$AGENT" ]]; then
    exec "$AGENT"
else
    echo "Polkit: hyprpolkitagent 未找到 ($AGENT)"
    exit 1
fi