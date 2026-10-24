-- 动效方案：veil（淡入淡出）。
-- 以透明度变化为主：窗口 slidefade、工作区直接交叉淡入淡出（style=fade，无位移）。
-- 是这套里唯一「几乎不动只淡变」的方案，最安静。

local M = {}

function M.apply()
	-- 淡入曲线：柔和渐显。
	hl.curve("veilIn", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
	-- 淡出曲线：渐隐。
	hl.curve("veilOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "veilIn", style = "slidefade" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "veilIn", style = "slidefade" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "veilOut", style = "slidefade" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "veilIn", style = "slidefade" })
	hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "flat" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "veilOut" })
	-- 工作区用纯 fade，两个工作区交叉淡入淡出，没有滑动。
	hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "veilOut", style = "fade" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "veilIn", style = "fade" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "veilOut", style = "fade" })
	-- noctalia 面板层：与工作区一致，纯交叉淡入淡出，安静不抢戏。
	hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "veilOut", style = "fade" })
	hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "veilIn", style = "fade" })
	hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "veilOut", style = "fade" })
end

return M
