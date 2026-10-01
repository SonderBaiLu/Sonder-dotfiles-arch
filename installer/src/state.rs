//! 运行时状态：日志文件、安装/跳过/失败结果，以及日志与命令执行。

use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;

use crate::util::now;

pub struct State {
    pub repo_dir: PathBuf,
    pub log_file: PathBuf,
    pub non_interactive: bool,
    pub installed: Vec<String>,
    pub skipped: Vec<String>,
    pub failed: Vec<String>,
}

impl State {
    /// 打印一行日志并追加到日志文件
    pub fn log(&self, msg: &str) {
        let line = format!("[{}] {}", now(), msg);
        println!("{}", line);
        let mut f = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .unwrap();
        let _ = writeln!(f, "{}", line);
    }

    /// 运行命令，stdout 追加到日志，stderr 输出到终端，返回是否成功
    pub fn run_logged(&self, program: &str, args: &[&str]) -> bool {
        let mut f = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .unwrap();
        let _ = writeln!(f, "---- $ {} {}", program, args.join(" "));
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
}

/// 安装类子命令的结尾汇总
pub fn summary(st: &State) {
    st.log("==================== 部署汇总 ====================");
    st.log(&format!("新安装: {} 个包", st.installed.len()));
    if !st.installed.is_empty() {
        st.log(&format!("  {}", st.installed.join(" ")));
    }
    st.log(&format!("跳过:   {} 个包", st.skipped.len()));
    if !st.skipped.is_empty() {
        st.log(&format!("  {}", st.skipped.join(" ")));
    }
    st.log(&format!("失败:   {} 项", st.failed.len()));
    if !st.failed.is_empty() {
        st.log(&format!("  {}", st.failed.join(" ")));
    }
    st.log(&format!("完整日志: {}", st.log_file.display()));
}
