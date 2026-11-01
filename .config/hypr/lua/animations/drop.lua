-- 动效方案：drop（垂直落下）。
-- 唯一强调「竖向」的一套：工作区/图层用 slidevert（上下滑动），开窗用 popin 缩放落下。
-- 与其余几套的水平滑动形成鲜明对比，切换方向一眼可辨。
-- 覆盖全部可配 leaf：曲线走 ease-out（起步有推进感、末段缓慢落定），避免瞬移到位的突兀。

local M = {}

local WINDOWS = { "windows", "windowsMove" }
local WORKSPACES = { "workspaces", "workspacesIn", "specialWorkspace", "specialWorkspaceIn" }
local LAYERS = { "layers", "layersIn" }
local FADES = {
	"fade",
	"fadeIn",
	"fadeDim",
	"fadeShadow",
	"fadeSwitch",
	"fadeDpms",
	"fadeGlow",
	"fadeLayers",
	"fadeLayersIn",
	"fadePopups",
	"fadePopupsIn",
}
local MISC = { "zoomFactor", "global", "glowangle", "shadowangle", "monitorAdded" }

local function set(leaves, speed, curve, style)
	for _, leaf in ipairs(leaves) do
		local spec = { leaf = leaf, enabled = true, speed = speed, bezier = curve }
		if style then spec.style = style end
		hl.animation(spec)
	end
end

function M.apply()
	-- 落下曲线（ease-out cubic）：起步明确、末段自然减速，像物体落定。
	hl.curve("dropIn", { type = "bezier", points = { { 0.215, 0.61 }, { 0.355, 1 } } })
	-- 收回曲线（平滑收尾）：向上收回时柔和渐隐。
	hl.curve("dropOut", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	set(WINDOWS, 6, "dropIn", "slidefade")
	-- 新开窗口以 96% 缩放落下（缩放幅度收小，减少突兀感）。
	set({ "windowsIn" }, 6, "dropIn", "popin 96%")
	set({ "windowsOut" }, 5, "dropOut", "slidefade")
	-- 工作区与特殊工作区：竖向滑动。
	set(WORKSPACES, 7, "dropIn", "slidevert")
	set({ "workspacesOut", "specialWorkspaceOut" }, 6, "dropOut", "slidevert")
	-- 图层：竖向滑入滑出，强化「落下」的方向感。
	set(LAYERS, 6, "dropIn", "slidevert")
	set({ "layersOut" }, 5, "dropOut", "slidevert")
	set(FADES, 6, "dropOut")
	set({ "fadeOut", "fadeLayersOut", "fadePopupsOut" }, 5, "dropOut")
	set(MISC, 6, "dropIn")
	set({ "border" }, 4, "flat")
	hl.animation({ leaf = "borderangle", enabled = false })
end

return M
