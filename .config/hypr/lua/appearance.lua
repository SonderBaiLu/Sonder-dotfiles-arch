-- 外观与动画：主题色、边框、装饰、阴影、模糊、窗口组与动画曲线。
--
-- 主题色取自 Noctalia 静态色板（原 wallust 动态色已被 Noctalia 覆盖，故此处直接写死，
-- 避免「先由 wallust 上色、再被 Noctalia 覆盖」的无效覆盖）。
--
-- 曲线与动画已迁至 lua/animations/ 下的方案模块，登录与每次 reload 随机选一套，
-- 可用 Super+Alt+A 随机切换、或在 .pinned 文件里固定方案（见 animations/init.lua）。
require("lua.animations.init")

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
		border_size = 2, -- 边框宽度（像素）：2px 配合活动/非活动配色，保证多窗并排时焦点可辨
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
			size = 4, -- 模糊内核大小
			passes = 8, -- 模糊通道数
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
