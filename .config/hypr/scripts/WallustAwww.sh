#!/usr/bin/env bash
# Wallust 配色流水线：从当前壁纸提取色板，并写入 wallust.toml 定义的各模板
# Usage: WallustAwww.sh [absolute_path_to_wallpaper]

set -euo pipefail

# Inputs and paths
# 输入与路径：优先用第一个参数指定的壁纸；未传参时从 awww 缓存/查询结果推断。
passed_path="${1:-}"
cache_dir="$HOME/.cache/awww/"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# 解析缓存文件：首个非 filter 行即原始壁纸路径
read_cached_wallpaper() {
  local cache_file="$1"
  if [[ -f "$cache_file" ]]; then
    awk 'NF && $0 !~ /^filter/ {print; exit}' "$cache_file"
  fi
}

# 直接问 awww 当前显示器正在显示的图片路径
read_wallpaper_from_query() {
  local monitor="$1"
  awww query | awk -v mon="$monitor" '
    /^Monitor/ {
      cur=$2
      gsub(":", "", cur)
    }
    /image:/ && cur==mon {
      sub(/^.*image: /,"")
      print
      exit
    }
  '
}

# Helper: get focused monitor name (prefer JSON)
# 取焦点显示器名：优先 hyprctl -j + jq，缺失时回退文本解析
get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

# Determine wallpaper_path
# 确定壁纸路径：显式传参 → 缓存文件 → awww query，三级回退
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  # Try to read from awww cache for the focused monitor, with a short retry loop
  # 换壁纸后缓存文件写入有延迟，先短暂重试等待其出现
  current_monitor="$(get_focused_monitor)"
  cache_file="$cache_dir$current_monitor"

  # Wait briefly for awww to write its cache after an image change
  for i in {1..10}; do
    if [[ -f "$cache_file" ]]; then
      break
    fi
    sleep 0.1
  done

  if [[ -f "$cache_file" ]]; then
    # The first non-filter line is the original wallpaper path
    wallpaper_path="$(read_cached_wallpaper "$cache_file")"
  fi

  if [[ -z "$wallpaper_path" ]]; then
    wallpaper_path="$(read_wallpaper_from_query "$current_monitor")"
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  # Nothing to do; avoid failing loudly so callers can continue
  # 拿不到壁纸路径时静默退出：GameMode.sh 等调用方依赖本脚本不抛错
  exit 0
fi

# Update helpers that depend on the path
# 记录一份当前壁纸副本，供 appearance/截图等模块取用
mkdir -p "$(dirname "$wallpaper_current")"
cp -f "$wallpaper_path" "$wallpaper_current" || true

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s 静默运行 wallust：按 wallust.toml 的 [templates] 重新生成配色模板
# （hypr 边框色、noctalia/quickshell 的 qml_color.json），由模板 target 指定落盘位置
wallust run -s "$wallpaper_path" || true
