//! stow / unstow：管理仓库 .config/ 与 ~/.config 之间的符号链接。

use std::env;
use std::fs;
use std::os::unix::fs::symlink;
use std::path::PathBuf;

use crate::state::State;
use crate::util::{read_dir_ok, relative_path, timestamp};

/// stow：为仓库 .config/ 下每个条目创建 ~/.config 符号链接
pub fn stow(st: &mut State) {
    st.log("==================== 符号链接 (stow) ====================");
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let dot_config = PathBuf::from(format!("{}/.config", home));
    let _ = fs::create_dir_all(&dot_config);
    let src_root = st.repo_dir.join(".config");

    if !src_root.is_dir() {
        st.log(&format!("[FAIL] 仓库内没有 .config/ 目录: {}", src_root.display()));
        st.failed.push("stow:no-.config".to_string());
        return;
    }

    let repo_real = fs::canonicalize(&st.repo_dir).unwrap_or_else(|_| st.repo_dir.clone());
    for entry in read_dir_ok(&src_root).into_iter().flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if name.starts_with('.') {
            continue;
        }
        let src = entry.path();
        let dest = dot_config.join(&name);

        // 已是指向仓库的符号链接 → 跳过
        if dest.symlink_metadata().map(|m| m.file_type().is_symlink()).unwrap_or(false) {
            if let Ok(target) = fs::read_link(&dest) {
                let resolved = if target.is_absolute() {
                    target
                } else {
                    dest.parent().unwrap().join(&target)
                };
                if let Ok(resolved) = fs::canonicalize(&resolved) {
                    if resolved.starts_with(&repo_real) {
                        st.log(&format!("[OK]   {} 已链接到仓库，跳过", name));
                        continue;
                    }
                }
            }
            // 指向别处的符号链接：直接替换（链接本身无数据）
            let _ = fs::remove_file(&dest);
        }

        // 真实目录：备份后替换（避免数据丢失）
        if dest.exists() && !dest.symlink_metadata().map(|m| m.file_type().is_symlink()).unwrap_or(false) {
            let backup = dot_config.join(format!("{}.bak-{}", name, timestamp()));
            st.log(&format!(
                "[WARN] {} 是真实目录，备份到 {} 后替换为符号链接",
                name,
                backup.file_name().unwrap().to_string_lossy()
            ));
            if fs::rename(&dest, &backup).is_err() {
                st.log(&format!("[FAIL] 备份 {} 失败，跳过", name));
                st.failed.push(format!("stow:{}", name));
                continue;
            }
        }

        let link = relative_path(&dot_config, &src);
        if symlink(&link, &dest).is_ok() {
            st.log(&format!("[OK]   {} → {}", name, link.display()));
        } else {
            st.log(&format!("[FAIL] 创建符号链接失败: {}", name));
            st.failed.push(format!("stow:{}", name));
        }
    }
}

/// unstow：移除指向本仓库的符号链接
pub fn unstow(st: &mut State) {
    st.log("==================== 移除符号链接 (unstow) ====================");
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let dot_config = PathBuf::from(format!("{}/.config", home));
    let src_root = st.repo_dir.join(".config");
    let repo_real = fs::canonicalize(&st.repo_dir).unwrap_or_else(|_| st.repo_dir.clone());

    if !src_root.is_dir() {
        st.log("[INFO] 仓库内没有 .config/ 目录，无需 unstow");
        return;
    }

    for entry in read_dir_ok(&src_root).into_iter().flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if name.starts_with('.') {
            continue;
        }
        let dest = dot_config.join(&name);
        if !dest.symlink_metadata().map(|m| m.file_type().is_symlink()).unwrap_or(false) {
            continue;
        }
        let points_to_repo = fs::read_link(&dest)
            .ok()
            .and_then(|t| {
                let full = if t.is_absolute() {
                    t
                } else {
                    dest.parent().unwrap().join(&t)
                };
                fs::canonicalize(full).ok()
            })
            .map(|p| p.starts_with(&repo_real))
            .unwrap_or(false);
        if points_to_repo {
            if fs::remove_file(&dest).is_ok() {
                st.log(&format!("[OK]   已移除 {}", name));
            } else {
                st.log(&format!("[FAIL] 移除失败: {}", name));
                st.failed.push(format!("unstow:{}", name));
            }
        } else {
            st.log(&format!("[SKIP] {} 指向仓库外部，不动", name));
        }
    }
}
