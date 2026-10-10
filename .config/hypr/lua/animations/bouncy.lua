-- 动效方案：bouncy（弹跳）。
-- 超调曲线（曲线越过 1 再回落）+ popin 缩放，开窗和移动带轻微回弹，手感活泼。

local M = {}

function M.apply()
	hl.curve("springy", { type = "bezier", points = { { 0.1, -0.35 }, { 0.35, 1.25 } } })
	hl.curve("settle", { type = "bezier", points = { { 0.2, 0.8 }, { 0.3, 1.05 } } })
	hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "springy", style = "slide" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "springy", style = "popin" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "settle", style = "slide" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "springy", style = "slide" })
	hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "settle" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "springy", style = "slide" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "springy", style = "slide" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "settle", style = "slide" })
end

return M
