-- 动效方案：veil（淡入淡出）。
-- 以透明度变化为主：窗口 slidefade、工作区与图层直接交叉淡入淡出（style=fade，无位移）。
-- 是这套里唯一「几乎不动只淡变」的方案，最安静。
-- 覆盖全部可配 leaf：淡变家族与窗口开合都走同一套柔和曲线，全程无突兀明暗跳变。

local M = {}

local WINDOWS = { "windows", "windowsIn", "windowsMove" }
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
	-- 淡入曲线（ease-in-out cubic）：柔和渐显。
	hl.curve("veilIn", { type = "bezier", points = { { 0.645, 0.045 }, { 0.355, 1 } } })
	-- 淡出曲线（ease-out quad）：平缓渐隐。
	hl.curve("veilOut", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	set(WINDOWS, 8, "veilIn", "slidefade")
	set({ "windowsOut" }, 7, "veilOut", "slidefade")
	-- 工作区与特殊工作区：纯交叉淡入淡出，没有位移。
	set(WORKSPACES, 8, "veilIn", "fade")
	set({ "workspacesOut", "specialWorkspaceOut" }, 8, "veilOut", "fade")
	-- 图层同样纯淡变，安静不抢戏。
	set(LAYERS, 8, "veilIn", "fade")
	set({ "layersOut" }, 7, "veilOut", "fade")
	set(FADES, 8, "veilOut")
	set({ "fadeOut", "fadeLayersOut", "fadePopupsOut" }, 7, "veilOut")
	set(MISC, 8, "veilIn")
	set({ "border" }, 5, "flat")
	hl.animation({ leaf = "borderangle", enabled = false })
end

return M
