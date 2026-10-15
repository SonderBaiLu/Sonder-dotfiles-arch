-- 动效方案：drop（垂直落下）。
-- 唯一强调「竖向」的一套：工作区用 slidevert（上下滑动），开窗用 popin 缩放落下。
-- 与其余几套的水平滑动形成鲜明对比，切换方向一眼可辨。

local M = {}

function M.apply()
	-- 落下曲线：起步较快、末端轻收，像物体落下落定。
	hl.curve("dropIn", { type = "bezier", points = { { 0.18, 1 }, { 0.35, 1 } } })
	-- 收回曲线：向上收回。
	hl.curve("dropOut", { type = "bezier", points = { { 0.65, 0 }, { 0.55, 1 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "dropIn", style = "slidefade" })
	-- 新开窗口以 95% 缩放落下。
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "dropIn", style = "popin 95%" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "dropOut", style = "slidefade" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "dropIn", style = "slidefade" })
	hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "flat" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "dropOut" })
	-- 工作区用 slidevert，上下方向滑动。
	hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "dropIn", style = "slidevert" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "dropIn", style = "slidevert" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "dropOut", style = "slidevert" })
end

return M
