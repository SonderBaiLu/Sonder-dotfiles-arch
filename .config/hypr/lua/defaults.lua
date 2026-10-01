-- 默认值、显示器与设备设置。
-- 这里集中放硬件/用户可调整的常量，其他模块通过 require 返回的表复用。

local M = {
	terminal = "alacritty",
	files = "nautilus",
	editor = "nvim",
	main_mod = "SUPER",
	scripts = os.getenv("HOME") .. "/.config/hypr/scripts",
}

-- 当前机器的双屏布局：外接 4K 主屏 + 2K 笔记本屏。
-- 更换硬件时只需修改这里，不要在快捷键模块里散落显示器名称。
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@160", position = "auto", scale = 1.0 })
hl.monitor({ output = "eDP-2", mode = "2560x1440@160", position = "auto", scale = 1.0 })
-- 在不使用独显直连的情况下 笔记本内屏id 会变成 eDP-1
hl.monitor({ output = "eDP-1", mode = "2560x1440@160", position = "auto", scale = 1.0 })

-- 默认编辑器同时注入环境，供终端应用与外部脚本读取。
hl.env("EDITOR", M.editor)

-- 笔记本专用触摸板设备；设备不存在时 Hyprland 会忽略该项。
hl.device({ name = "asue1209:00-04f3:319f-touchpad", enabled = true })

return M
