-- 动效方案：snap（干脆）。
-- 速度拉到最快（时长 0.1s）+ 近似直线的曲线，动画只提示状态变化、不拖节奏。
-- 与 flow 的慢滑正好相反：几乎瞬间到位。

local M = {}

function M.apply()
	-- 快曲线：起步极快，几乎直接到位。
	hl.curve("snapQ", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
	-- 直线：边框/淡入淡出用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "snapQ", style = "slide" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, bezier = "snapQ", style = "slide" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "snapQ", style = "slidefade" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "snapQ", style = "slide" })
	hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "flat" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "flat" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "snapQ", style = "slide" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1, bezier = "snapQ", style = "slide" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1, bezier = "snapQ", style = "slide" })
end

return M
