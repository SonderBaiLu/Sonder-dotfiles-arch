-- 环境变量集中管理：这些变量在 Hyprland 启动前注入到桌面会话。
-- NVIDIA 相关项按当前设备保留；若更换为非 NVIDIA 硬件，可整体删除对应区块。

local vars = {
	{ "DOTS_VERSION", "2.3.19" },
	{ "GDK_BACKEND", "wayland,x11,*" },
	{ "QT_QPA_PLATFORM", "wayland;xcb" },
	{ "CLUTTER_BACKEND", "wayland" },
	{ "XDG_CURRENT_DESKTOP", "Hyprland" },
	{ "XDG_SESSION_DESKTOP", "Hyprland" },
	{ "XDG_SESSION_TYPE", "wayland" },
	{ "QT_AUTO_SCREEN_SCALE_FACTOR", "1" },
	{ "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1" },
	{ "QT_QPA_PLATFORMTHEME", "xdgdesktopportal" },
	{ "QT_QUICK_CONTROLS_STYLE", "org.hyprland.style" },
	{ "GDK_SCALE", "1" },
	{ "QT_SCALE_FACTOR", "1" },
	{ "HYPRCURSOR_THEME", "Bibata-Modern-Ice" },
	{ "HYPRCURSOR_SIZE", "24" },
	{ "MOZ_ENABLE_WAYLAND", "1" },
	{ "ELECTRON_OZONE_PLATFORM_HINT", "auto" },
	{ "NVD_BACKEND", "direct" },
	{ "GSK_RENDERER", "ngl" },
	{ "__GL_GSYNC_ALLOWED", "1" },
	{ "MOZ_DISABLE_RDD_SANDBOX", "1" },
	{ "EGL_PLATFORM", "wayland" },
	{ "__GLX_VENDOR_LIBRARY_NAME", "nvidia" },
	{ "GTK_IM_MODULE", "fcitx" },
	{ "QT_IM_MODULE", "fcitx" },
	{ "XMODIFIERS", "@im=fcitx" },
	{ "INPUT_METHOD", "fcitx5" },
	{ "GDK_BACKEND", "wayland,x11,*" },
}

for _, item in ipairs(vars) do
	hl.env(item[1], item[2])
end
