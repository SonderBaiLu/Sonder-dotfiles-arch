#!/usr/bin/env bash
# Sonder-dotfiles-arch 引导脚本
#
# 全新 Arch 上先补齐构建依赖（base-devel / git / rust），再编译并运行 sonder-installer，
# 最后安装 tty1 自动进入 Hyprland 的登录片段。
#
# 用法: ./bootstrap.sh [all|deps|tools|stow|unstow|verify|check] [--yes]
#       不带参数 = all（驱动 + 依赖 + 工具 + 符号链接 + 校验）

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v pacman >/dev/null || die "这是 Arch 系专用脚本"

# ---- 1. 构建依赖 ----
info "检查构建依赖（base-devel / git / rust）"
missing=()
command -v git   >/dev/null || missing+=(git)
command -v make  >/dev/null || missing+=(base-devel)
command -v cargo >/dev/null || missing+=(rust)
if [ ${#missing[@]} -gt 0 ]; then
	printf '将安装: %s\n' "${missing[*]}"
	sudo pacman -S --needed --noconfirm "${missing[@]}"
else
	echo "已就绪"
fi

# ---- 2. 编译安装器 ----
info "构建 sonder-installer"
( cd installer && cargo build --release )
INSTALLER="$REPO_DIR/installer/target/release/sonder-installer"
[ -x "$INSTALLER" ] || die "构建失败：$INSTALLER 不存在"

# ---- 3. 部署 ----
if [ $# -eq 0 ]; then
	info "只读预检"
	"$INSTALLER" check || die "预检发现冲突，已中止（先处理上面的 [冲突] 项）"
fi

info "运行部署"
status=0
if [ $# -gt 0 ]; then
	"$INSTALLER" "$@" || status=$?
else
	"$INSTALLER" all || status=$?
fi

# ---- 4. tty1 自动启动 Hyprland ----
info "配置 tty1 自动启动 Hyprland"
MARK_BEGIN="# >>> sonder-hyprland-autostart >>>"
MARK_END="# <<< sonder-hyprland-autostart <<<"
PROFILE="$HOME/.bash_profile"
if grep -qF "$MARK_BEGIN" "$PROFILE" 2>/dev/null; then
	echo "已存在，跳过"
else
	touch "$PROFILE"
	{
		printf '\n%s\n' "$MARK_BEGIN"
		cat <<'SNIPPET'
# 在 tty1 登录时自动进入 Hyprland；其它 TTY 保留纯 shell 以便排障。
# 删除本段即可恢复手动启动。
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] \
   && [ "$(tty)" = "/dev/tty1" ] && command -v start-hyprland >/dev/null 2>&1; then
	exec start-hyprland
fi
SNIPPET
		printf '%s\n' "$MARK_END"
	} >> "$PROFILE"
	echo "已写入 $PROFILE"
fi

info "完成"
echo "日志: ~/.local/state/sonder-dotfiles/install.log"
if [ "$status" -ne 0 ]; then
	warn "部署有失败/跳过项（退出码 $status），详见上面的日志"
fi
[ "$status" -eq 0 ] || exit "$status"
