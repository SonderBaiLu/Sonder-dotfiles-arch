-- 动效方案：bounce（弹跳）。
-- 弹簧曲线带轻微超调（冲过终点再小幅回弹）+ 开窗用 popin 缩放，手感活泼但不晃。
-- 弹簧参数用 0.56 起重写过的物理模型下的推荐值（stiffness 878.5 / dampening 59.29）；
-- 沿用旧版的小 stiffness 会让曲线在 0.56+ 变得拖沓，这是升级后必须改的点。
-- 覆盖全部可配 leaf：窗口与工作区、图层走弹簧，各类淡变与收向走沉降曲线。

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

-- 弹簧版批量设置：只有这几种曲线能给「弹」的手感。
local function spring(leaves, speed, style)
	for _, leaf in ipairs(leaves) do
		local spec = { leaf = leaf, enabled = true, speed = speed, spring = "boing" }
		if style then spec.style = style end
		hl.animation(spec)
	end
end

-- 贝塞尔版批量设置：用于「收」的动画，弹簧收尾会晃。
local function bez(leaves, speed, curve, style)
	for _, leaf in ipairs(leaves) do
		local spec = { leaf = leaf, enabled = true, speed = speed, bezier = curve }
		if style then spec.style = style end
		hl.animation(spec)
	end
end

function M.apply()
	-- 弹簧：轻阻尼，回弹一次即止。参数取 0.56+ 物理模型下的推荐值。
	hl.curve("boing", { type = "spring", mass = 1, stiffness = 878.5, dampening = 59.29 })
	-- 沉降曲线（ease-out quad）：关闭与淡出时柔和收住。
	hl.curve("settle", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })
	-- 直线：边框用。
	hl.curve("flat", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

	-- 开：弹簧 + 轻微缩放弹入。
	spring(WINDOWS, 5, "slidefade")
	spring({ "windowsIn" }, 5, "popin 94%")
	-- 收：沉降曲线收住，不用弹簧避免回弹。
	bez({ "windowsOut" }, 4, "settle", "popin 92%")
	spring(WORKSPACES, 6, "slidefade")
	bez({ "workspacesOut", "specialWorkspaceOut" }, 5, "settle", "slidefade")
	spring(LAYERS, 5, "slidefade")
	bez({ "layersOut" }, 4, "settle", "slidefade")
	bez(FADES, 5, "settle")
	bez({ "fadeOut", "fadeLayersOut", "fadePopupsOut" }, 4, "settle")
	spring(MISC, 5)
	bez({ "border" }, 3, "flat")
	hl.animation({ leaf = "borderangle", enabled = false })
end

return M
