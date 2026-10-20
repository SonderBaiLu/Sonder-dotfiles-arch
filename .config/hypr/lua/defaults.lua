-- 默认值、显示器与设备设置。
-- 这里集中放硬件/用户可调整的常量，其他模块通过 require 返回的表复用。

local M = {
	terminal = "alacritty",
	files = "nautilus --new-window",
	-- yazi 是 TUI，exec 派发的进程没有 TTY，直接跑会因取不到终端尺寸而退出，须包一层 alacritty；
	-- yazi 不识别 Alacritty，会落到 ueberzugpp（Wayland）分支导致卡死；
	-- TERM=foot 让 yazi 走 Sixel 驱动，Alacritty 原生支持 Sixel，可正常显示图片预览。
	termfiles = "alacritty env TERM=foot yazi",
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

-- 持久工作区：空工作区也常驻，Noctalia 状态栏的工作区指示器才能完整显示。
-- 刻意不写 monitor：工作区可自由跟随 Super+Ctrl+F9~F12 在双屏之间搬运，
-- 不会被规则钉回原显示器。1-5 带名字（显示在状态栏上），6-10 用纯数字。
local named_workspaces = { "web", "code", "chat", "game", "design" }
for i, name in ipairs(named_workspaces) do
	hl.workspace_rule({ workspace = tostring(i), persistent = true, default_name = name })
end
for i = 6, 10 do
	hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

-- 默认编辑器同时注入环境，供终端应用与外部脚本读取。
hl.env("EDITOR", M.editor)

-- 笔记本专用触摸板设备；设备不存在时 Hyprland 会忽略该项。
hl.device({ name = "asue1209:00-04f3:319f-touchpad", enabled = true })

return M
