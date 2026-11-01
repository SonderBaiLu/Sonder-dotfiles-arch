#!/usr/bin/env bash
# 安装 Girl · Pillow SDDM 主题（源自 Darkkal44/qylock），并部署配套壁纸。
# 用法: sudo bash install.sh [--enable]
#   --enable  额外启用 SDDM 服务，并禁用 ~/.bash_profile 里 tty1 自动进 Hyprland 的片段。
# 不带 --enable 只装主题 + 部署配套壁纸 + 设为默认主题，不改登录方式。
set -euo pipefail

THEME_NAME="girl-pillow"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="${HERE}/${THEME_NAME}"
THEME_DEST="/usr/share/sddm/themes/${THEME_NAME}"
SDDM_CONF="/etc/sddm.conf"

die() { printf '错误: %s\n' "$*" >&2; exit 1; }

[[ ${EUID} -eq 0 ]] || die "需要 root：sudo bash $(basename "$0")"
[[ -f "${THEME_SRC}/metadata.desktop" ]] || die "找不到主题：${THEME_SRC}"
command -v sddm >/dev/null || die "找不到 sddm，先安装：pacman -S sddm"

# 定位真实用户（sudo 下 $USER 是 root）
TARGET_USER="${SUDO_USER:-${USER:-qicat}}"
USER_HOME="$(getent passwd "${TARGET_USER}" 2>/dev/null | awk -F: '{print $6}')"

# ---- 1. 复制主题 ----
# 防御性校验：THEME_DEST 必须是 /usr/share/sddm/themes/ 下的单一子目录，
# 防止路径被误改为 / 或空值时 rm -rf 误删系统文件。
[[ "${THEME_DEST}" == /usr/share/sddm/themes/* ]] \
    && [[ "${THEME_DEST}" != "/usr/share/sddm/themes/" ]] \
    || die "目标路径异常，已中止：${THEME_DEST}"

install -d "${THEME_DEST}"
rm -rf "${THEME_DEST}"
cp -a "${THEME_SRC}/." "${THEME_DEST}/"

# ---- 2. 设为主题 + 修正 DisplayServer ----
# SDDM 配置优先级：/etc/sddm.conf > /etc/sddm.conf.d/*.conf，
# 所以必须直接改 /etc/sddm.conf，否则会被旧的 Current=KDE-Story 覆盖。
if [[ ! -f "${SDDM_CONF}" ]]; then
    die "找不到 ${SDDM_CONF}"
fi
cp -a "${SDDM_CONF}" "${SDDM_CONF}.bak.$(date +%Y%m%d-%H%M%S)"

set_key() {
    local key="$1" value="$2"
    if grep -qE "^[[:space:]]*${key}=" "${SDDM_CONF}"; then
        sed -i -E "s|^([[:space:]]*${key}=).*|\1${value}|" "${SDDM_CONF}"
    else
        printf '%s=%s\n' "${key}" "${value}" >> "${SDDM_CONF}"
    fi
}

# 主题：覆盖掉 EndeavourOS 残留的 Current=KDE-Story
set_key Current "${THEME_NAME}"

# 登录界面后端：本机没装 weston，wayland greeter 必然失败并回退 X11，
# 直接固定为 x11，消除 HELPER_DISPLAYSERVER_ERROR 报错。
# 主题是纯静态 PNG 的 Qt6 QML，X11 / Wayland 下观感完全一致。
set_key DisplayServer "x11"

grep -q "^Current=${THEME_NAME}" "${SDDM_CONF}" || die "写入 Current 失败"
grep -q "^DisplayServer=x11" "${SDDM_CONF}" || die "写入 DisplayServer 失败"

printf '\n主题 girl-pillow 已安装并设为默认，登录界面后端固定为 X11。\n'

# ---- 2.5 部署配套壁纸到用户壁纸目录（桌面/锁屏复用同一张图）----
if [[ -n "${USER_HOME}" && -d "${USER_HOME}" ]]; then
    WALL_DIR=""
    for _d in "${USER_HOME}/Pictures/Wallpapers" "${USER_HOME}/Pictures/wallpapers"; do
        [[ -d "${_d}" ]] && WALL_DIR="${_d}" && break
    done
    [[ -z "${WALL_DIR}" ]] && WALL_DIR="${USER_HOME}/Pictures/Wallpapers"
    install -d -o "${TARGET_USER}" -g "${TARGET_USER}" "${WALL_DIR}"
    install -m 644 -o "${TARGET_USER}" -g "${TARGET_USER}" \
        "${THEME_SRC}/bg.png" "${WALL_DIR}/girl-pillow.png"
    printf '配套壁纸已部署到 %s/girl-pillow.png\n' "${WALL_DIR}"
fi

# ---- 3. 可选：启用 SDDM 并禁用 tty 自动登录 ----
if [[ "${1:-}" != "--enable" ]]; then
    printf '提示：要真正用 SDDM 登录器，再执行 sudo bash %s --enable\n' "$(basename "$0")"
    exit 0
fi

PROFILE="${USER_HOME}/.bash_profile"

if [[ -f "${PROFILE}" ]] && grep -qF "# >>> sonder-hyprland-autostart >>>" "${PROFILE}"; then
    cp -a "${PROFILE}" "${PROFILE}.bak.$(date +%Y%m%d-%H%M%S)"
    sed -i -E '/^# >>> sonder-hyprland-autostart >>>/,/^# <<< sonder-hyprland-autostart <<</ s|^([[:space:]]*)exec start-hyprland|#\1exec start-hyprland  # sddm 接管登录后禁用|' "${PROFILE}"
    printf '已备份并禁用 %s 的 tty1 自动登录片段。\n' "${PROFILE}"
else
    printf '未找到 %s 的自动登录片段，跳过。\n' "${PROFILE}"
fi

systemctl enable --now sddm
printf '\nSDDM 已启用。重启后由 SDDM 登录界面进入 Hyprland。\n'
