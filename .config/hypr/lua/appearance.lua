-- 外观与动画：主题色、边框、装饰、阴影、模糊、窗口组与动画曲线。
--
-- 主题色取自 Noctalia 静态色板（原 wallust 动态色已被 Noctalia 覆盖，故此处直接写死，
-- 避免「先由 wallust 上色、再被 Noctalia 覆盖」的无效覆盖）。

-- 动画速度单位是 1/10 秒（decisecond），数值越大动画越快。
-- 下面把原 bezier 定义迁移为 hl.curve，把 animation 定义迁移为 hl.animation。

hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.5, -0.5 }, { 0.68, 1.5 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
-- 注意：borderangle 使用 style="loop" 会让边框角持续渲染，
-- 会提高 CPU/GPU 占用与耗电，仅在需要动态边框角效果时保留。
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })

-- 静态主题色（Noctalia 色板）。
-- primary 用于活动边框/输入框外框，surface 用于非活动边框/背景。
local primary = "rgb(cba6f7)" -- 活动边框
local surface = "rgb(1e1e2e)" -- 非活动边框 / 背景
local secondary = "rgb(fab387)" -- 群组活动
local error = "rgb(f38ba8)" -- 群组锁定活动 / 失败色
local tertiary = "rgb(94e2d5)" -- 校验色
local surface_lowest = "rgb(212232)" -- 更深背景

hl.config({
	general = {
		border_size = 1, -- 边框宽度（像素）
		gaps_in = 2, -- 窗口内边距
		gaps_out = 4, -- 窗口之间空隙

		col = {
			active_border = primary, -- 活动窗口边框色
			inactive_border = surface, -- 非活动窗口边框色
		},
	},

	decoration = {
		rounding = 5, -- 窗口圆角（像素）

		active_opacity = 1.0, -- 活动窗口透明度
		inactive_opacity = 1.0, -- 非活动窗口透明度
		fullscreen_opacity = 1.0, -- 全屏窗口透明度

		dim_inactive = false, -- 是否暗化非活动窗口
		dim_strength = 0.1, -- 暗化强度
		dim_special = 0.8, -- 特殊工作区暗化强度

		shadow = {
			enabled = true,
			range = 3, -- 阴影扩散范围
			render_power = 6, -- 阴影渲染强度
			color = primary, -- 阴影颜色（活动，替换原 wallust $color12）
			color_inactive = surface, -- 阴影颜色（非活动，替换原 wallust $color10）
		},

		blur = {
			enabled = true,
			size = 2, -- 模糊内核大小
			passes = 4, -- 模糊通道数
			new_optimizations = true, -- 启用新版模糊优化
			xray = true, -- 穿透模糊
			ignore_opacity = true, -- 忽略窗口透明度
			special = true, -- 特殊工作区也启用模糊
			popups = true, -- 弹出层也启用模糊
		},
	},

	group = {
		col = {
			border_active = secondary, -- 群组活动边框
			border_inactive = surface, -- 群组非活动边框
			border_locked_active = error, -- 群组锁定活动边框
			border_locked_inactive = surface, -- 群组锁定非活动边框
		},

		groupbar = {
			col = {
				active = secondary, -- 群组栏活动项
				inactive = surface, -- 群组栏非活动项
				locked_active = error, -- 群组栏锁定活动项
				locked_inactive = surface, -- 群组栏锁定非活动项
			},
		},
	},
})

return true
