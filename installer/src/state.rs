//! 运行时状态：日志文件、安装/跳过/失败结果，以及日志与命令执行。

use std::fs;
use std::io::{IsTerminal, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::util::now;

// ANSI 转义常量：paint 与 log 共用。
const RESET: &str = "\x1b[0m";
const BOLD: &str = "\x1b[1m";
const DIM: &str = "\x1b[2m";
const GREEN: &str = "\x1b[32m";
const YELLOW: &str = "\x1b[33m";
const RED: &str = "\x1b[31m";
const CYAN: &str = "\x1b[36m";

pub struct State {
    pub repo_dir: PathBuf,
    pub log_file: PathBuf,
    pub non_interactive: bool,
    /// 已选中的可选软件 key（--optional 传入；bootstrap.sh 部署前交互询问后转发）。
    /// 空 = 不安装任何可选软件。
    pub optional: Vec<String>,
    pub installed: Vec<String>,
    pub skipped: Vec<String>,
    pub failed: Vec<String>,
    /// 全屏 TUI 界面（仅 `all` 在真实终端下启用）；None = 纯文本模式。
    pub tui: Option<crate::tui::TuiHandle>,
}

/// 终端着色：按行首标签/符号/横幅给消息上色。
/// 仅在 stdout 是真实终端时生效；重定向到文件或管道时保持纯文本，
/// 保证 `| tee`、CI 输出不含转义序列。日志文件始终写纯文本。
fn paint(msg: &str) -> String {
    if !std::io::stdout().is_terminal() {
        return msg.to_string();
    }

    // 分节横幅：青色加粗；含"失败"字样的收尾横幅用红色示警。
    if msg.starts_with("====") || msg.starts_with("####") {
        let color = if msg.contains("失败") { RED } else { CYAN };
        return format!("{}{}{}{}", BOLD, color, msg, RESET);
    }

    // 结果符号行（部署汇总用）：按语义着色。
    let (symbol, color) = if msg.starts_with('✔') {
        ("✔", GREEN)
    } else if msg.starts_with('✘') {
        ("✘", RED)
    } else if msg.starts_with("➖") {
        ("➖", YELLOW)
    } else if msg.starts_with('ℹ') {
        ("ℹ", CYAN)
    } else {
        ("", "")
    };
    if !symbol.is_empty() {
        return format!("{}{}{}{}{}", BOLD, color, symbol, RESET, &msg[symbol.len()..]);
    }

    // 标签行：只给方括号标签上色，正文保持默认色，长行不会糊成一片。
    let (color, bold_tag) = if msg.starts_with("[OK]") {
        (GREEN, false)
    } else if msg.starts_with("[FAIL]") {
        (RED, true)
    } else if msg.starts_with("[WARN]") || msg.starts_with("[SKIP]") {
        (YELLOW, false)
    } else if msg.starts_with("[INFO]") || msg.starts_with("[QUIT]") {
        (CYAN, false)
    } else {
        // 行首无标签：可能是预检的逐条结果行，行内标记就地着色。
        return paint_inline(msg).unwrap_or_else(|| msg.to_string());
    };
    let end = msg.find(']').map(|i| i + 1).unwrap_or(0);
    let tag = if bold_tag { format!("{}{}", BOLD, &msg[..end]) } else { msg[..end].to_string() };
    format!("{}{}{}{}{}", color, tag, RESET, DIM, &msg[end..],)
}

/// 行内结果标记（预检逐条结果把 [OK]/[警告] 等放在行尾）就地着色；无命中返回 None。
fn paint_inline(msg: &str) -> Option<String> {
    let colored = msg
        .replace("[OK]", &format!("{}{}[OK]{}", GREEN, BOLD, RESET))
        .replace("[警告]", &format!("{}{}[警告]{}", YELLOW, BOLD, RESET))
        .replace("[冲突]", &format!("{}{}[冲突]{}", RED, BOLD, RESET))
        .replace("[缺失]", &format!("{}{}[缺失]{}", YELLOW, BOLD, RESET));
    (colored != msg).then_some(colored)
}

impl State {
    /// TUI 下用户是否按了取消键（部署在阶段/包之间检查）。
    pub fn cancelled(&self) -> bool {
        self.tui.as_ref().map(|t| t.cancelled()).unwrap_or(false)
    }

    /// 打印一行日志并追加到日志文件（终端带色，文件纯文本）。
    /// TUI 模式下不直接写 stdout（会打花界面），改发给界面日志窗格。
    pub fn log(&self, msg: &str) {
        let stamped = format!("[{}] {}", now(), msg);
        match &self.tui {
            Some(t) => t.log(msg),
            None if std::io::stdout().is_terminal() => {
                println!("{}[{}]{} {}", DIM, now(), RESET, paint(msg));
            }
            None => println!("{}", stamped),
        }
        let mut f = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .unwrap();
        let _ = writeln!(f, "{}", stamped);
    }

    /// 运行命令，stdout 追加到日志，stderr 输出到终端，返回是否成功
    pub fn run_logged(&self, program: &str, args: &[&str]) -> bool {
        let mut f = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .unwrap();
        let _ = writeln!(f, "---- $ {} {}", program, args.join(" "));
        if self.tui.is_some() {
            // TUI：整段捕获输出，结束后写入日志文件并送界面窗格，
            // 避免子进程输出打花全屏界面（界面侧的进度条承担过程反馈）。
            return match Command::new(program).args(args).output() {
                Ok(out) => {
                    for half in [&out.stdout, &out.stderr] {
                        for line in String::from_utf8_lossy(half).lines() {
                            let _ = writeln!(f, "{}", line);
                            if let Some(t) = &self.tui {
                                t.log(line);
                            }
                        }
                    }
                    out.status.success()
                }
                Err(e) => {
                    let _ = writeln!(f, "执行失败: {}", e);
                    false
                }
            };
        }
        let status = Command::new(program)
            .args(args)
            .stdout(f.try_clone().unwrap())
            .stderr(std::process::Stdio::inherit())
            .status();
        match status {
            Ok(s) => s.success(),
            Err(e) => {
                let _ = writeln!(f, "执行失败: {}", e);
                false
            }
        }
    }

    /// 运行命令并捕获 stdout（静默检查用）
    pub fn run_capture(&self, program: &str, args: &[&str]) -> Option<String> {
        let out = Command::new(program).args(args).output().ok()?;
        Some(String::from_utf8_lossy(&out.stdout).to_string())
    }

    /// 同 run_logged，但在指定目录下执行（构建仓库内工具时用）
    pub fn run_logged_in(&self, dir: &Path, program: &str, args: &[&str]) -> bool {
        let mut f = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .unwrap();
        let _ = writeln!(f, "---- $ (cd {}) {} {}", dir.display(), program, args.join(" "));
        if self.tui.is_some() {
            // TUI：同 run_logged 的整段捕获策略。
            return match Command::new(program).args(args).current_dir(dir).output() {
                Ok(out) => {
                    for half in [&out.stdout, &out.stderr] {
                        for line in String::from_utf8_lossy(half).lines() {
                            let _ = writeln!(f, "{}", line);
                            if let Some(t) = &self.tui {
                                t.log(line);
                            }
                        }
                    }
                    out.status.success()
                }
                Err(e) => {
                    let _ = writeln!(f, "执行失败: {}", e);
                    false
                }
            };
        }
        let status = Command::new(program)
            .args(args)
            .current_dir(dir)
            .stdout(f.try_clone().unwrap())
            .stderr(std::process::Stdio::inherit())
            .status();
        match status {
            Ok(s) => s.success(),
            Err(e) => {
                let _ = writeln!(f, "执行失败: {}", e);
                false
            }
        }
    }
}

/// 部署汇总：终端上 ✔/➖/✘ 三色符号行，日志文件同结构纯文本。
pub fn summary(st: &State) {
    st.log("==================== 部署汇总 ====================");
    st.log(&format!("✔ 新安装 {} 个包", st.installed.len()));
    if !st.installed.is_empty() {
        st.log(&format!("      {}", st.installed.join(" ")));
    }
    st.log(&format!("➖ 跳过 {} 个包", st.skipped.len()));
    if !st.skipped.is_empty() {
        st.log(&format!("      {}", st.skipped.join(" ")));
    }
    st.log(&format!("✘ 失败 {} 项", st.failed.len()));
    if !st.failed.is_empty() {
        st.log(&format!("      {}", st.failed.join(" ")));
    }
    st.log(&format!("ℹ 完整日志: {}", st.log_file.display()));
}
