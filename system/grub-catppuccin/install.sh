#!/usr/bin/env bash
# Install the Catppuccin Frappé GRUB theme in ./catppuccin-frappe-eos.
# Usage: sudo bash install.sh [--revert]
set -euo pipefail

THEME_NAME="catppuccin-frappe-eos"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="${HERE}/${THEME_NAME}"
THEME_DEST="/boot/grub/themes/${THEME_NAME}"
GRUB_CONF="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"
GFXMODE="2560x1440x32,1920x1080x32,auto"

die() { printf '错误: %s\n' "$*" >&2; exit 1; }

[[ ${EUID} -eq 0 ]] || die "需要 root：sudo bash $(basename "$0")"
[[ -f "${THEME_SRC}/theme.txt" ]] || die "找不到主题：${THEME_SRC}/theme.txt"
[[ -f "${GRUB_CONF}" ]] || die "找不到 ${GRUB_CONF}"
command -v grub-mkconfig >/dev/null || die "找不到 grub-mkconfig"

if [[ "${1:-}" == "--revert" ]]; then
    latest="$(ls -1t "${GRUB_CONF}".bak.* 2>/dev/null | head -n1 || true)"
    [[ -n "${latest}" ]] || die "没有找到 ${GRUB_CONF}.bak.* 备份"
    cp -a "${latest}" "${GRUB_CONF}"
    grub-mkconfig -o "${GRUB_CFG}"
    printf '已恢复 %s\n' "${latest}"
    exit 0
fi

stamp="$(date +%Y%m%d-%H%M%S)"
cp -a "${GRUB_CONF}" "${GRUB_CONF}.bak.${stamp}"

install -d "${THEME_DEST}"
cp -a "${THEME_SRC}/." "${THEME_DEST}/"
rm -f "${THEME_DEST}/font-title.pf2"

# EndeavourOS 自带的 splash 会和主题背景冲突
sed -i -E 's|^[[:space:]]*GRUB_BACKGROUND=.*|# GRUB_BACKGROUND disabled: theme provides its own background|' "${GRUB_CONF}"

set_key() {
    local key="$1" value="$2"
    if grep -qE "^[#[:space:]]*${key}=" "${GRUB_CONF}"; then
        sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=${value}|" "${GRUB_CONF}"
    else
        printf '%s=%s\n' "${key}" "${value}" >> "${GRUB_CONF}"
    fi
}

set_key GRUB_THEME "\"${THEME_DEST}/theme.txt\""
set_key GRUB_GFXMODE "\"${GFXMODE}\""
set_key GRUB_DISABLE_SUBMENU "'true'"

grep -q "^GRUB_THEME=\"${THEME_DEST}/theme.txt\"" "${GRUB_CONF}" \
    || die "写入 GRUB_THEME 失败"
grep -q "^GRUB_GFXMODE=\"${GFXMODE}\"" "${GRUB_CONF}" \
    || die "写入 GRUB_GFXMODE 失败"
grep -q "^GRUB_DISABLE_SUBMENU='true'" "${GRUB_CONF}" \
    || die "写入 GRUB_DISABLE_SUBMENU 失败"

grub-mkconfig -o "${GRUB_CFG}"

if grep -q "${THEME_NAME}/theme.txt" "${GRUB_CFG}"; then
    printf '\n主题已启用，重启后生效。\n'
    printf '回滚：sudo bash %s --revert\n' "${HERE}/$(basename "$0")"
else
    printf '\n警告: grub.cfg 中未找到主题引用，请检查上面的 grub-mkconfig 输出。\n' >&2
    printf '回滚：sudo bash %s --revert\n' "${HERE}/$(basename "$0")" >&2
    exit 1
fi
