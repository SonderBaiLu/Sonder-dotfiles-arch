-- 核心布局、输入、手势与渲染设置。
-- 键名使用 Hyprland Lua 的层级表写法：冒号改为嵌套表，连字符改为下划线。

hl.config({
  -- Dwindle 是当前默认平铺布局；保持分割方向，特殊工作区窗口缩小到 80%。
  dwindle = {
    preserve_split = true,
    special_scale_factor = 0.8,
  },

  -- Master 布局保留原有偏好，快捷键可在两种布局之间切换。
  master = {
    new_status = "master",
    new_on_top = true,
    mfact = 0.5,
  },

  general = {
    resize_on_border = true,
    layout = "dwindle",
  },

  input = {
    kb_layout = "cn",
    repeat_rate = 50,
    repeat_delay = 300,
    sensitivity = 0,
    numlock_by_default = true,
    left_handed = false,
    follow_mouse = 1,
    float_switch_override_focus = 0,
    touchpad = {
      disable_while_typing = true,
      natural_scroll = true,
      clickfinger_behavior = false,
      middle_button_emulation = false,
      tap_to_click = true,
      drag_lock = 0,
    },
    touchdevice = { enabled = true },
    tablet = {
      transform = 0,
      left_handed = false,
    },
  },

  gestures = {
    workspace_swipe_distance = 500,
    workspace_swipe_invert = true,
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 2,
    mouse_move_enables_dpms = true,
    enable_swallow = false,
    focus_on_activate = false,
    initial_workspace_tracking = 0,
    middle_click_paste = false,
    enable_anr_dialog = true,
    anr_missed_pings = 15,
    allow_session_lock_restore = true,
    on_focus_under_fullscreen = 1,
  },

  binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles = true,
    pass_mouse_when_bound = false,
  },

  xwayland = {
    enabled = true,
    force_zero_scaling = true,
  },

  render = { direct_scanout = 0 },

  cursor = {
    sync_gsettings_theme = true,
    no_hardware_cursors = 1,
    enable_hyprcursor = true,
    warp_on_change_workspace = 2,
    no_warps = true,
  },
})

-- 触摸板手势。
-- 三指横向滑动：切换工作区（原生 workspace 手势，带预览动画）。
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 四指上/下滑动：按比例放大/缩小光标缩放。
-- 原配置通过 hyprctl keyword cursor:zoom_factor 每次 ×1.5 / ÷1.5，
-- 这里改用 Lua 函数手势 + hl.get_config / hl.config，避免启动子进程。
local scripts = require("lua.defaults").scripts
local function cursor_zoom(factor)
  local cur = hl.get_config("cursor.zoom_factor")
  hl.config({ cursor = { zoom_factor = math.max(1, math.min(3, cur * factor)) } })
end
hl.gesture({ fingers = 4, direction = "up",   action = function() cursor_zoom(1.5) end })
hl.gesture({ fingers = 4, direction = "down", action = function() cursor_zoom(1 / 1.5) end })

-- 三指上滑：打开/关闭窗口总览（OverviewToggle.sh）。
hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd(scripts .. "/OverviewToggle.sh") end })

return true
