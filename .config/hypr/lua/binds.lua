-- 快捷键绑定（含桌面快捷键与笔记本 Fn 键）。
-- 迁移期间修复：
--   - 合并重复的 Alt+Tab（原为 cyclenext 与 bringactivetotop 两条）；
--   - 删除与 Print 截图组重复的 F6 截图组；
--   - 解决 Super+Tab / Super+Shift+Tab 同时被「群组导航」与「工作区切换」占用的冲突；
--   - 键名统一为 xkbcommon keysym（大小写敏感：tab→Tab、SPACE→space、left/right/up/down 小写）。

local M   = require("lua.defaults")
local MOD = M.main_mod  -- 主修饰键 SUPER
local sc  = M.scripts   -- 脚本目录 $HOME/.config/hypr/scripts

-- 桌面放大镜（光标缩放）常量：最小 1 倍、最大 3 倍，鼠标缩放每次 ×2 / ÷2。
local MIN_ZOOM = 1
local MAX_ZOOM = 3
local function cursor_zoom(factor)
  local cur = hl.get_config("cursor.zoom_factor")
  hl.config({ cursor = { zoom_factor = math.max(MIN_ZOOM, math.min(MAX_ZOOM, cur * factor)) } })
end

-- ============================================================
-- 通用快捷键（打开应用）
-- ============================================================

hl.bind(MOD .. " + B",      hl.dsp.exec_cmd('xdg-open "https://"'), { description = "打开默认浏览器" })
hl.bind(MOD .. " + Return", hl.dsp.exec_cmd(M.terminal),            { description = "打开终端" })
hl.bind(MOD .. " + E",      hl.dsp.exec_cmd(M.files),               { description = "打开文件管理器" })

-- ============================================================
-- 特色功能 / 附加组件
-- ============================================================

