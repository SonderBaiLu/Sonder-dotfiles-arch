-- 动效方案随机加载器。
-- 每次加载配置（登录、hyprctl reload）都会从本目录的方案中随机选一套生效；
-- 想固定某套方案时，把方案名写入同目录的 .pinned 文件（如 "flow"），
-- 文件留空或删除即恢复随机。
--
-- 为避免「随机抽出来却和上次一样、看不出换没换」，加载器记住上一次抽中的方案
-- （.last），本次若与上次相同就重抽，保证连续 Super+Alt+A 切换一定有肉眼可见的变化。
-- 当前生效方案名同时写入 .current，方便随时查看。
--
-- 各方案文件须返回带 apply() 函数的模块，函数体里注册 hl.curve / hl.animation。
-- 动画 speed 的单位是 1/10 秒（动画时长），数值越大动画越慢。

local PRESETS = { "flow", "snap", "bounce", "veil", "drop" }

local dir = os.getenv("HOME") .. "/.config/hypr/lua/animations"
local pinned_path = dir .. "/.pinned"
local last_path = dir .. "/.last"
local current_path = dir .. "/.current"

-- 读取单行文本并去首尾空白；文件不存在返回 nil。
local function read_line(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local line = f:read("*l") or ""
	f:close()
	return (line:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function write_line(path, val)
	local f = io.open(path, "w")
	if not f then return end
	f:write(val .. "\n")
	f:close()
end

-- .pinned 里的名字必须是已登记的方案，否则视为无效、回退随机。
local valid = {}
for _, name in ipairs(PRESETS) do valid[name] = true end

local pinned = read_line(pinned_path)
local last = read_line(last_path)

local chosen
if pinned and valid[pinned] then
	-- 固定模式：直接用指定方案。
	chosen = pinned
else
	-- 随机模式。
	math.randomseed(os.time() + math.floor(os.clock() * 1000000))
	if #PRESETS >= 2 then
		-- 多套则重抽到不同于上一次；只有一套时无所谓重复。
		repeat
			chosen = PRESETS[math.random(#PRESETS)]
		until chosen ~= last
	else
		chosen = PRESETS[1]
	end
end

require("lua.animations." .. chosen).apply()

-- 记录本次结果，供下次去重与人工查看。
write_line(last_path, chosen)
write_line(current_path, chosen)

-- 通知当前方案；配置冷启动时通知系统可能未就绪，失败可忽略。
pcall(hl.notification.create, {
	text = "窗口动效：" .. chosen .. (pinned and "（已固定）" or "（随机）"),
	timeout = 3500,
	font_size = 14,
})

return true
