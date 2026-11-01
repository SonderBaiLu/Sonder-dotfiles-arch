# Girl · Pillow SDDM 主题

来源：[Darkkal44/qylock](https://github.com/Darkkal44/qylock) 合集里的 `girl-pillow`，GPL-3.0（见 `LICENSE-qylock`）。

- 预览：`preview.gif`
- 背景：静态 PNG（无视频），**不需要** gstreamer/多媒体依赖
- 字体：Itim（已随主题附带在 `girl-pillow/font/` 内，SDDM 会自动加载）

## 安装

只装主题 + 部署配套壁纸 + 设为默认（不改登录方式）：

```bash
sudo bash install.sh
```

要真正用 SDDM 登录器（启用 `sddm` 服务 + 禁用 tty1 自动进 Hyprland）：

```bash
sudo bash install.sh --enable
```

## 配套壁纸与锁屏

主题背景 `girl-pillow/bg.png`（4444×2500，比 2560×1440 屏幕还高）在安装时
会一并复制到 `~/Pictures/Wallpapers/girl-pillow.png`（目录不存在会自动创建）。

你的桌面壁纸由 `awww` 管理、锁屏由 noctalia 内置锁屏（`noctalia msg session lock`）
复用当前桌面壁纸，所以把桌面壁纸设成它，锁屏就自动是同一张图：

```bash
~/.config/hypr/scripts/WallustAwww.sh ~/Pictures/Wallpapers/girl-pillow.png
```

## 回滚

改回 tty1 自动登录：

```bash
sudo systemctl disable --now sddm
# 再把 ~/.bash_profile 里被注释的 exec start-hyprland 段取消注释
```

换回官方默认主题：把 `/etc/sddm.conf` 里 `[Theme]` 段的 `Current=` 改掉即可。
