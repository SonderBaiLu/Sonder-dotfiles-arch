-- 动效方案：flow（流畅）。
-- 慢速长滑：时长最长、缓入缓出曲线，窗口与工作区都走水平滑动，观感最沉稳从容。
-- noctalia 面板层同样长滑入、利落收走，与整体节奏一致。

local M = {}

function M.apply()
	-- 缓入缓出：起步与收尾都柔和，中段最快。
	hl.curve("flowInOut", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
	-- 收尾快速：用于关闭窗口，尽快让位。
	hl.curve("flowOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
	-- 直线：边框用，无感。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 8, bezier = "flowInOut", style = "slide" })
	hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "flowInOut", style = "slide" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "flowOut", style = "slidefade" })
	hl.animation({ leaf = "windowsMove", enabled = true, speed = 8, bezier = "flowInOut", style = "slide" })
	hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "flat" })
	hl.animation({ leaf = "borderangle", enabled = false })
	hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "flowOut" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "flowInOut", style = "slide" })
	hl.animation({ leaf = "workspacesIn", enabled = true, speed = 7, bezier = "flowInOut", style = "slide" })
	hl.animation({ leaf = "workspacesOut", enabled = true, speed = 7, bezier = "flowInOut", style = "slide" })
	-- noctalia 面板（layers 层）：滑入带淡变，收走快半拍不让面板拖泥带水。
	hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "flowInOut", style = "slidefade" })
	hl.animation({ leaf = "layersIn", enabled = true, speed = 6, bezier = "flowInOut", style = "slidefade" })
	hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "flowOut", style = "slidefade" })
end

return M
