//! 构建并安装仓库内的小工具（tools/）。

use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;

use crate::state::State;
use crate::util::command_exists;

/// 构建仓库内小工具并安装到 ~/.local/bin，同时补齐运行所需的用户组。
pub fn install_tools(st: &mut State) {
    st.log("==================== 本地工具 ====================");
    install_rightclick(st);
    ensure_input_group(st);
}

fn install_rightclick(st: &mut State) {
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let src = st.repo_dir.join("tools/rightclick");
    if !src.join("Cargo.toml").is_file() {
        st.log("[SKIP] tools/rightclick 不存在，跳过");
        return;
    }
    if !command_exists("cargo") {
        st.log("[FAIL] 未找到 cargo，无法构建 rightclick（先运行仓库根目录的 bootstrap.sh）");
        st.failed.push("rightclick:cargo".to_string());
        return;
    }

    st.log("[INFO] 构建 rightclick ...");
    if !st.run_logged_in(&src, "cargo", &["build", "--release", "--quiet"]) {
        st.log("[FAIL] rightclick 构建失败");
        st.failed.push("rightclick:build".to_string());
        return;
    }

    let bin = src.join("target/release/rightclick");
    if !bin.is_file() {
        st.log("[FAIL] 构建产物不存在: target/release/rightclick");
        st.failed.push("rightclick:artifact".to_string());
        return;
    }

    let dest_dir = PathBuf::from(&home).join(".local/bin");
    let dest = dest_dir.join("rightclick");
    if let Err(e) = fs::create_dir_all(&dest_dir) {
        st.log(&format!("[FAIL] 创建 {} 失败: {}", dest_dir.display(), e));
        st.failed.push("rightclick:mkdir".to_string());
        return;
    }
    match fs::copy(&bin, &dest) {
        Ok(_) => {
            let _ = fs::set_permissions(&dest, fs::Permissions::from_mode(0o755));
            st.log(&format!("[OK]   rightclick → {}", dest.display()));
        }
        Err(e) => {
            st.log(&format!("[FAIL] 复制 rightclick 失败: {}", e));
            st.failed.push("rightclick:install".to_string());
        }
    }
}

/// rightclick 通过 evdev 读设备，需要 input 组权限（重新登录后生效）
fn ensure_input_group(st: &mut State) {
    let groups = st.run_capture("id", &["-nG"]).unwrap_or_default();
    if groups.split_whitespace().any(|g| g == "input") {
        st.log("[OK]   已在 input 组");
        return;
    }

    let user = env::var("USER")
        .or_else(|_| env::var("LOGNAME"))
        .unwrap_or_default();
    if user.is_empty() {
        st.log("[WARN] 无法确定用户名，跳过 input 组配置");
        return;
    }

    st.log(&format!("[INFO] 将 {} 加入 input 组（重新登录后生效）", user));
    if st.run_logged("sudo", &["usermod", "-aG", "input", user.as_str()]) {
        st.log("[OK]   input 组已配置");
    } else {
        st.log("[WARN] 加入 input 组失败，rightclick 可能无法读取设备");
    }
}
