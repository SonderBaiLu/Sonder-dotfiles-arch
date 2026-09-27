-- 窗口规则：把应用归类为标签（tag），再按标签或按 class/title 施加统一的浮动、透明、尺寸、模糊等规则。
-- 迁移时已去除重复规则、统一 KooL 标签命名、删除由 Noctalia 取代的旧规则。
--
-- 说明：
--   - tag 规则给窗口打「动态标签」（如 browser*），后续可用 match.tag 针对整组窗口设置效果。
--   - 静态效果（float/center/size/move/opacity 等）只在窗口创建时评估一次；
--     因此 title/class 匹配等价于 initial_title/initial_class。
--   - 规则按书写顺序生效，后写者覆盖先写者。

-- 辅助函数：给匹配 prop（class 或 title）的窗口打上标签。tag 自动加 "+" 前缀（添加动态标签）。
local function tag(prop, regex, name)
  hl.window_rule({ match = { [prop] = regex }, tag = "+" .. name })
end

-- ============================================================
-- 标签分类
-- ============================================================

-- 浏览器
tag("class", "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$", "browser")
tag("class", "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$", "browser")
tag("class", "^(chrome-.+-Default)$", "browser") -- Chrome 独立 WebApp 窗口
tag("class", "^([Cc]hromium)$", "browser")
tag("class", "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$", "browser")
tag("class", "^(Brave-browser(-beta|-dev|-unstable)?)$", "browser")
tag("class", "^([Tt]horium-browser|[Cc]achy-browser)$", "browser")
tag("class", "^(zen-alpha|zen)$", "browser") -- Zen 浏览器

-- 通知中心
tag("class", "^(swaync-control-center|swaync-notification-window|swaync-client|class)$", "notif")

-- KooL 配置工具（标签名统一为连字符形式）
tag("title", "^KooL Quick Cheat Sheet$", "KooL-Cheat")   -- 快捷键参考表
tag("title", "^KooL Hyprland Settings$", "KooL-Settings") -- 设置面板
tag("class", "^(nwg-displays|nwg-look)$", "KooL-Settings") -- 显示器/外观管理

-- 终端
tag("class", "^Alacritty$", "terminal")

-- 邮件客户端
tag("class", "^([Tt]hunderbird|org.mozilla.Thunderbird)$", "email")
tag("class", "^eu.betterbird.Betterbird$", "email") -- Betterbird（雷鸟分支）
tag("class", "^org.gnome.Evolution$", "email")

-- 项目 / 开发工具
tag("class", "^(codium|codium-url-handler|VSCodium)$", "projects")
tag("class", "^(VSCode|code|code-url-handler)$", "projects")
tag("class", "^jetbrains-.+$", "projects") -- 所有 JetBrains IDE
tag("class", "^(dev.zed.Zed|antigravity)$", "projects") -- Zed 编辑器

-- 屏幕共享 / 录制
tag("class", "^com.obsproject.Studio$", "screenshare")

-- 即时通讯
tag("class", "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$", "im")
tag("class", "^([Ff]erdium)$", "im") -- 多协议聚合客户端
tag("class", "^([Ww]hatsapp-for-linux)$", "im")
tag("class", "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$", "im")
tag("class", "^teams-for-linux$", "im")
tag("class", "^(im.riot.Riot|Element)$", "im") -- Matrix 客户端

-- 游戏窗口
tag("class", "^gamescope$", "games") -- Gamescope 微合成器
tag("class", "^steam_app_\\d+$", "games") -- Steam 游戏进程窗口（原配置的 \\d 为笔误，已修正）

-- 游戏商店 / 启动器
tag("class", "^([Ss]team)$", "gamestore")
tag("title", "^([Ll]utris)$", "gamestore") -- Lutris 按标题匹配
tag("class", "^com.heroicgameslauncher.hgl$", "gamestore")

-- 文件管理器
tag("class", "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$", "file-manager")
tag("class", "^app.drey.Warp$", "file-manager") -- Warp 文件传输工具

-- 壁纸工具
tag("class", "^([Ww]aytrogen)$", "wallpaper")

-- 多媒体（音频）
tag("class", "^([Aa]udacious)$", "multimedia")

