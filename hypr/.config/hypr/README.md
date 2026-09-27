# Hyprland 配置（原生 Lua）

本目录是 Hyprland 0.56+ 的原生 Lua 配置。入口为 `hyprland.lua`，按职责拆分为 `lua/` 下的多个模块。

## 目录结构

```
hyprland.lua            # 入口，require 加载各模块
lua/
  defaults.lua          # 常量（终端/编辑器/脚本目录）、显示器、触摸板设备
  environment.lua       # 环境变量（输入法、NVIDIA、Wayland 等）
  layout.lua            # 布局、输入、手势、渲染、光标
  appearance.lua        # 主题色、动画曲线、边框、装饰、阴影、模糊、窗口组
  rules.lua             # 窗口规则（tag 归类 + 浮动/透明/尺寸等）
  binds.lua             # 快捷键绑定
  startup.lua           # 开机启动项
hypridle.conf           # 空闲管理（锁屏/休眠/关屏）
hyprlock.conf           # 锁屏界面
initial-boot.sh         # 首次进系统的精装脚本（壁纸配色、深色模式等）
scripts/                # 被绑定的各类辅助脚本
```

## 关于配置格式

- Hyprland 0.56 内置原生 Lua 配置管理器，入口为 `hyprland.lua`；传统 `.conf`（hyprlang）将在 0.57 移除。
- 用 `require("lua.xxx")` 拆分模块，替代旧的 `source =` 语法。
- 键名层级：传统 `a:b-c` 写成嵌套表 `a = { b_c = ... }`。

## 维护提示

- 更换显示器 / 触摸板设备：改 `lua/defaults.lua`。
- 调整主题色：改 `lua/appearance.lua`。
- 增减窗口规则：改 `lua/rules.lua`。
- 增减快捷键：改 `lua/binds.lua`。
- 修改后用 `hyprctl reload config-only` 使配置生效，并用 `hyprctl configerrors` 检查解析错误。
- 校验脚本语法：`luac -p hyprland.lua`（Lua）、`bash -n scripts/xxx.sh`（shell）。

## 注意

- 仓库历史中曾提交过 `.webui_secret_key`（明文 token），如仍在服务端使用请立即撤销/轮换。
- 壁纸缓存目录 `wallpaper_effects/` 与首次启动标记 `.initial_startup_done` 均已加入 `.gitignore`，不纳入版本控制。

# 我都干了什么？

1. 安装光标主题
   paru -S catppuccin-cursors-frappe
   paru -S papirus-folders-catppuccin-git
   sudo papirus-folders -C cat-frappe-blue --theme Papirus-Dark
   papirus-folders -l --theme Papirus-Dark | grep -i frappe
