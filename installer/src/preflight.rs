//! 只读预检：不改动任何文件，提前发现正式运行（all）会遇到的冲突与缺失。
//! 发现错误项时以退出码 1 结束，便于在脚本/CI 里做门禁。

use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

use crate::deps::DEPS;
use crate::state::State;
use crate::util::{command_exists, read_dir_ok};
use crate::verify::{hyprland_running, lua_files};

/// 只读预检
pub fn preflight(st: &mut State) {
    st.log("==================== 预检 (check) ====================");
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let dot_config = PathBuf::from(format!("{}/.config", home));
    let src_root = st.repo_dir.join(".config");
    let repo_real = fs::canonicalize(&st.repo_dir).unwrap_or_else(|_| st.repo_dir.clone());

    let mut errors = 0;
    let mut warnings = 0;

    // 1. 仓库结构
    st.log("[仓库]");
    if !src_root.is_dir() {
        st.log("  [FAIL] 仓库内没有 .config/ 目录");
        errors += 1;
    } else {
        let entries: Vec<String> = read_dir_ok(&src_root)
            .into_iter()
            .flatten()
            .map(|e| e.file_name().to_string_lossy().to_string())
            .filter(|n| !n.starts_with('.'))
            .collect();
        st.log(&format!(
            "  .config/ 存在，{} 个应用目录: {}",
            entries.len(),
            entries.join(", ")
        ));
    }

    // 2. 目标状态：~/.config 下每个条目 stow 会怎么处理
    st.log("[目标] ~/.config 现状（stow 将如何处理）");
    for entry in read_dir_ok(&src_root).into_iter().flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if name.starts_with('.') {
            continue;
        }
        let src = entry.path();
        let dest = dot_config.join(&name);
        if dest.symlink_metadata().is_err() {
            st.log(&format!("  {:<12} 不存在 → stow 将创建 [INFO]", name));
            continue;
        }
        let md = match dest.symlink_metadata() {
            Ok(m) => m,
            Err(_) => continue,
        };
        if md.file_type().is_symlink() {
            match fs::read_link(&dest) {
                Ok(target) => {
                    let resolved = if target.is_absolute() {
                        target.clone()
                    } else {
                        dest.parent().unwrap().join(&target)
                    };
                    let in_repo = fs::canonicalize(&resolved)
                        .map(|p| p.starts_with(&repo_real))
                        .unwrap_or(false);
                    if in_repo {
                        st.log(&format!("  {:<12} 符号链接 → 仓库 [OK]", name));
                    } else {
                        st.log(&format!(
                            "  {:<12} 符号链接 → {} [冲突] stow 会替换该链接（原链接指向仓库外部）",
                            name,
                            target.display()
                        ));
                        errors += 1;
                    }
                }
                Err(_) => {
                    st.log(&format!("  {:<12} 悬空符号链接 → stow 将重建 [INFO]", name));
                }
            }
        } else if md.is_dir() {
            let out = Command::new("diff")
                .args(["-rq", &dest.to_string_lossy(), &src.to_string_lossy()])
                .output();
            match out {
                Ok(o) if o.status.success() => {
                    st.log(&format!("  {:<12} 真实目录，与仓库一致 [OK]", name));
                }
                Ok(o) => {
                    let n = String::from_utf8_lossy(&o.stdout).lines().count();
                    st.log(&format!(
                        "  {:<12} 真实目录，与仓库有 {} 处差异 → stow 将备份为 .bak-时间戳 后替换 [警告]",
                        name, n
                    ));
                    warnings += 1;
                }
                Err(_) => {
                    st.log(&format!("  {:<12} 真实目录，diff 不可用 [警告]", name));
                    warnings += 1;
                }
            }
        }
    }

    // 3. 软件依赖
    st.log("[依赖]");
    let mut missing = Vec::new();
    for (pkg, _) in DEPS {
        let ok = Command::new("pacman")
            .args(["-Q", pkg])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);
        if !ok {
            missing.push(*pkg);
        }
    }
    if missing.is_empty() {
        st.log(&format!("  {} 个依赖全部已安装 [OK]", DEPS.len()));
    } else {
        st.log(&format!(
            "  缺失 {} 个: {} [警告]（正式运行将安装）",
            missing.len(),
            missing.join(", ")
        ));
        warnings += 1;
    }
    if command_exists("paru") || command_exists("yay") {
        st.log("  AUR 助手: 可用 [OK]");
    } else {
        st.log("  AUR 助手: 缺失 → 正式运行将从 AUR 构建 paru（需网络 + git）[警告]");
        warnings += 1;
    }
    if command_exists("git") {
        st.log("  git: 可用 [OK]");
    } else {
        st.log("  git: 缺失 → 无法从 AUR 构建 paru [警告]");
        warnings += 1;
    }

    // 4. 驱动
    st.log("[驱动]");
    if command_exists("lspci") {
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
        let mut drv: Vec<&str> = Vec::new();
        if lower.contains("nvidia") {
            drv.extend(["nvidia-dkms", "nvidia-utils"]);
        }
        if lower.contains("amd") || lower.contains("ati") {
            drv.extend(["mesa", "vulkan-radeon", "libva-mesa-drivers"]);
        }
        if lower.contains("intel") {
            drv.extend(["vulkan-intel", "libva-intel-driver"]);
        }
        if drv.is_empty() {
            st.log("  未识别到显卡，跳过驱动检查");
        } else {
            let mut miss = Vec::new();
            for p in &drv {
                let ok = Command::new("pacman")
                    .args(["-Q", p])
                    .output()
                    .map(|o| o.status.success())
                    .unwrap_or(false);
                if !ok {
                    miss.push(*p);
                }
            }
            if miss.is_empty() {
                st.log(&format!("  驱动包全部已安装 [OK]: {}", drv.join(", ")));
            } else {
                st.log(&format!("  驱动缺失: {} [警告]", miss.join(", ")));
                warnings += 1;
            }
        }
    } else {
        st.log("  lspci 不可用（pciutils 未安装）[警告]");
        warnings += 1;
    }

    // 5. 语法
    st.log("[语法]");
    let hypr = dot_config.join("hypr");
    if command_exists("luac") {
        let mut lua_bad = 0;
        for f in lua_files(&hypr) {
            if !f.exists() {
                continue;
            }
            let ok = Command::new("luac")
                .args(["-p", f.to_str().unwrap()])
                .output()
                .map(|o| o.status.success())
                .unwrap_or(false);
            if !ok {
                lua_bad += 1;
                st.log(&format!("  [FAIL] Lua 语法错误: {}", f.display()));
            }
        }
        if lua_bad == 0 {
            st.log("  Lua 语法全部通过 [OK]");
        } else {
            errors += lua_bad;
        }
    } else {
        st.log("  luac 不可用，跳过 [警告]");
        warnings += 1;
    }
    let mut sh_bad = 0;
    if let Ok(rd) = fs::read_dir(hypr.join("scripts")) {
        for e in rd.flatten() {
            let p = e.path();
            if !p.extension().map(|x| x == "sh").unwrap_or(false) {
                continue;
            }
            let ok = Command::new("bash")
                .args(["-n", p.to_str().unwrap()])
                .output()
                .map(|o| o.status.success())
                .unwrap_or(false);
            if !ok {
                sh_bad += 1;
                st.log(&format!("  [FAIL] Shell 语法错误: {}", p.display()));
            }
        }
    }
    if sh_bad == 0 {
        st.log("  Shell 语法全部通过 [OK]");
    } else {
        errors += sh_bad;
    }

    // 6. 运行时
    st.log("[运行时]");
    if hyprland_running() {
        let errs = st.run_capture("hyprctl", &["configerrors"]).unwrap_or_default();
        if errs.trim().is_empty() {
            st.log("  Hyprland 运行中，configerrors 为空 [OK]");
        } else {
            st.log(&format!("  [FAIL] 配置错误:\n{}", errs.trim()));
            errors += 1;
        }
    } else {
        st.log("  Hyprland 未运行 [INFO]（首次装机属正常，进入会话后自行检查）");
    }

    // 7. 环境
    st.log("[环境]");
    if command_exists("sudo") {
        let cached = Command::new("sudo")
            .args(["-n", "true"])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);
        if cached {
            st.log("  sudo: 可用且凭据已缓存 [OK]");
        } else {
            st.log("  sudo: 可用，凭据未缓存 → 正式运行时会提示输入密码 [INFO]");
        }
    } else {
        st.log("  sudo: 缺失 → 无法安装依赖 [FAIL]");
        errors += 1;
    }

    // 汇总
    st.log("==================== 预检汇总 ====================");
    st.log(&format!("错误: {}  警告: {}", errors, warnings));
    if errors == 0 {
        st.log("预检通过：正式运行（sonder-installer all）不会因冲突/缺失报错。");
    } else {
        st.log("预检发现错误项，请先处理再正式运行。");
    }
    if errors > 0 {
        std::process::exit(1);
    }
}
