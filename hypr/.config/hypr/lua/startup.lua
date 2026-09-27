-- 启动项：集中管理原 Startup_Apps.conf / Keybinds.conf 中的 exec-once。
-- 在 Hyprland 就绪后于 hl.on("hyprland.start") 回调中逐个执行。
-- 回调内只做一次性派发；hl.exec_cmd 会转到子进程执行，不会阻塞合成器事件循环。

local sc = require("lua.defaults").scripts

hl.on("hyprland.start", function()
  -- 壁纸守护进程（swww），由 noctalia 壁纸模块调度
  hl.exec_cmd("swww-daemon --format xrgb")

  -- 桌面环境与 systemd 用户会话环境同步
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Polkit 鉴权代理
  hl.exec_cmd(sc .. "/Polkit.sh")

  -- 空闲管理守护进程（锁屏 / 休眠 / DPMS）
  hl.exec_cmd("hypridle")

  -- Noctalia 外壳（启动器 / 状态栏 / 控制中心）
  hl.exec_cmd("noctalia")

  -- 剪贴板历史（cliphist），分别监听文本与图片
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- 键盘布局初始化
  hl.exec_cmd(sc .. "/KeybindsLayoutInit.sh")

  -- 布局初始化（原 exec-once = $scriptsDir/ChangeLayout.sh init）
  hl.exec_cmd(sc .. "/ChangeLayout.sh init")
end)

return true
