-- Hyprland 原生 Lua 配置入口。
-- Hyprland 0.56+ 会优先读取本文件；模块通过 require() 加载。
-- 所有模块均只注册配置，不在回调中执行阻塞操作。

require("lua.defaults")
require("lua.environment")
require("lua.layout")
require("lua.appearance")
require("lua.rules")
require("lua.behavior")
require("lua.binds")
require("lua.plugins")
require("lua.startup")



-- For Noctalia Color templates
require("noctalia").apply_theme()


-- >>> HYPRLAND VISUAL EDITOR (HVE) <<<
pcall(function() dofile(os.getenv("HOME") .. "/.cache/noctalia/HVE/overlay.lua") end)
-- <<< HYPRLAND VISUAL EDITOR (HVE) <<<
