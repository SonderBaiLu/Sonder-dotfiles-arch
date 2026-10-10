-- 动效方案：fade（淡入淡出）。
-- 所有过渡以透明度变化为主、位移为辅，工作区直接交叉淡入淡出，观感最安静。

local M = {}

function M.apply()
	hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
	hl.curve("smoothIn", { type = "bezier", points = { { 0.5, -0.5 }, { 0.68, 1.5 } } })
	hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "liner", style = "slidefade" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "smoothIn", style = "slidefade" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "slidefade" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "liner", style = "slidefade" })
	hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "liner", style = "fade" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "smoothOut", style = "fade" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "smoothOut", style = "fade" })
end

return M
