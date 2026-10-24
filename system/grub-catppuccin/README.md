# Catppuccin Frappé GRUB 主题（EndeavourOS / 2560×1440 定制）

预览图：`preview.png`

## 安装

```bash
sudo bash install.sh
```

脚本会：

1. 备份 `/etc/default/grub` 为 `/etc/default/grub.bak.<时间戳>`
2. 复制主题到 `/boot/grub/themes/catppuccin-frappe-eos/`
3. 设置 `GRUB_THEME`、`GRUB_GFXMODE="2560x1440x32,1920x1080x32,auto"`
4. 设置 `GRUB_DISABLE_SUBMENU='true'`，内核条目平铺到第一层菜单
5. 注释掉 EndeavourOS 的 `GRUB_BACKGROUND`（避免和主题背景冲突）
6. 执行 `grub-mkconfig -o /boot/grub/grub.cfg`

重启后生效。

## 更新

装过旧版的话，直接再运行一次 `sudo bash install.sh`：会覆盖主题、删掉旧标题字体，然后重新生成 grub.cfg。

## 回滚

```bash
sudo bash install.sh --revert
```

## 说明

- 保留 GRUB 引导，Windows 双启动项不受影响。
- 布局用百分比定位，GRUB 回退到 1080p 时依然可用。
- 菜单字体：Terminus 32px（单色位图字体，GRUB 下无锯齿）；标题预渲染为 PNG。
- 菜单宽度 1000px，`EndeavourOS, with Linux linux-zen (fallback initramfs)` 也能完整显示。
- 内核条目已平铺，第一层菜单直接显示内核名；第二条是同一个 linux-zen 的 fallback initramfs，不是原版内核。
- 背景与图标素材来自 [catppuccin/grub](https://github.com/catppuccin/grub)（MIT，见 `LICENSE-catppuccin-grub`），Terminus 字体见 `LICENSE-terminus-font`。
