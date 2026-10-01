-- Hyprland 原生 Lua 配置入口。
-- Hyprland 0.56+ 会优先读取本文件；模块通过 require() 加载。
-- 所有模块均只注册配置，不在回调中执行阻塞操作。

require("lua.defaults")
require("lua.environment")
require("lua.layout")
require("lua.appearance")
require("lua.rules")
require("lua.binds")
require("lua.startup")


