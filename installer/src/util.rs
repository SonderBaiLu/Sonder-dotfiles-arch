//! 通用小工具：时间、PATH 查找、目录列举、相对路径。

use std::env;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

/// 当前时间（date 命令，避免引入 chrono）
pub fn now() -> String {
    std::process::Command::new("date")
        .arg("+%Y-%m-%d %H:%M:%S")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default()
        .trim()
        .to_string()
}

/// Unix 秒时间戳（用于备份文件名）
pub fn timestamp() -> String {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs().to_string())
        .unwrap_or_default()
}

/// 是否处于交互终端（能读用户输入）
pub fn is_tty() -> bool {
    fs::File::open("/dev/tty").is_ok()
}

/// read_dir 的容错版本：失败返回空列表
pub fn read_dir_ok(p: &Path) -> Vec<std::io::Result<fs::DirEntry>> {
    match fs::read_dir(p) {
        Ok(rd) => rd.collect(),
        Err(_) => Vec::new(),
    }
}

/// 计算 from → to 的相对路径（两者需为绝对路径）
pub fn relative_path(from: &Path, to: &Path) -> PathBuf {
    let from_c = fs::canonicalize(from).unwrap_or_else(|_| from.to_path_buf());
    let to_c = fs::canonicalize(to).unwrap_or_else(|_| to.to_path_buf());
    let from_comps: Vec<Component> = from_c.components().collect();
    let to_comps: Vec<Component> = to_c.components().collect();
    let mut i = 0;
    while i < from_comps.len() && i < to_comps.len() && from_comps[i] == to_comps[i] {
        i += 1;
    }
    let mut rel = PathBuf::new();
    for _ in i..from_comps.len() {
        rel.push("..");
    }
    for c in &to_comps[i..] {
        rel.push(c.as_os_str());
    }
    if rel.as_os_str().is_empty() {
        rel.push(".");
    }
    rel
}

/// PATH 中查找可执行文件（command -v 是 shell 内建，不能直接 exec）
pub fn command_exists(name: &str) -> bool {
    let path = env::var("PATH").unwrap_or_default();
    for dir in path.split(':') {
        let candidate = Path::new(dir).join(name);
        if let Ok(md) = candidate.metadata() {
            if md.is_file() && std::os::unix::fs::PermissionsExt::mode(&md.permissions()) & 0o111 != 0 {
                return true;
            }
        }
    }
    false
}
