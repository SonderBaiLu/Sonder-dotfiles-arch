-- 动效方案：snap（干脆）。
-- 五套里最快（0.3s 级）：强 ease-out 曲线让起步迅速、末段自然减速，快而不撞墙。
-- 覆盖全部可配 leaf；与 flow 的 1.2s 长滑形成最明显的节奏对比。

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
	-- 强 ease-out（quint）：前段快速推进，末段自然减速，快而不硬。
	hl.curve("snapQ", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	set(WINDOWS, 3, "snapQ", "slidefade")
	set({ "windowsOut" }, 3, "snapQ", "slidefade")
	set(WORKSPACES, 4, "snapQ", "slidefade")
	set({ "workspacesOut", "specialWorkspaceOut" }, 3, "snapQ", "slidefade")
	set(LAYERS, 3, "snapQ", "slidefade")
	set({ "layersOut" }, 3, "snapQ", "slidefade")
	set(FADES, 3, "snapQ")
	set({ "fadeOut", "fadeLayersOut", "fadePopupsOut" }, 3, "snapQ")
	set(MISC, 4, "snapQ")
	set({ "border" }, 2, "flat")
	hl.animation({ leaf = "borderangle", enabled = false })
end

return M
