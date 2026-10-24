-- 动效方案：bounce（弹跳）。
-- 弹簧曲线带超调（冲过终点再回弹）+ 开窗用 popin 缩放，手感活泼有弹性。
-- 与 snap 的直线、flow 的平滑完全不同，是这里唯一带物理回弹的一套。

local M = {}

function M.apply()
	-- 弹簧：欠阻尼，冲过目标后小幅回弹，越欠阻尼越弹。
	hl.curve("boing", { type = "spring", mass = 1, stiffness = 170, dampening = 12 })
	-- 沉降曲线：关闭窗口时用，快速收住。
	hl.curve("settle", { type = "bezier", points = { { 0.2, 0.8 }, { 0.3, 1.05 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "boing", style = "slide" })
	-- 新开窗口以 90% 缩放弹入。
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "boing", style = "popin 90%" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "settle", style = "popout 85%" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, spring = "boing", style = "slide" })
	hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "flat" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "settle" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "boing", style = "slide" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, spring = "boing", style = "slide" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "settle", style = "slide" })
	-- noctalia 面板层：滑入带回弹，收走速战速决。
	hl.animation({ leaf = "layers", enabled = true, speed = 3, spring = "boing", style = "slidefade" })
	hl.animation({ leaf = "layersIn", enabled = true, speed = 4, spring = "boing", style = "slidefade" })
	hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "settle", style = "slidefade" })
end

return M
