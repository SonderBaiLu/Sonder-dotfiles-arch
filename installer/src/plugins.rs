//! noctalia 本地插件落位。
//!
//! 仓库 `system/noctalia-local-plugins/<插件>/` 是插件 fork 的唯一事实源；
//! 本模块为每个插件在 `~/.local/share/noctalia-local-plugins/` 建指向仓库的
//! 符号链接（noctalia 的 local 源目录），并确保 `~/.local/state/noctalia/settings.toml`
//! 注册了 local 源、启用了各插件 id。全程幂等：已就绪的链接与配置不动。

use std::env;
use std::fs;
use std::os::unix::fs::symlink;
use std::path::PathBuf;

use crate::state::State;
use crate::util::{read_dir_ok, relative_path, timestamp};

/// 确保 local 源目录下是指向仓库的符号链接；返回插件 id 列表（读 plugin.toml）。
fn place_plugin_links(st: &mut State, ids: &mut Vec<String>) {
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let src_root = st.repo_dir.join("system/noctalia-local-plugins");
    let dest_root = PathBuf::from(&home).join(".local/share/noctalia-local-plugins");
    let _ = fs::create_dir_all(&dest_root);
    let repo_real = fs::canonicalize(&st.repo_dir).unwrap_or_else(|_| st.repo_dir.clone());

    for entry in read_dir_ok(&src_root).into_iter().flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if name.starts_with('.') {
            continue;
        }
        let src = entry.path();
        if !src.join("plugin.toml").is_file() {
            continue;
        }
        if let Ok(raw) = fs::read_to_string(src.join("plugin.toml")) {
            if let Ok(id) = raw.parse::<toml::Table>() {
                if let Some(id) = id.get("id").and_then(|v| v.as_str()) {
                    ids.push(id.to_string());
                }
            }
        }

        let dest = dest_root.join(&name);
        // 与 stow 相同的三态处理：已指向仓库→跳过；真实目录→备份替换；其余→建相对链接。
        if dest.symlink_metadata().map(|m| m.file_type().is_symlink()).unwrap_or(false) {
            if let Ok(target) = fs::read_link(&dest) {
                let resolved = if target.is_absolute() { target } else { dest.parent().unwrap().join(&target) };
                if let Ok(resolved) = fs::canonicalize(&resolved) {
                    if resolved == fs::canonicalize(&src).unwrap_or_else(|_| src.clone()) {
                        st.log(&format!("[OK]   {} 已链接到仓库，跳过", name));
                        continue;
                    }
                }
            }
            let _ = fs::remove_file(&dest);
        }
        if dest.exists() {
            let backup = dest_root.join(format!("{}.bak-{}", name, timestamp()));
            st.log(&format!("[WARN] {} 是真实目录，备份到 {} 后替换为符号链接", name, backup.display()));
            if fs::rename(&dest, &backup).is_err() {
                st.log(&format!("[FAIL] 备份 {} 失败，跳过", name));
                st.failed.push(format!("plugins:{}", name));
                continue;
            }
        }
        let link = relative_path(&dest_root, &src);
        match symlink(&link, &dest) {
            Ok(()) => st.log(&format!("[OK]   {} → {}", name, link.display())),
            Err(e) => {
                st.log(&format!("[FAIL] 创建 {} 符号链接失败: {}", name, e));
                st.failed.push(format!("plugins:{}", name));
            }
        }
    }
    let _ = repo_real; // 仅表达“链接必须落在本仓库”的语义，canonicalize 已在上面使用
}

/// 确保 settings.toml 含 local 源与启用清单；仅在缺失时写入（写入前备份）。
fn register_settings(st: &mut State, ids: &[String]) {
    let home = env::var("HOME").unwrap_or_else(|_| "/root".into());
    let path = PathBuf::from(&home).join(".local/state/noctalia/settings.toml");
    let _ = fs::create_dir_all(path.parent().unwrap());
    let dest_root = PathBuf::from(&home).join(".local/share/noctalia-local-plugins");

    let raw = fs::read_to_string(&path).unwrap_or_default();
    let mut doc: toml::Table = raw.parse().unwrap_or_default();
    let empty = toml::Table::new();
    let plugins = doc
        .entry("plugins".to_string())
        .or_insert_with(|| toml::Value::Table(empty))
        .as_table_mut()
        .cloned()
        .unwrap_or_default();
    let mut plugins = plugins;
    let mut changed = false;

    // 启用清单：补上缺失的插件 id。
    if !plugins.get("enabled").is_some_and(|v| v.is_array()) {
        plugins.insert("enabled".to_string(), toml::Value::Array(Vec::new()));
        changed = true;
    }
    if let Some(list) = plugins.get_mut("enabled").and_then(|v| v.as_array_mut()) {
        for id in ids {
            if !list.iter().any(|v| v.as_str() == Some(id.as_str())) {
                list.push(toml::Value::String(id.clone()));
                st.log(&format!("[INFO] settings.toml 启用 {}", id));
                changed = true;
            }
        }
    }

    // 源清单：补上指向本地目录的 path 源。
    if !plugins.get("source").is_some_and(|v| v.is_array()) {
        plugins.insert("source".to_string(), toml::Value::Array(Vec::new()));
        changed = true;
    }
    let location = dest_root.to_string_lossy().to_string();
    if let Some(list) = plugins.get_mut("source").and_then(|v| v.as_array_mut()) {
        let has_local = list.iter().any(|v| {
            v.as_table()
                .map(|t| t.get("kind").and_then(|k| k.as_str()) == Some("path")
                    && t.get("location").and_then(|l| l.as_str()) == Some(location.as_str()))
                .unwrap_or(false)
        });
        if !has_local {
            let mut source = toml::Table::new();
            source.insert("kind".to_string(), toml::Value::String("path".to_string()));
            source.insert("location".to_string(), toml::Value::String(location.clone()));
            source.insert("name".to_string(), toml::Value::String("local".to_string()));
            list.push(toml::Value::Table(source));
            st.log(&format!("[INFO] settings.toml 注册 local 源: {}", location));
            changed = true;
        }
    }

    doc.insert("plugins".to_string(), toml::Value::Table(plugins));
    if !changed {
        st.log("[OK]   settings.toml 已包含本地插件注册，无需写入");
        return;
    }
    if path.exists() {
        let backup = path.with_file_name(format!("settings.toml.bak-{}", timestamp()));
        let _ = fs::copy(&path, &backup);
        st.log(&format!("[INFO] 原 settings.toml 备份到 {}", backup.display()));
    }
    match toml::to_string_pretty(&doc) {
        Ok(text) => match fs::write(&path, text) {
            Ok(()) => st.log("[OK]   settings.toml 写入完成"),
            Err(e) => {
                st.log(&format!("[FAIL] 写入 settings.toml 失败: {}", e));
                st.failed.push("plugins:settings".to_string());
            }
        },
        Err(e) => {
            st.log(&format!("[FAIL] 序列化 settings.toml 失败: {}", e));
            st.failed.push("plugins:settings".to_string());
        }
    }
    st.log("[INFO] 若 noctalia 正在运行，重启 noctalia（或重新登录）后生效");
}

/// noctalia 本地插件落位入口（`plugins` 子命令 / `all` 的一个阶段）。
pub fn ensure_local_plugins(st: &mut State) {
    st.log("==================== noctalia 本地插件 ====================");
    let mut ids = Vec::new();
    place_plugin_links(st, &mut ids);
    if ids.is_empty() {
        st.log("[WARN] 未发现任何本地插件（system/noctalia-local-plugins/ 为空？）");
        return;
    }
    register_settings(st, &ids);
}
