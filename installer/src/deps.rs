//! 驱动与软件依赖检测安装。

use std::env;
use std::fs;
use std::io::BufRead;
use std::process::Command;

use crate::state::{summary, State};
use crate::util::{command_exists, is_tty};

/// 依赖清单：(包名, 是否 AUR)
pub const DEPS: &[(&str, bool)] = &[
    // Hyprland 核心
    ("hyprland", false),
    ("hypridle", false),
    // 锁屏由 noctalia 内置锁屏负责（hyprlock 会与其冲突导致双锁屏）；
    // Polkit 授权弹窗由 noctalia 内置的认证代理负责（quickshell Services/Polkit 模块），
    // 不需要单独装 hyprpolkitagent；scripts/Polkit.sh 找不到二进制时会自动退出，仅作后备。
    // 壁纸 / 截图 / 取色（awww 即原 swww，上游已改名，官方仓库 extra）
    ("awww", false),
    ("wallust", false),
    ("grim", false),
    ("slurp", false),
    ("swappy", false),
    ("hyprsunset", true),
    // 通知 / 外壳（通知守护进程由 noctalia 充当，不用 swaync；启动器用 noctalia，不用 rofi）
    ("noctalia", true),
    ("yad", false),
    ("quickshell", false),
    // 终端 / shell
    ("alacritty", false),
    ("fish", false),
    // 音频 / 亮度 / 蓝牙
    ("pipewire", false),
    ("wireplumber", false),
    ("pipewire-pulse", false),
    ("pamixer", false),
    ("playerctl", false),
    ("brightnessctl", false),
    ("bluez", false),
    ("blueman", false),
    // 输入法 / 剪贴板 / 通知库
    ("fcitx5", false),
    ("fcitx5-chinese-addons", false),
    ("fcitx5-gtk", false),
    ("fcitx5-qt", false),
    ("fcitx5-rime", false),
    ("fcitx5-configtool", false),
    ("wl-clipboard", false),
    ("cliphist", false),
    ("libnotify", false),
    // 字体（缺 CJK 中文会显示为豆腐块）
    ("noto-fonts-cjk", false),
    ("noto-fonts-emoji", false),
    // 基础工具
    ("jq", false),
    ("fastfetch", false),
    ("xdg-user-dirs", false),
    ("xdg-utils", false),
    ("xdg-desktop-portal", false),
    ("xdg-desktop-portal-hyprland", false),
    ("xdg-desktop-portal-gtk", false),
    ("dbus", false),
    ("systemd", false),
];

/// 安装单个依赖。返回 true 表示已就绪（已装或装成功）
fn install_dep(st: &mut State, pkg: &str, aur: bool) -> bool {
    // 先用 pacman -Q 探测：已安装则直接视为就绪，不做网络请求
    let already = Command::new("pacman")
        .args(["-Q", pkg])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);
    if already {
        st.log(&format!("[OK]   {} 已安装", pkg));
        return true;
    }

    // AUR 包走 paru（以普通用户运行，内部自行 sudo）；官方仓库包直接 sudo pacman
    let (program, need_sudo) = if aur {
        ("paru", false)
    } else {
        ("pacman", true)
    };

    if !command_exists(program) {
        st.log(&format!("[FAIL] {} 需要 {}，但未找到，跳过", pkg, program));
        st.failed.push(pkg.to_string());
        return false;
    }

    // 统一以 -S --noconfirm --needed 安装：needed 避免重装已有包
    let try_install = |st: &mut State| -> bool {
        let mut args: Vec<&str> = Vec::new();
        if need_sudo {
            args.push("sudo");
        }
        args.push(program);
        args.extend(["-S", "--noconfirm", "--needed", pkg]);
        st.run_logged(&args[0], &args[1..])
    };

    st.log(&format!("[INFO] 安装 {} ...", pkg));
    if try_install(st) {
        st.log(&format!("[OK]   {} 安装成功", pkg));
        st.installed.push(pkg.to_string());
        return true;
    }

    // 失败：交互选择 重试 / 跳过 / 退出
    loop {
        if st.non_interactive || !is_tty() {
            st.log(&format!("[FAIL] {} 安装失败（非交互模式，跳过）", pkg));
            st.failed.push(pkg.to_string());
            return false;
        }
        eprintln!("\n[错误] {} 安装失败。R=重试  S=跳过  Q=退出部署", pkg);
        let mut line = String::new();
        if std::io::stdin().lock().read_line(&mut line).is_err() {
            st.log(&format!("[FAIL] {} 无法读取输入，跳过", pkg));
            st.failed.push(pkg.to_string());
            return false;
        }
        match line.trim().to_lowercase().as_str() {
            "r" => {
                st.log(&format!("[INFO] 重试安装 {} ...", pkg));
                if try_install(st) {
                    st.log(&format!("[OK]   {} 重试安装成功", pkg));
                    st.installed.push(pkg.to_string());
                    return true;
                }
            }
            "s" => {
                st.log(&format!("[SKIP] {} 用户选择跳过", pkg));
                st.skipped.push(pkg.to_string());
                return false;
            }
            _ => {
                st.log("[QUIT] 用户选择退出");
                summary(st);
                std::process::exit(1);
            }
        }
    }
}

