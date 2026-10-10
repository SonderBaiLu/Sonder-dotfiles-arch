//! rightclick —— 通过 uinput 创建虚拟鼠标，模拟连点右键。
//!
//! 点击发生在当前光标位置，不移动光标；进程退出时虚拟设备自动销毁。
//!
//! 用法：
//! - rightclick            开关：开始连点（默认每秒 3 次），再次运行即停止
//! - rightclick 5          开关：以每秒 5 次的频率连点（1–100）
//! - rightclick stop       停止正在进行的连点
//! - rightclick once [次数] [总时长秒]
//!                         一次性连点后退出，默认一秒内右键三次
//!
//! 开关原理：连点进程在锁文件（$XDG_RUNTIME_DIR/rightclick.lock）上持有
//! flock，再次运行时抢不到锁，就读出其中记录的 pid 并向它发 SIGTERM。
//! 终止后的清理（释放锁、销毁虚拟设备）全部由内核自动完成，无需信号处理。

use std::env;
use std::fs::OpenOptions;
use std::io::{Seek, SeekFrom, Write};
use std::os::unix::io::AsRawFd;
use std::path::{Path, PathBuf};
use std::process::ExitCode;
use std::thread::sleep;
use std::time::Duration;

use evdev::{
    uinput::{VirtualDevice, VirtualDeviceBuilder},
    AttributeSet, EventType, InputEvent, Key,
};

/// 单次按下保持的基准时长：太短部分程序会当成抖动忽略；
/// 连点频率高时按点击间隔的 1/3 自动缩短。
const HOLD: Duration = Duration::from_millis(60);

/// 开关模式的锁文件名：持有 flock 的进程就是正在连点的进程
const LOCK_NAME: &str = "rightclick.lock";

/// 打印错误并以失败状态退出。
fn fail(msg: &str) -> ExitCode {
    eprintln!("rightclick：{msg}");
    ExitCode::FAILURE
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        None => toggle(3.0),
        Some("stop") => stop_cmd(),
        Some("once") => once(&args[1..]),
        Some(s) => match s.parse::<f64>() {
            Ok(cps) if (1.0..=100.0).contains(&cps) => toggle(cps),
            Ok(_) => fail("每秒次数需在 1–100 之间"),
            Err(_) => fail("无法识别的参数；用法：rightclick [每秒次数] | stop | once [次数] [总时长秒]"),
        },
    }
}

/// 锁文件位置：优先会话运行时目录（注销即清空），缺失时回退 /tmp。
fn lock_path() -> PathBuf {
    let dir = env::var_os("XDG_RUNTIME_DIR")
        .map_or_else(|| PathBuf::from("/tmp"), PathBuf::from);
    dir.join(LOCK_NAME)
}

/// 打开（或创建）锁文件并尝试加非阻塞独占锁；抢到说明当前没有连点进程。
fn acquire(path: &Path) -> Option<std::fs::File> {
    let file = OpenOptions::new()
        .create(true)
        .read(true)
        .write(true)
        .open(path)
        .ok()?;
    let locked = unsafe { libc::flock(file.as_raw_fd(), libc::LOCK_EX | libc::LOCK_NB) == 0 };
    locked.then_some(file)
}

/// 把自己的 pid 写进锁文件，供后续"停止"实例定位。
fn write_pid(file: &mut std::fs::File) -> std::io::Result<()> {
    file.set_len(0)?;
    file.seek(SeekFrom::Start(0))?;
    writeln!(file, "{}", std::process::id())
}

fn read_pid(path: &Path) -> Option<i32> {
    std::fs::read_to_string(path).ok()?.trim().parse().ok()
}

/// 校验 pid 对应的进程确实是 rightclick，防止锁文件内容异常时误杀无关进程。
fn is_rightclick(pid: i32) -> bool {
    std::fs::read_to_string(format!("/proc/{pid}/comm"))
        .is_ok_and(|s| s.trim() == "rightclick")
}

fn signal_stop(pid: i32) -> bool {
    unsafe { libc::kill(pid, libc::SIGTERM) == 0 }
}

/// 创建只带右键的虚拟鼠标。写 /dev/uinput 需要权限：
/// 活动会话用户已由 systemd uaccess 规则通过 ACL 放行。
fn open_virtual_mouse() -> Result<VirtualDevice, String> {
    let builder =
        VirtualDeviceBuilder::new().map_err(|e| format!("无法初始化 uinput：{e}"))?;
    let mut keys = AttributeSet::<Key>::new();
    keys.insert(Key::BTN_RIGHT);
    let builder = builder
        .name("rightclick")
        .with_keys(&keys)
        .map_err(|e| format!("无法声明右键能力：{e}"))?;
    builder.build().map_err(|e| format!("无法创建虚拟鼠标：{e}"))
}

