-- 动效方案：popin（缩放）。
-- 窗口开/关以缩放（popin）呈现，工作区切换用交叉淡入淡出，接近 macOS 的弹窗质感。

local M = {}

function M.apply()
	hl.curve("pop", { type = "bezier", points = { { 0.2, 0.9 }, { 0.3, 1.1 } } })
	hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
	hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "pop", style = "slide" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "pop", style = "popin" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "popin" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "pop", style = "slide" })
	hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "liner", style = "fade" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "pop", style = "slide" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "smoothOut", style = "slide" })
end

return M
