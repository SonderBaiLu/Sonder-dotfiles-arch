#!/usr/bin/env bash
# Sonder-dotfiles-arch 引导脚本
#
# 全新 Arch 上先补齐构建依赖（base-devel / git / rust），再编译并运行 sonder-installer，
# 最后安装 tty1 自动进入 Hyprland 的登录片段。
#
# 用法: ./bootstrap.sh [all|deps|tools|stow|unstow|plugins|verify|check] [--yes] [--optional wechat,qq,office]
#       不带参数 = all（驱动 + 依赖 + 工具 + 符号链接 + 校验），
#       部署前会询问要安装哪些可选软件（微信/QQ/LibreOffice；回车=不装）

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32m  ✔ %s\033[0m\n' "$*"; }
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
	ok "构建依赖就绪"
else
	ok "构建依赖已就绪"
fi

# ---- 2. 编译安装器 ----
info "构建 sonder-installer"
( cd installer && cargo build --release )
INSTALLER="$REPO_DIR/installer/target/release/sonder-installer"
[ -x "$INSTALLER" ] || die "构建失败：$INSTALLER 不存在"

# ---- 2.5 可选软件选择（非必要大件，按需安装）----
# 仅在默认全量部署 + 交互终端时询问；显式传参或 --yes 时跳过询问，
# 可选软件由命令行 --optional 直接指定（缺省=不装）。
OPT_ARGS=()
if [ $# -eq 0 ] && [ -t 0 ]; then
	echo
	echo "可选软件（非必要大件，不选就跳过）："
	echo "  1) 微信        wechat-bin"
	echo "  2) QQ          linuxqq"
	echo "  3) LibreOffice 办公套件（含中文语言包）"
	printf '要安装哪些？输入编号（如 1,3 / all 全装 / 直接回车=不装）: '
	read -r opt_choice
	keys=""
	if [ -n "$opt_choice" ]; then
		case "$opt_choice" in
			all|ALL) keys="all" ;;
			*)
				IFS=',' read -ra _nums <<< "$opt_choice"
				for n in "${_nums[@]}"; do
					n="${n//[[:space:]]/}"
					case "$n" in
						1) keys="${keys:+$keys,}wechat" ;;
						2) keys="${keys:+$keys,}qq" ;;
						3) keys="${keys:+$keys,}office" ;;
						all|ALL) keys="all"; break ;;
					esac
				done
				;;
		esac
	fi
	if [ -n "$keys" ]; then
		OPT_ARGS=(--optional "$keys")
		info "可选软件: $keys"
	else
		info "可选软件: 不安装（可随时手动 paru -S wechat-bin 等）"
	fi
fi

# ---- 3. 部署 ----
if [ $# -eq 0 ]; then
	info "只读预检"
	"$INSTALLER" check "${OPT_ARGS[@]}" || die "预检发现冲突，已中止（先处理上面的 [冲突] 项）"
fi

info "运行部署"
status=0
if [ $# -gt 0 ]; then
	"$INSTALLER" "$@" || status=$?
else
	"$INSTALLER" all "${OPT_ARGS[@]}" || status=$?
fi

# ---- 3.5 Hyprland 插件（hyprpm 管理）----
# hypr-dynamic-cursors 光标动态效果；按当前 Hyprland 版本联网编译，
# 失败只告警不中止部署（无插件时 Hyprland 照常启动，仅没有光标特效）
if command -v hyprpm >/dev/null && command -v cpio >/dev/null; then
if hyprpm list 2>/dev/null | grep -q dynamic-cursors; then
	ok "hypr-dynamic-cursors 插件已安装"
else
		info "安装 Hyprland 插件 hypr-dynamic-cursors（联网编译，约 1-2 分钟）"
		hyprpm add https://github.com/VirtCode/hyprland-dynamic-cursors \
			|| warn "插件安装失败，可稍后手动执行：hyprpm add https://github.com/VirtCode/hyprland-dynamic-cursors"
	fi
else
	warn "缺 hyprpm 或 cpio，跳过 Hyprland 插件安装"
fi

# ---- 4. tty1 自动启动 Hyprland ----
info "配置 tty1 自动启动 Hyprland"
MARK_BEGIN="# >>> sonder-hyprland-autostart >>>"
MARK_END="# <<< sonder-hyprland-autostart <<<"
PROFILE="$HOME/.bash_profile"
if grep -qF "$MARK_BEGIN" "$PROFILE" 2>/dev/null; then
	ok "tty1 自动启动片段已存在，跳过"
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
	ok "已写入 $PROFILE"
fi

info "完成"
echo
printf '\033[1;32m✔ Sonder 桌面部署流程全部结束\033[0m\n'
echo "  日志：~/.local/state/sonder-dotfiles/install.log"
echo "  验证：从 tty1 重新登录即自动进入 Hyprland"
if [ "$status" -ne 0 ]; then
	warn "部署有失败/跳过项（退出码 $status），详见上面的日志"
fi
[ "$status" -eq 0 ] || exit "$status"
