-- Hyprland 插件配置。
-- hyprpm 在启动回调中加载插件；首次启动时插件尚未注册，跳过配置即可。

-- 允许官方插件管理器加载共享库，避免每次启动都弹权限确认。
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

if hl.plugin.dynamic_cursors then
	hl.config({
		plugin = {
			dynamic_cursors = {
				enabled = true,
				mode = "tilt",
				threshold = 2,
				tilt = {
					limit = 5000,
					activation = "negative_quadratic",
					window = 100,
					full = 60,
				},
				shake = {
					enabled = true,
					threshold = 6.0,
					base = 4.0,
					speed = 4.0,
					limit = 0.0,
					timeout = 2000,
					effects = false,
				},
				hyprcursor = {
					enabled = true,
					nearest = 1,
					resolution = -1,
					fallback = "clientside",
				},
			},
		},
	})
end

return true