hl.bind(MOD .. " + ALT + R",       hl.dsp.exec_cmd(sc .. "/Refresh.sh"),     { description = "刷新状态栏和菜单" })
hl.bind(MOD .. " + ALT + O",       hl.dsp.exec_cmd(sc .. "/ChangeBlur.sh"),  { description = "开启/关闭模糊效果" })
hl.bind(MOD .. " + SHIFT + G",     hl.dsp.exec_cmd(sc .. "/GameMode.sh"),    { description = "开启/关闭游戏模式" })
hl.bind(MOD .. " + ALT + L",       hl.dsp.exec_cmd(sc .. "/ChangeLayout.sh"),{ description = "切换 Master/Dwindle 窗口布局" })
hl.bind(MOD .. " + SHIFT + F",     hl.dsp.window.fullscreen(),               { description = "全屏切换" })
hl.bind(MOD .. " + CTRL + F",      hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "最大化窗口 (保留状态栏)" })
hl.bind(MOD .. " + SPACE",         hl.dsp.window.float(),                    { description = "浮动当前窗口" })
hl.bind(MOD .. " + ALT + SPACE",   hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"), { description = "浮动所有窗口" })
hl.bind(MOD .. " + SHIFT + Return",hl.dsp.exec_cmd(sc .. "/Dropterminal.sh " .. M.terminal), { description = "下拉式终端" })

-- ============================================================
-- Noctalia v5+ 核心外壳快捷键（通过 IPC：noctalia msg）
-- ============================================================

hl.bind(MOD .. " + D",             hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"),      { description = "主应用启动器 / 全局搜索" })
hl.bind(MOD .. " + SHIFT + N",     hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"), { description = "控制中心与通知面板" })
hl.bind(MOD .. " + V",             hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"),      { description = "剪贴板历史记录" })
hl.bind(MOD .. " + W",             hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"),      { description = "壁纸选择器" })
hl.bind("CTRL + ALT + P",          hl.dsp.exec_cmd("noctalia msg panel-toggle session"),        { description = "电源与注销/会话菜单" })
hl.bind(MOD .. " + SHIFT + E",     hl.dsp.exec_cmd("noctalia msg settings-toggle"),             { description = "Noctalia 设置中心" })
hl.bind(MOD .. " + Z",             hl.dsp.exec_cmd("noctalia msg settings-toggle"),             { description = "Noctalia 设置中心" })
hl.bind(MOD .. " + CTRL + ALT + B",hl.dsp.exec_cmd("noctalia msg bar-toggle"),                  { description = "顶部状态栏显示/隐藏切换" })

-- 启动器前缀直达
hl.bind(MOD .. " + ALT + E",       hl.dsp.exec_cmd('noctalia msg panel-toggle launcher "/emo "'),  { description = "Emoji 快速选择器" })
hl.bind(MOD .. " + ALT + C",       hl.dsp.exec_cmd('noctalia msg panel-toggle launcher "/calc "'), { description = "快速计算器 / 汇率换算" })
hl.bind(MOD .. " + CTRL + S",      hl.dsp.exec_cmd('noctalia msg panel-toggle launcher "/win "'),  { description = "正在运行的窗口快速跳转" })

-- ============================================================
-- 桌面缩放 / 放大镜（改用 Lua 函数，避免每次 spawn 子进程）
-- ============================================================

hl.bind(MOD .. " + ALT + mouse_down", function() cursor_zoom(2.0) end,    { description = "放大桌面" })
hl.bind(MOD .. " + ALT + mouse_up",   function() cursor_zoom(1 / 2.0) end,{ description = "缩小桌面" })

-- ============================================================
-- 夜间护眼 / 壁纸 / 透明度
-- ============================================================

hl.bind(MOD .. " + N",          hl.dsp.exec_cmd(sc .. "/Hyprsunset.sh toggle"), { description = "切换夜间模式" })
hl.bind("CTRL + ALT + W",       hl.dsp.exec_cmd(sc .. "/WallpaperRandom.sh"),    { description = "随机更换壁纸" })
-- 原 setprop active opaque toggle 没有对应的 Lua 布尔翻转 API，这里直接用 hyprctl 等价执行。
hl.bind(MOD .. " + CTRL + O",   hl.dsp.exec_cmd("hyprctl dispatch setprop active opaque toggle"), { description = "切换当前窗口透明度" })

-- ============================================================
-- 键盘布局（绑定纯修饰键，顺序即按键顺序）
-- ============================================================

hl.bind("Alt_L + Shift_L",      hl.dsp.exec_cmd(sc .. "/KeyboardLayout.sh switch"), { locked = true, non_consuming = true, description = "全局切换键盘布局" })
hl.bind("Shift_L + Alt_L",      hl.dsp.exec_cmd(sc .. "/Tak0-Per-Window-Switch.sh"),{ locked = true, non_consuming = true, description = "按窗口切换键盘布局" })

-- ============================================================
-- 多显示器：把当前工作区移到指定方向的显示器
-- ============================================================

hl.bind(MOD .. " + CTRL + F9",  hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor l"), { description = "将工作区移至左侧显示器" })
hl.bind(MOD .. " + CTRL + F10", hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor r"), { description = "将工作区移至右侧显示器" })
hl.bind(MOD .. " + CTRL + F11", hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor u"), { description = "将工作区移至上方显示器" })
hl.bind(MOD .. " + CTRL + F12", hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor d"), { description = "将工作区移至下方显示器" })

-- ============================================================
-- 系统控制
-- ============================================================

hl.bind("CTRL + ALT + Delete",  hl.dsp.exit(),                        { description = "退出 Hyprland 环境" })
hl.bind(MOD .. " + Q",          hl.dsp.window.close(),               { description = "关闭当前窗口" })
hl.bind(MOD .. " + SHIFT + Q",  hl.dsp.exec_cmd(sc .. "/KillActiveProcess.sh"), { description = "强制结束当前进程" })
hl.bind("CTRL + ALT + L",       hl.dsp.exec_cmd(sc .. "/LockScreen.sh"),       { description = "锁定屏幕" })

-- ============================================================
-- Master 布局专用快捷键
-- ============================================================

hl.bind(MOD .. " + CTRL + D",       hl.dsp.layout("removemaster"),    { description = "移除 Master 窗口" })
hl.bind(MOD .. " + I",              hl.dsp.layout("addmaster"),       { description = "添加为 Master 窗口" })
hl.bind(MOD .. " + CTRL + Return",  hl.dsp.layout("swapwithmaster"),  { description = "与 Master 窗口互换位置" })

-- Dwindle 布局专用快捷键
hl.bind(MOD .. " + P",              hl.dsp.window.pseudo(),           { description = "切换伪平铺模式" })

-- 通用布局快捷键（Master / Dwindle 通用）
hl.bind(MOD .. " + M",              hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"), { description = "设置窗口分割比例为 0.3" })

-- ============================================================
-- 循环切换窗口（合并 Alt+Tab 两条：先切换、再置顶）
-- ============================================================

hl.bind("ALT + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "切换到下一个窗口" })

-- ============================================================
-- 多媒体与特殊功能按键（F1-F12 上的功能键）
-- ============================================================

-- 音量（可重复、锁屏时也生效）
hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd(sc .. "/Volume.sh --inc"),         { repeating = true, locked = true, description = "提高音量" })
hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd(sc .. "/Volume.sh --dec"),         { repeating = true, locked = true, description = "降低音量" })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(sc .. "/Volume.sh --inc-precise"), { repeating = true, locked = true, description = "微调提高音量" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(sc .. "/Volume.sh --dec-precise"), { repeating = true, locked = true, description = "微调降低音量" })

-- 静音 / 休眠 / 飞行模式（锁屏时也生效）
hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd(sc .. "/Volume.sh --toggle-mic"), { locked = true, description = "麦克风静音切换" })
hl.bind("XF86AudioMute",          hl.dsp.exec_cmd(sc .. "/Volume.sh --toggle"),     { locked = true, description = "扬声器静音切换" })
hl.bind("XF86Sleep",              hl.dsp.exec_cmd("systemctl suspend"),             { locked = true, description = "休眠系统" })
hl.bind("XF86Rfkill",             hl.dsp.exec_cmd(sc .. "/AirplaneMode.sh"),        { locked = true, description = "飞行模式切换" })

-- 媒体播放控制
-- 注：原配置中的 xf86AudioPlayPause 并非合法键名（Hyprland 报 "Unknown keysym"），
-- 已用合法的 XF86AudioPlay / XF86AudioPause 两键替代。
hl.bind("XF86AudioPause",         hl.dsp.exec_cmd(sc .. "/MediaCtrl.sh --pause"), { locked = true, description = "暂停" })
hl.bind("XF86AudioPlay",          hl.dsp.exec_cmd(sc .. "/MediaCtrl.sh --pause"), { locked = true, description = "播放" })
hl.bind("XF86AudioNext",          hl.dsp.exec_cmd(sc .. "/MediaCtrl.sh --nxt"),   { locked = true, description = "下一首" })
hl.bind("XF86AudioPrev",          hl.dsp.exec_cmd(sc .. "/MediaCtrl.sh --prv"),   { locked = true, description = "上一首" })
hl.bind("XF86AudioStop",          hl.dsp.exec_cmd(sc .. "/MediaCtrl.sh --stop"),  { locked = true, description = "停止播放" })

-- ============================================================
-- 截图快捷键
-- ============================================================

-- Print：直接截取全屏，保存并复制到剪切板
hl.bind("Print",
        hl.dsp.exec_cmd(sc .. "/ScreenShot.sh --now"),
        { description = "全屏截图并复制到剪切板" })

-- Mod + Shift + S：框选区域，保存并复制到剪切板
hl.bind(MOD .. " + SHIFT + S",
        hl.dsp.exec_cmd(sc .. "/ScreenShot.sh --area"),
        { description = "框选截图并复制到剪切板" })

-- Alt + Print：框选区域，保存后用 Swappy 打开编辑
hl.bind("ALT + Print",
        hl.dsp.exec_cmd(sc .. "/ScreenShot.sh --edit"),
        { description = "框选截图并打开 Swappy 编辑" })

-- ============================================================
-- 调整窗口尺寸（可重复触发）
-- ============================================================

hl.bind(MOD .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true, description = "窗口向左缩小" })
hl.bind(MOD .. " + SHIFT + right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true, description = "窗口向右放大" })
hl.bind(MOD .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true, description = "窗口向上缩小" })
hl.bind(MOD .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true, description = "窗口向下放大" })

-- ============================================================
-- 移动窗口位置 / 交换窗口位置
-- ============================================================

hl.bind(MOD .. " + CTRL + left",   hl.dsp.window.move({ direction = "l" }), { description = "窗口向左移动" })
hl.bind(MOD .. " + CTRL + right",  hl.dsp.window.move({ direction = "r" }), { description = "窗口向右移动" })
hl.bind(MOD .. " + CTRL + up",     hl.dsp.window.move({ direction = "u" }), { description = "窗口向上移动" })
hl.bind(MOD .. " + CTRL + down",   hl.dsp.window.move({ direction = "d" }), { description = "窗口向下移动" })

hl.bind(MOD .. " + ALT + left",    hl.dsp.window.swap({ direction = "l" }), { description = "与左侧窗口互换" })
hl.bind(MOD .. " + ALT + right",   hl.dsp.window.swap({ direction = "r" }), { description = "与右侧窗口互换" })
hl.bind(MOD .. " + ALT + up",      hl.dsp.window.swap({ direction = "u" }), { description = "与上方窗口互换" })
hl.bind(MOD .. " + ALT + down",    hl.dsp.window.swap({ direction = "d" }), { description = "与下方窗口互换" })

-- ============================================================
-- 窗口群组管理（Group）
-- ============================================================

hl.bind(MOD .. " + G",                 hl.dsp.group.toggle(), { description = "开启/关闭窗口编组" })

-- 群组内导航：
-- 原配置中 Super+Tab / Super+Shift+Tab 同时被「群组导航」与「工作区切换」占用，属重复绑定。
-- 此处保留群组导航（changegroupactive f/b），工作区切换改用滚轮 / period / comma（见下方）。
-- 另：Super+Ctrl+Tab 的原 changegroupactive（无参数）等价于向前切换，保留其功能。
hl.bind(MOD .. " + Tab",          hl.dsp.group.next(), { description = "切换到组内下一个窗口" })
hl.bind(MOD .. " + SHIFT + Tab",  hl.dsp.group.prev(), { description = "切换到组内上一个窗口" })
hl.bind(MOD .. " + CTRL + Tab",   hl.dsp.group.next(), { description = "切换到组内下一个窗口" })

-- 窗口移入/移出群组
hl.bind(MOD .. " + CTRL + K",          hl.dsp.window.move({ into_group = "l" }), { description = "将窗口向左移入群组" })
hl.bind(MOD .. " + CTRL + L",          hl.dsp.window.move({ into_group = "r" }), { description = "将窗口向右移入群组" })
hl.bind(MOD .. " + CTRL + H",          hl.dsp.window.move({ out_of_group = true }), { description = "将窗口移出群组" })

-- ============================================================
-- 改变焦点方向
-- ============================================================

hl.bind(MOD .. " + left",   hl.dsp.focus({ direction = "left" }),  { description = "焦点向左移动" })
hl.bind(MOD .. " + right",  hl.dsp.focus({ direction = "right" }), { description = "焦点向右移动" })
hl.bind(MOD .. " + up",     hl.dsp.focus({ direction = "up" }),    { description = "焦点向上移动" })
hl.bind(MOD .. " + down",   hl.dsp.focus({ direction = "down" }),  { description = "焦点向下移动" })

-- ============================================================
-- 工作区切换 / 特殊工作区
-- ============================================================

-- 特殊工作区（后台收纳工作区，默认名 magic）
hl.bind(MOD .. " + SHIFT + U",  hl.dsp.window.move({ workspace = "special:magic" }), { description = "将窗口放入特殊工作区" })
hl.bind(MOD .. " + U",          hl.dsp.workspace.toggle_special("magic"),           { description = "显示/隐藏特殊工作区" })

-- 切换工作区 1-10（focus / 携带移动 / 静默发送，三组绑定）
for i = 1, 10 do
  local code = "code:" .. (9 + i) -- code:10 ~ code:19 对应数字键 1~10
  hl.bind(MOD .. " + " .. code,        hl.dsp.focus({ workspace = i }),              { description = "切换到工作区 " .. i })
  hl.bind(MOD .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }),        { description = "携带窗口至工作区 " .. i })
  hl.bind(MOD .. " + CTRL + " .. code,  hl.dsp.window.move({ workspace = i, follow = false }), { description = "静默发送至工作区 " .. i })
end

-- 携带/静默移动到相邻工作区
hl.bind(MOD .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }),                 { description = "携带窗口至上一个工作区" })
hl.bind(MOD .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }),                 { description = "携带窗口至下一个工作区" })
hl.bind(MOD .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }), { description = "静默发送至上一个工作区" })
hl.bind(MOD .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "静默发送至下一个工作区" })

