//! Sonder-dotfiles-arch 一键部署工具
//!
//! 子命令：
//!   （无）/ all   完整流程：deps + tools + stow + verify
//!   deps         仅驱动与软件依赖检测安装
//!   tools        构建仓库内小工具并安装到 ~/.local/bin
//!   stow         为仓库 .config/ 下每个目录创建 ~/.config 符号链接
//!   unstow       移除指向本仓库的符号链接
//!   verify       仅语法与运行时校验
//!   check        只读预检：不改动任何文件，提前发现正式运行会遇到的冲突/缺失
//!
//! 安装失败时交互选择 重试/跳过/退出；所有失败与跳过项写入日志。
//! 用法：sonder-installer [命令] [--yes] [--optional wechat,qq,office]
//!   --yes      非交互，失败直接跳过
//!   --optional 可选软件选择（wechat/QQ/LibreOffice 等，逗号分隔；all=全装，缺省=不装）；
//!              bootstrap.sh 部署前交互询问后转发到这里
//! 全新系统请先运行仓库根目录的 bootstrap.sh（安装构建依赖后再编译本工具）。

mod deps;
mod plugins;
mod preflight;
mod state;
mod stow;
mod tui;
mod tools;
mod util;
mod verify;

use std::env;
use std::fs;
use std::io::IsTerminal;
use std::path::PathBuf;
use std::process::Command;
use std::time::Instant;

use state::{summary, State};
use util::command_exists;

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
    let no_tui = args.iter().any(|a| a == "--no-tui");
    // --optional <key,...>：可选软件选择（见 deps.rs 的 OPTIONAL_DEPS）。
    let optional: Vec<String> = match args.iter().position(|a| a == "--optional") {
        Some(i) => args
            .get(i + 1)
            .map(|v| v.split(',').map(|s| s.trim().to_lowercase()).filter(|s| !s.is_empty()).collect())
            .unwrap_or_default(),
        None => Vec::new(),
    };
    let optional: Vec<String> = if optional.iter().any(|k| k == "all") {
        deps::OPTIONAL_DEPS.iter().map(|(k, _, _, _)| k.to_string()).collect()
    } else if optional.iter().any(|k| k == "none") {
        Vec::new()
    } else {
        optional
    };
    // 去重后的可用 key，用于校验与报错提示（同一 key 可对应多个包）
    let mut valid_keys: Vec<&str> = Vec::new();
    for (k, _, _, _) in deps::OPTIONAL_DEPS {
        if !valid_keys.contains(&k) {
            valid_keys.push(k);
        }
    }
    if let Some(bad) = optional.iter().find(|k| !valid_keys.contains(&k.as_str())) {
        eprintln!(
            "[错误] --optional 未知项: {}（可用: {}，或 all）",
            bad,
            valid_keys.join("/")
        );
        std::process::exit(1);
    }
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
        optional,
        installed: Vec::new(),
        skipped: Vec::new(),
        failed: Vec::new(),
        tui: None,
    };

    let t0 = Instant::now();
    st.log(&format!("############ {} 开始 ############", command));
    st.log(&format!("仓库目录: {}", st.repo_dir.display()));

    match command.as_str() {
        "deps" => deps::check_deps(&mut st),
        "tools" => tools::install_tools(&mut st),
        "stow" => stow::stow(&mut st),
        "unstow" => stow::unstow(&mut st),
        "plugins" => plugins::ensure_local_plugins(&mut st),
        "verify" => verify::verify(&mut st),
        "check" => preflight::preflight(&mut st),
        "all" => {
            // 全屏 TUI 只给完整部署用：真实终端 + 非 --yes + 未加 --no-tui。
            let use_tui = std::io::stdout().is_terminal() && !non_interactive && !no_tui;
            if use_tui {
                // 先在普通终端缓存 sudo 凭据——密码提示不能出现在全屏界面里。
                let sudo_ok = Command::new("sudo").arg("-v").status().map(|s| s.success()).unwrap_or(false);
                st.tui = tui::TuiHandle::spawn();
                st.log("[INFO] 已进入交互部署界面：Q 请求取消（阶段/包之间生效），失败项自动跳过");
                if !sudo_ok {
                    st.log("[WARN] sudo 凭据缓存失败：需要安装的包会被跳过，可退出后重新运行");
                }
            }
            let stages: &[(&str, fn(&mut State))] = &[
                ("驱动检测", deps::check_drivers),
                ("依赖安装", deps::check_deps),
                ("本地工具", tools::install_tools),
                ("符号链接", stow::stow),
                ("本地插件", plugins::ensure_local_plugins),
                ("校验", verify::verify),
            ];
            for (name, run) in stages {
                if st.cancelled() {
                    st.log("[WARN] 收到取消请求，跳过剩余阶段");
                    break;
                }
                if let Some(t) = &st.tui {
                    t.phase_start(name);
                }
                let before = st.failed.len();
                run(&mut st);
                if let Some(t) = &st.tui {
                    t.phase_end(name, st.failed.len() == before && !st.cancelled());
                }
            }
            summary(&st);
            let ok = st.failed.is_empty() && !st.cancelled();
            if let Some(t) = st.tui.take() {
                t.finish_and_wait(ok);
            }
            // 桌面通知：部署耗时较长，人不在终端前也能得知结果。
            if command_exists("notify-send") {
                let (icon, text) = if ok {
                    ("dialog-information", "Sonder 桌面部署完成")
                } else {
                    ("dialog-warning", "Sonder 部署有失败/跳过项，详见日志")
                };
                let _ = Command::new("notify-send").args(["-i", icon, "Sonder 部署", text]).output();
            }
        }
        other => {
            eprintln!("[错误] 未知命令: {}（可用: all / deps / tools / stow / unstow / plugins / verify / check）", other);
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
