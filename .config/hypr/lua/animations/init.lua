-- 动效方案随机加载器。
-- 每次加载配置（登录、hyprctl reload）都会从本目录的方案中随机选一套生效；
-- 想固定某套方案时，把方案名写入同目录的 .pinned 文件（如 "smooth"），
-- 文件留空或删除即恢复随机。
-- 各方案文件须返回带 apply() 函数的模块，函数体里注册 hl.curve / hl.animation。
-- 动画 speed 的单位是 1/10 秒（动画时长），数值越大动画越慢。

local PRESETS = { "smooth", "snappy", "bouncy", "popin", "fade" }
local pinned_path = os.getenv("HOME") .. "/.config/hypr/lua/animations/.pinned"

local function read_pin()
  local f = io.open(pinned_path, "r")
  if not f then return nil end
  local name = f:read("*l") or ""
  f:close()
  return (name:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- .pinned 里的名字必须是已登记的方案，否则视为无效、回退随机。
local valid = {}
for _, name in ipairs(PRESETS) do valid[name] = true end

local pinned = read_pin()
local chosen = pinned
if not (chosen and valid[chosen]) then
  chosen = nil
  pinned = nil
  math.randomseed(os.time() * 1000 + math.floor(os.clock() * 1000000))
  chosen = PRESETS[math.random(#PRESETS)]
end

require("lua.animations." .. chosen).apply()

-- 启动器/状态栏提示当前方案；配置冷启动时通知系统可能未就绪，失败可忽略。
pcall(hl.notification.create, {
  text = "窗口动效：" .. chosen .. (pinned and "（已固定）" or "（随机）"),
  timeout = 4000,
  font_size = 14,
})

return true