-- 鼠标滚轮 / 按键切换工作区
hl.bind(MOD .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "滚轮切换至下一个工作区" })
hl.bind(MOD .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "滚轮切换至上一个工作区" })
hl.bind(MOD .. " + period",     hl.dsp.focus({ workspace = "e+1" }), { description = "按键切换至下一个工作区" })
hl.bind(MOD .. " + comma",      hl.dsp.focus({ workspace = "e-1" }), { description = "按键切换至上一个工作区" })

-- ============================================================
-- 鼠标拖拽（mouse:272 左键拖动、mouse:273 右键调整大小）
-- ============================================================

hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "按住拖动窗口位置" })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "按住调整窗口大小" })

-- ============================================================
-- 笔记本 Fn 键（XF86 功能键：背光/亮度/触控板/华硕 ROG 专用键）
-- ============================================================

-- 键盘背光亮度（可重复）
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(sc .. "/BrightnessKbd.sh --dec"), { repeating = true })
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(sc .. "/BrightnessKbd.sh --inc"), { repeating = true })

-- 华硕 ROG 专用按键
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"))
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))

-- 屏幕亮度（可重复）
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(sc .. "/Brightness.sh --dec"), { repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(sc .. "/Brightness.sh --inc"), { repeating = true })

-- 触控板开关
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(sc .. "/TouchPad.sh"))

return true