-- 多媒体（视频）
tag("class", "^([Mm]pv|vlc)$", "multimedia_video")

-- 系统设置工具
tag("title", "^ROG Control$", "settings") -- 华硕 ROG 控制中心
tag("class", "^(gnome-disks|wihotspot(-gui)?)$", "settings") -- 磁盘工具 / 热点
tag("class", "^([Bb]aobab|org.gnome.[Bb]aobab)$", "settings") -- 磁盘使用分析器
tag("title", "^Kvantum Manager$", "settings") -- Qt 主题管理器
tag("class", "^(file-roller|org.gnome.FileRoller)$", "settings") -- 归档管理器
tag("class", "^(nm-applet|nm-connection-editor|blueman-manager)$", "settings") -- 网络 / 蓝牙
tag("class", "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$", "settings") -- 音量控制
tag("class", "^(qt5ct|qt6ct)$", "settings") -- Qt 配置工具
tag("class", "^xdg-desktop-portal-gtk$", "settings") -- 桌面门户
tag("class", "^org.kde.polkit-kde-authentication-agent-1$", "settings") -- 鉴权弹窗
tag("class", "^([Rr]ofi)$", "settings") -- 应用启动器
tag("class", "^btrfs-assistant$", "settings") -- Btrfs 管理工具
tag("class", "^timeshift-gtk$", "settings") -- 系统快照还原

-- 查看器（文档 / 系统监控）
tag("class", "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$", "viewer")
tag("class", "^evince$", "viewer") -- 文档查看器
tag("class", "^(eog|org.gnome.Loupe)$", "viewer") -- 图片查看器

-- ============================================================
-- 标签覆盖规则（无模糊 + 不透明）
-- ============================================================

