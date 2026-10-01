//! Sonder-dotfiles-arch 一键部署工具
//!
//! 子命令：
//!   （无）/ all   完整流程：deps + stow + verify
//!   deps         仅驱动与软件依赖检测安装
//!   stow         为仓库 .config/ 下每个目录创建 ~/.config 符号链接
//!   unstow       移除指向本仓库的符号链接
//!   verify       仅语法与运行时校验
//!   check        只读预检：不改动任何文件，提前发现正式运行会遇到的冲突/缺失
//!
//! 安装失败时交互选择 重试/跳过/退出；所有失败与跳过项写入日志。
//! 用法：sonder-installer [命令] [--yes]（--yes 非交互，失败直接跳过）

mod deps;
mod preflight;
mod state;
mod stow;
mod util;
mod verify;

use std::env;
use std::fs;
use std::path::PathBuf;
use std::time::Instant;

use state::{summary, State};

/// 仓库目录：从可执行文件位置向上查找包含 .config/ 的目录，找不到则用当前目录
fn locate_repo_dir() -> PathBuf {
    let start = env::current_exe()
        .unwrap_or_else(|_| PathBuf::from("sonder-installer"))
        .parent()
        .map(|p| p.to_path_buf())
        .unwrap_or_default();
    let mut repo_dir = start;
    loop {
        if repo_dir.join(".config").is_dir() {
            break;
        }
        match repo_dir.parent() {
            Some(p) => repo_dir = p.to_path_buf(),
            None => break,
        }
    }
    if !repo_dir.join(".config").is_dir() {
        repo_dir = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    }
    repo_dir
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let non_interactive = args.iter().any(|a| a == "--yes");
    let command = args
        .iter()
        .skip(1)
        .find(|a| !a.starts_with('-'))
        .cloned()
        .unwrap_or_else(|| "all".to_string());

    let repo_dir = locate_repo_dir();
    if !repo_dir.join(".config").is_dir() {
        eprintln!("[错误] 无法定位仓库目录（需在仓库内运行或从仓库构建），当前: {}", repo_dir.display());
        std::process::exit(1);
    }

    let log_dir = PathBuf::from(format!(
        "{}/.local/state/sonder-dotfiles",
        env::var("HOME").unwrap_or_default()
    ));
    let _ = fs::create_dir_all(&log_dir);
    let mut st = State {
        repo_dir,
        log_file: log_dir.join("install.log"),
        non_interactive,
        installed: Vec::new(),
        skipped: Vec::new(),
        failed: Vec::new(),
    };

    let t0 = Instant::now();
    st.log(&format!("############ {} 开始 ############", command));
    st.log(&format!("仓库目录: {}", st.repo_dir.display()));

    match command.as_str() {
        "deps" => deps::check_deps(&mut st),
        "stow" => stow::stow(&mut st),
        "unstow" => stow::unstow(&mut st),
        "verify" => verify::verify(&mut st),
        "check" => preflight::preflight(&mut st),
        "all" => {
            deps::check_drivers(&mut st);
            deps::check_deps(&mut st);
            stow::stow(&mut st);
            verify::verify(&mut st);
        }
        other => {
            eprintln!("[错误] 未知命令: {}（可用: all / deps / stow / unstow / verify / check）", other);
            std::process::exit(1);
        }
    }

    // check 自带汇总，跳过安装类汇总
    if command != "check" {
        summary(&st);
    }
    st.log(&format!("耗时: {:.1} 秒", t0.elapsed().as_secs_f64()));
    if command != "check" && !st.failed.is_empty() {
        st.log("############ 完成（存在失败项，详见日志） ############");
        std::process::exit(2);
    }
    if command != "check" {
        st.log("############ 完成 ############");
    }
}
