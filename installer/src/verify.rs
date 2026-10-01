//! 语法与运行时校验（会执行 hyprctl reload）。

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::state::State;
use crate::util::command_exists;

/// 收集 hyprland.lua + lua/*.lua 的绝对路径
pub fn lua_files(hypr: &Path) -> Vec<PathBuf> {
    let mut files: Vec<PathBuf> = vec![hypr.join("hyprland.lua")];
    if let Ok(rd) = fs::read_dir(hypr.join("lua")) {
        for e in rd.flatten() {
            if e.path().extension().map(|x| x == "lua").unwrap_or(false) {
                files.push(e.path());
            }
        }
    }
    files
}

/// Hyprland 是否正在运行
pub fn hyprland_running() -> bool {
    command_exists("hyprctl")
        && Command::new("hyprctl")
            .arg("version")
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false)
}

/// 语法与运行时校验
pub fn verify(st: &mut State) {
    st.log("==================== 校验 ====================");
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let hypr = PathBuf::from(format!("{}/.config/hypr", home));

    // Lua 语法
    if command_exists("luac") {
        let mut bad = 0;
        for f in lua_files(&hypr) {
            if !f.exists() {
                continue;
            }
            if !st.run_logged("luac", &["-p", f.to_str().unwrap()]) {
                st.log(&format!("[FAIL] Lua 语法错误: {}", f.display()));
                st.failed.push(format!("lua:{}", f.display()));
                bad += 1;
            }
        }
        if bad == 0 {
            st.log("[OK]   Lua 语法全部通过");
        }
    } else {
        st.log("[SKIP] luac 不可用，跳过 Lua 语法检查");
    }

    // Shell 语法
    let mut bad = 0;
    if let Ok(rd) = fs::read_dir(hypr.join("scripts")) {
        for e in rd.flatten() {
            let p = e.path();
            if p.extension().map(|x| x == "sh").unwrap_or(false) {
                if !st.run_logged("bash", &["-n", p.to_str().unwrap()]) {
                    st.log(&format!("[FAIL] Shell 语法错误: {}", p.display()));
                    st.failed.push(format!("shell:{}", p.display()));
                    bad += 1;
                }
            }
        }
    }
    if bad == 0 {
        st.log("[OK]   Shell 语法全部通过");
    }

    // Hyprland 运行时配置错误（仅当 Hyprland 正在运行）
    if hyprland_running() {
        st.log("[INFO] Hyprland 正在运行，重载配置并检查错误");
        if st.run_logged("hyprctl", &["reload", "config-only"]) {
            let errs = st.run_capture("hyprctl", &["configerrors"]).unwrap_or_default();
            if errs.trim().is_empty() {
                st.log("[OK]   配置重载成功，无配置错误");
            } else {
                st.log(&format!("[FAIL] 配置错误: {}", errs.trim()));
                st.failed.push("configerrors".to_string());
            }
        } else {
            st.log("[WARN] hyprctl reload 失败（可能尚未进入 Hyprland 会话）");
        }
    } else {
        st.log("[INFO] Hyprland 未运行，跳过运行时校验（进入会话后自行检查）");
    }
}