/// 显卡驱动检测与安装
pub fn check_drivers(st: &mut State) {
    st.log("==================== 驱动检测 ====================");
    if !command_exists("lspci") {
        st.log("[INFO] lspci 不可用，先安装 pciutils");
        install_dep(st, "pciutils", false);
    }

    let gpu = st.run_capture("lspci", &[]).unwrap_or_default();
    let gpu = gpu
        .lines()
        .filter(|l| {
            let l = l.to_lowercase();
            l.contains("vga") || l.contains("3d") || l.contains("display")
        })
        .collect::<Vec<_>>()
        .join("\n");

    let lower = gpu.to_lowercase();
    if lower.contains("nvidia") {
        st.log("[INFO] 检测到 NVIDIA 显卡");
        // 本机实测使用 open 内核模块（environment.lua 的 NVD_BACKEND=direct 仅对 open 模块生效）
        install_dep(st, "nvidia-open-dkms", false);
        install_dep(st, "nvidia-utils", false);
        install_dep(st, "nvidia-settings", false);
    }
    if lower.contains("amd") || lower.contains("ati") {
        st.log("[INFO] 检测到 AMD 显卡");
        install_dep(st, "mesa", false);
        install_dep(st, "vulkan-radeon", false);
        install_dep(st, "libva-mesa-drivers", false);
    }
    if lower.contains("intel") {
        st.log("[INFO] 检测到 Intel 核显");
        install_dep(st, "vulkan-intel", false);
        install_dep(st, "libva-intel-driver", false);
    }
}

/// 确保 AUR 助手（paru）存在，缺失则从 AUR 构建安装
fn ensure_paru(st: &mut State) {
    if command_exists("paru") || command_exists("yay") {
        return;
    }
    st.log("[INFO] 未找到 AUR 助手（paru/yay），从 AUR 构建安装 paru ...");
    let tmp = env::temp_dir().join(format!("paru-build-{}", std::process::id()));
    let _ = fs::remove_dir_all(&tmp);
    let clone_ok = st.run_logged(
        "git",
        &["clone", "--depth", "1", "https://aur.archlinux.org/paru.git", tmp.to_str().unwrap()],
    );
    if clone_ok
        && st.run_logged("makepkg", &["-Csi", "--noconfirm", "-p", &format!("{}/PKGBUILD", tmp.display())])
    {
        st.log("[OK]   paru 安装成功");
    } else {
        st.log("[FAIL] paru 安装失败，AUR 包（noctalia/hyprsunset 等）将被跳过");
    }
    let _ = fs::remove_dir_all(&tmp);
}

/// 软件依赖检测与安装
pub fn check_deps(st: &mut State) {
    st.log("==================== 软件依赖检测 ====================");
    // 缓存 sudo 凭据，后续安装免重复输密码（paru 内部也会调用 sudo）
    if !st.non_interactive && is_tty() {
        st.log("[INFO] 缓存 sudo 凭据（如已缓存则直接通过）");
        if !st.run_logged("sudo", &["-v"]) {
            st.log("[WARN] sudo 凭据缓存失败，安装步骤可能中断");
        }
    }
    ensure_paru(st);
    for (pkg, aur) in DEPS {
        install_dep(st, pkg, *aur);
    }
}
