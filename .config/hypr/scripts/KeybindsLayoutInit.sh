#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# 启动时把 SUPER+J/K 固定为「全局窗口循环」，不随 dwindle/master 布局切换而变化，
# 避免 ChangeLayout.sh 切布局时同一按键出现两套行为的歧义。

set -euo pipefail

# 每次启动都先解绑再重绑，保证与 ChangeLayout.sh 的写法互不残留
hyprctl keyword unbind SUPER,J || true
hyprctl keyword unbind SUPER,K || true

# 全局循环窗口：J 下一个，K 上一个
hyprctl keyword bind SUPER,J,cyclenext
hyprctl keyword bind SUPER,K,cyclenext,prev
