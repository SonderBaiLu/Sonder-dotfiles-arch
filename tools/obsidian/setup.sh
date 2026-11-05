#!/usr/bin/env bash
# Obsidian 笔记库一键恢复
#
# 做三件事：装 Obsidian → 准备 ~/Obsidian/SondeNote → 校验插件与主题。
# vault 用固定 commit 的 starter vault 做种子，插件文件随 vault 自己的 git 走，
# 不依赖应用内「更新全部」，重装后能回到同一套配置。
#
# 用法:
#   ./tools/obsidian/setup.sh                 # 安装 + 准备 + 校验
#   ./tools/obsidian/setup.sh --check         # 只校验，不改动
#   OBSIDIAN_VAULT_REPO=git@github.com:<你>/SondeNote.git ./tools/obsidian/setup.sh
#                                             # 已把笔记库推到自己的远端时，从自己的仓库恢复
#   OBSIDIAN_VAULT=/path/to/vault ...         # 换 vault 路径（默认 ~/Obsidian/SondeNote）

set -euo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/Obsidian/SondeNote}"
VAULT_REPO="${OBSIDIAN_VAULT_REPO:-}"
TEMPLATE_REPO="https://github.com/semanticdata/obsidian-starter-vault.git"
TEMPLATE_COMMIT="daab6394f77fac33d6dfcef77777d408f2d71eab"

CHECK_ONLY=0
case "${1:-}" in
	--check) CHECK_ONLY=1 ;;
	-h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	'') ;;
	*) echo "未知参数：$1（用 --help）" >&2; exit 2 ;;
esac

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null || die "缺少 git"

STATUS=0

# ---- 1. 应用 ----
info "检查 Obsidian"
if command -v obsidian >/dev/null 2>&1; then
	ok "已安装 $(pacman -Q obsidian 2>/dev/null | awk '{print $2}' || true)"
else
	if [ "$CHECK_ONLY" = 1 ]; then
		warn "未安装（sudo pacman -S obsidian）"
		STATUS=1
	else
		sudo pacman -S --needed --noconfirm obsidian
		ok "安装完成"
	fi
fi

# ---- 2. 笔记库 ----
info "准备笔记库：$VAULT"
if [ -d "$VAULT/.obsidian" ]; then
	ok "已存在"
elif [ "$CHECK_ONLY" = 1 ]; then
	warn "缺少笔记库（去掉 --check 执行初始化）"
	STATUS=1
else
	mkdir -p "$(dirname -- "$VAULT")"
	if [ -n "$VAULT_REPO" ]; then
		git clone "$VAULT_REPO" "$VAULT"
		ok "已从 $VAULT_REPO 恢复"
	else
		git clone "$TEMPLATE_REPO" "$VAULT"
		git -C "$VAULT" checkout -B main "$TEMPLATE_COMMIT"
		git -C "$VAULT" remote rename origin upstream
		ok "已用固定模板初始化（$(printf '%.7s' "$TEMPLATE_COMMIT")）"
		warn "当前是模板种子，笔记库还没有自己的远端"
		warn "推送后下次可指定 OBSIDIAN_VAULT_REPO 恢复："
		warn "  cd \"$VAULT\" && git remote add origin <你的仓库> && git push -u origin main"
	fi
fi

# ---- 3. 校验 ----
info "校验配置"
[ -d "$VAULT/.obsidian" ] || die "缺少 $VAULT/.obsidian，先去掉 --check 再跑一次"
plugin_dir="$VAULT/.obsidian/plugins"
theme_file="$VAULT/.obsidian/themes/Minimal/theme.css"

if [ -f "$theme_file" ]; then
	ok "Minimal 主题就位"
else
	warn "缺少 Minimal 主题"
	STATUS=1
fi

count=0
printf '\n  插件：\n'
for d in "$plugin_dir"/*/; do
	[ -d "$d" ] || continue
	id="$(basename -- "$d")"
	missing=""
	for f in manifest.json main.js; do
		[ -f "$d/$f" ] || missing="$missing $f"
	done
	if [ -n "$missing" ]; then
		warn "$id 缺少：$missing"
		STATUS=1
		continue
	fi
	ver="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$d/manifest.json" | head -1)"
	printf '    %-34s %s\n' "$id" "${ver:-?}"
	count=$((count + 1))
done
if [ "$count" -gt 0 ]; then
	ok "$count 个插件文件完整"
else
	warn "没有找到插件"
	STATUS=1
fi

# 启用列表里的插件必须真的存在
enabled_file="$VAULT/.obsidian/community-plugins.json"
if [ -f "$enabled_file" ]; then
	while IFS= read -r id; do
		id="${id//\"/}"
		[ -z "$id" ] && continue
		[ -d "$plugin_dir/$id" ] || { warn "已启用但缺失：$id"; STATUS=1; }
	done < <(grep -o '"[^"]*"' "$enabled_file" || true)
fi

# 笔记库是否已纳入 git（插件版本靠它固定）
if git -C "$VAULT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	ok "笔记库已在 git 管理（$(git -C "$VAULT" log -1 --format='%h %s' 2>/dev/null || echo '无提交')）"
else
	warn "笔记库不在 git 管理，插件版本无法固定"
	STATUS=1
fi

# ---- 4. 提示 ----
info "完成"
printf '  vault ：%s\n' "$VAULT"
printf '  打开  ：obsidian "obsidian://open?vault=%s"\n' "$(basename -- "$VAULT")"
printf '  说明  ：nvim 的 obsidian.nvim 已指向该路径；笔记库不随 dotfiles 入库\n'
exit "$STATUS"