-- 视频 / 音频窗口：关闭模糊，保持完全不透明（避免视频播放时模糊造成的性能与观感问题）。
hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video" }, opacity = "1.0" })
hl.window_rule({ match = { tag = "multimedia" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia" }, opacity = "1.0" })

-- ============================================================
-- 浮动规则（FLOAT）
-- ============================================================

-- 设置 / 查看器 / 壁纸 / KooL 面板统一浮动并居中。
hl.window_rule({ match = { tag = "settings" }, float = true, center = true })
hl.window_rule({ match = { title = "^Keybindings$" }, center = true }) -- 快捷键参考窗口居中（由快捷键脚本打开）
hl.window_rule({ match = { tag = "viewer" }, float = true, center = true })
hl.window_rule({ match = { tag = "wallpaper" }, float = true, center = true })
hl.window_rule({ match = { tag = "KooL-Cheat" }, float = true, center = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, float = true, center = true })

-- 指定应用浮动。
hl.window_rule({ match = { class = "^([Zz]oom|onedriver|onedriver-launcher)$" }, float = true }) -- 会议 / OneDrive
hl.window_rule({ match = { class = "^(org.gnome.Calculator|[Qq]alculate-gtk)$" }, float = true }) -- 计算器（去重）
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true }) -- 视频播放器
-- Ferdium：浮动 + 居中 + 指定尺寸（原为三条分散规则，合并为一）。
hl.window_rule({
  match = { class = "^([Ff]erdium)$" },
  float = true,
  center = true,
  size = { "monitor_w*0.6", "monitor_h*0.7" },
})

-- 弹窗与对话框（Popup / Dialogue）浮动。
hl.window_rule({ match = { title = "^Authentication Required$" }, float = true, center = true }) -- 鉴权弹窗
-- VSCodium / VSCode 子窗口（标题不含主窗口名）浮动。
hl.window_rule({
  match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },
  float = true,
})
-- Heroic Games Launcher 子窗口浮动。
hl.window_rule({
  match = { class = "^com.heroicgameslauncher.hgl$", title = "negative:(Heroic Games Launcher)" },
  float = true,
})
-- Steam 子窗口（好友列表、设置等）浮动。
hl.window_rule({
  match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
  float = true,
})
-- 文件对话框：浮动并指定尺寸居中。
hl.window_rule({ match = { title = "^Add Folder to Workspace$" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" }, center = true })
hl.window_rule({ match = { title = "^Save As$" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" }, center = true })
hl.window_rule({ match = { initial_title = "^Open Files$" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" } })
-- SDDM 背景设置窗口（很小）。
hl.window_rule({ match = { title = "^SDDM Background$" }, float = true, center = true, size = { "monitor_w*0.16", "monitor_h*0.12" } })
-- yad 通用对话框（小尺寸）。
hl.window_rule({ match = { class = "^yad$" }, float = true, center = true, size = { "monitor_w*0.2", "monitor_h*0.2" } })
-- Hyprland 捐赠提示窗口。
hl.window_rule({ match = { class = "^hyprland-donate-screen$" }, float = true, center = true })

-- ============================================================
-- 空闲抑制（Idle Inhibit）
-- ============================================================

-- 仅保留真正匹配「任意窗口全屏」这一条；原配置中另有 3 条通配/重复规则已删除。
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

-- ============================================================
-- 透明度规则（OPACITY）
-- 格式：opacity "<活动> <非活动>"
-- ============================================================

hl.window_rule({ match = { tag = "im" }, opacity = "0.94 0.86" }) -- 即时通讯
hl.window_rule({ match = { tag = "multimedia" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "settings" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" }) -- 简易文本编辑器
hl.window_rule({ match = { class = "^deluge$" }, opacity = "0.9 0.8" }) -- BitTorrent 客户端
hl.window_rule({ match = { class = "^seahorse$" }, opacity = "0.9 0.8" }) -- 密码 / 密钥管理
hl.window_rule({ match = { title = "^Picture-in-Picture$" }, opacity = "0.95 0.75" }) -- 画中画

-- ============================================================
-- 尺寸规则（SIZE）
-- 使用 monitor_w / monitor_h 表示显示器宽高比例
-- ============================================================

hl.window_rule({ match = { tag = "KooL-Cheat" }, size = { "monitor_w*0.65", "monitor_h*0.9" } }) -- 快捷键参考
hl.window_rule({ match = { tag = "wallpaper" }, size = { "monitor_w*0.7", "monitor_h*0.7" } }) -- 壁纸选择器
hl.window_rule({ match = { tag = "settings" }, size = { "monitor_w*0.7", "monitor_h*0.7" } }) -- 设置窗口

-- ============================================================
-- 模糊 / 全屏 / 焦点规则
-- ============================================================

-- 游戏窗口：关闭模糊，默认不全屏（由游戏自己决定），两条重复规则合并为一条。
hl.window_rule({ match = { tag = "games" }, no_blur = true, fullscreen = false })

-- JetBrains IDE 的弹出提示（如代码补全详情）不抢焦点，避免打断输入。
hl.window_rule({ match = { class = "^(jetbrains-.*)$" }, no_initial_focus = true })
-- 某些以 "wind" 开头的标题窗口（工具提示类）也不抢焦点。
hl.window_rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })

-- ============================================================
-- 具名窗口规则（Named Window Rules）
-- 具名规则可被动态启停，便于脚本精细控制。
-- ============================================================

-- Whatsapp 客户端（多种包名）专属规则：固定尺寸并居中。
hl.window_rule({
  name = "Whatsapp-zapzap",
  match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
  size = { "monitor_w*0.6", "monitor_h*0.7" },
  center = true,
})

-- 画中画（Picture-in-Picture）：浮动、置顶、保持宽高比、定位到右上区域。
hl.window_rule({
  name = "Picture-in-Picture",
  match = { title = "^Picture-in-Picture$" },
  float = true,
  move = "72% 7%", -- 屏幕右上区域（72% 水平，7% 垂直）
  opacity = "0.95 0.75",
  pin = true, -- 置顶，不随工作区切换
  keep_aspect_ratio = true,
  size = { "monitor_w*0.3", "monitor_h*0.3" },
})

-- Thunar 文件操作进度对话框：仅匹配进度条窗口，小尺寸居中浮动。
hl.window_rule({
  name = "Thunar-Progress-bar",
  match = { class = "^thunar$", title = "^File Operation Progress$" },
  float = true,
  center = true,
  size = { "monitor_w*0.26", "monitor_h*0.18" },
})

return true
