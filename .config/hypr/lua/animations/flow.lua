-- 动效方案：flow（流畅）。
-- 五套里时长最长（1.2s 级），窗口与工作区都走滑动 + 淡变，观感最沉稳从容。
-- 曲线用标准 ease-in-out-cubic：起步与收尾都慢、中段才加速，是「柔」的主要来源。
-- 覆盖全部可配 leaf：窗口开合/移动、工作区、特殊工作区、图层、各类淡变、缩放因子、边框。

local M = {}

-- 按用途分组的 leaf，避免逐条手写遗漏。
local WINDOWS = { "windows", "windowsIn", "windowsMove" }
local WORKSPACES = { "workspaces", "workspacesIn", "specialWorkspace", "specialWorkspaceIn" }
local LAYERS = { "layers", "layersIn" }
-- 淡变家族：窗口淡入淡出、暗化、阴影、切换、DPMS、发光、图层、弹窗。
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
-- 全局类：缩放因子、总开关曲线、发光角、阴影角、显示器接入。
local MISC = { "zoomFactor", "global", "glowangle", "shadowangle", "monitorAdded" }

-- 批量给一组 leaf 应用同一组参数；每个 leaf 单独建表，避免共享同一份 spec。
local function set(leaves, speed, curve, style)
	for _, leaf in ipairs(leaves) do
		local spec = { leaf = leaf, enabled = true, speed = speed, bezier = curve }
		if style then spec.style = style end
		hl.animation(spec)
	end
end

function M.apply()
	-- 缓入缓出（cubic）：起步与收尾都慢，中段才加速，过渡最顺。
	hl.curve("flowInOut", { type = "bezier", points = { { 0.645, 0.045 }, { 0.355, 1 } } })
	-- 柔和收尾（quad）：用于关窗/淡出，渐隐让位而不突兀。
	hl.curve("flowOut", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })
	-- 直线：边框用，无感。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	set(WINDOWS, 12, "flowInOut", "slidefade")
	set({ "windowsOut" }, 10, "flowOut", "slidefade")
	set(WORKSPACES, 12, "flowInOut", "slidefade")
	set({ "workspacesOut", "specialWorkspaceOut" }, 10, "flowOut", "slidefade")
	set(LAYERS, 10, "flowInOut", "slidefade")
	set({ "layersOut" }, 8, "flowOut", "slidefade")
	set(FADES, 9, "flowOut")
	set({ "fadeOut", "fadeLayersOut", "fadePopupsOut" }, 8, "flowOut")
	set(MISC, 10, "flowInOut")
	set({ "border" }, 6, "flat")
	hl.animation({ leaf = "borderangle", enabled = false })
end

return M
