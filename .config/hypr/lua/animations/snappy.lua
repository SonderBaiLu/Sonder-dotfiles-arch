-- 动效方案：snappy（利落）。
-- 短时长 + 近似直线的曲线，动画只提示状态变化不拖节奏，适合嫌动效慢的场景。

local M = {}

function M.apply()
	hl.curve("quick", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
	hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "quick", style = "slide" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "quick", style = "slidefade" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "quick", style = "slidefade" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "quick", style = "slide" })
	hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "liner" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "quick", style = "slide" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2, bezier = "quick", style = "slide" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, bezier = "quick", style = "slide" })
end

return M