/// 发出一次按下或释放事件（value 1 = 按下，0 = 释放）。
/// emit 会自动在批次末尾补 SYN_REPORT，把这次按键作为完整一帧提交给内核。
fn emit_button(device: &mut VirtualDevice, value: i32) -> std::io::Result<()> {
    device.emit(&[InputEvent::new(EventType::KEY, Key::BTN_RIGHT.code(), value)])
}

/// 点击一次：按下 hold 时长后松开。
fn click_once(device: &mut VirtualDevice, hold: Duration) -> Result<(), String> {
    emit_button(device, 1).map_err(|e| format!("发送按下事件失败：{e}"))?;
    sleep(hold);
    emit_button(device, 0).map_err(|e| format!("发送释放事件失败：{e}"))
}

/// 开关模式：抢到锁就开始连点；抢不到说明已在连点，向它发停止信号。
fn toggle(cps: f64) -> ExitCode {
    let path = lock_path();
    if let Some(mut file) = acquire(&path) {
        if let Err(e) = write_pid(&mut file) {
            return fail(&format!("无法写入锁文件：{e}"));
        }
        return run_loop(cps);
    }
    let pid = read_pid(&path);
    if matches!(pid, Some(p) if is_rightclick(p) && signal_stop(p)) {
        println!("rightclick：已停止连点（pid {}）", pid.unwrap());
        return ExitCode::SUCCESS;
    }
    // 持有者可能恰好正在退出：稍候重试接管锁
    for _ in 0..5 {
        sleep(Duration::from_millis(100));
        if let Some(mut file) = acquire(&path) {
            if let Err(e) = write_pid(&mut file) {
                return fail(&format!("无法写入锁文件：{e}"));
            }
            return run_loop(cps);
        }
    }
    fail("无法停止也无法接管连点（可执行 pkill rightclick 兜底）")
}

/// 开关模式主循环：每 1/cps 秒点击一次，一直运行，直到被 SIGTERM/SIGINT 终止。
fn run_loop(cps: f64) -> ExitCode {
    let mut device = match open_virtual_mouse() {
        Ok(d) => d,
        Err(m) => return fail(&m),
    };
    let interval = 1.0 / cps;
    let hold = Duration::from_secs_f64((interval / 3.0).min(HOLD.as_secs_f64()));
    let gap = Duration::from_secs_f64((interval - hold.as_secs_f64()).max(0.0));
    println!("rightclick：开始连点，每秒 {cps:.1} 次；再次运行 rightclick 即可停止");
    loop {
        if let Err(m) = click_once(&mut device, hold) {
            return fail(&m);
        }
        sleep(gap);
    }
}

/// stop 子命令：只负责停止，不开始新的连点。
fn stop_cmd() -> ExitCode {
    let path = lock_path();
    if !path.exists() || acquire(&path).is_some() {
        println!("rightclick：当前没有正在进行的连点");
        return ExitCode::SUCCESS;
    }
    let pid = match read_pid(&path) {
        Some(p) => p,
        None => return fail("锁文件里没有有效 pid；可执行 pkill rightclick 兜底"),
    };
    if !is_rightclick(pid) {
        return fail(&format!("pid {pid} 不是 rightclick 进程，拒绝停止它"));
    }
    if signal_stop(pid) {
        println!("rightclick：已停止连点（pid {pid}）");
        ExitCode::SUCCESS
    } else {
        fail(&format!("无法向 pid {pid} 发送停止信号"))
    }
}

/// once 模式：连点 count 次、总时长 span 秒后退出。
fn once(args: &[String]) -> ExitCode {
    let count: u32 = match args.first().map(|s| s.parse()) {
        None => 3,
        Some(Ok(n)) if n > 0 => n,
        Some(Err(e)) => return fail(&format!("次数无效：{e}")),
        Some(Ok(_)) => return fail("次数必须大于 0"),
    };
    let span: f64 = match args.get(1).map(|s| s.parse()) {
        None => 1.0,
        Some(Ok(v)) if v > 0.0 => v,
        Some(Err(e)) => return fail(&format!("总时长无效：{e}")),
        Some(Ok(_)) => return fail("总时长必须大于 0"),
    };
    let mut device = match open_virtual_mouse() {
        Ok(d) => d,
        Err(m) => return fail(&m),
    };
    let interval = span / count as f64;
    let hold = Duration::from_secs_f64((interval / 3.0).min(HOLD.as_secs_f64()));
    let gap = Duration::from_secs_f64((interval - hold.as_secs_f64()).max(0.0));
    for i in 0..count {
        if let Err(m) = click_once(&mut device, hold) {
            return fail(&m);
        }
        if i + 1 < count {
            sleep(gap);
        }
    }
    ExitCode::SUCCESS
}
