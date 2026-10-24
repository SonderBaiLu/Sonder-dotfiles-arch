//! 全屏 TUI 部署界面（ratatui + crossterm）。
//!
//! 仅在 `all` 且 stdout 是真实终端、未指定 `--no-tui` 时启用；管道重定向
//! 与其它子命令自动回落纯文本。部署侧只通过 `TuiHandle` 发事件，不感知
//! 终端状态；渲染线程独立绘制并处理按键，Q/Esc 请求取消（部署在阶段与
//! 包之间检查取消标志，不会打断正在运行的 pacman/paru）。

use std::io::{stdout, IsTerminal};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, RecvTimeoutError, Sender};
use std::sync::Arc;
use std::thread::JoinHandle;
use std::time::{Duration, Instant};

use crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers};
use ratatui::{
    backend::CrosstermBackend,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Gauge, Paragraph},
    Frame, Terminal,
};

/// 阶段条上的状态。
const PENDING: u8 = 0;
const RUNNING: u8 = 1;
const OK: u8 = 2;
const FAIL: u8 = 3;

enum UiEvent {
    Log(String),
    PhaseStart(String),
    PhaseEnd(String, bool),
    Progress(usize, usize, String),
    Finish(bool),
}

pub struct TuiHandle {
    tx: Sender<UiEvent>,
    pub cancel: Arc<AtomicBool>,
    worker: Option<JoinHandle<()>>,
}

impl TuiHandle {
    /// stdout 是真实终端时启动渲染线程，否则返回 None（调用方走纯文本）。
    pub fn spawn() -> Option<TuiHandle> {
        if !stdout().is_terminal() {
            return None;
        }
        let (tx, rx) = mpsc::channel();
        let cancel = Arc::new(AtomicBool::new(false));
        let cancel_in_ui = Arc::clone(&cancel);
        let worker = std::thread::spawn(move || run_ui(rx, cancel_in_ui));
        Some(TuiHandle { tx, cancel, worker: Some(worker) })
    }

    pub fn log(&self, line: &str) {
        let _ = self.tx.send(UiEvent::Log(line.to_string()));
    }

    pub fn phase_start(&self, name: &str) {
        let _ = self.tx.send(UiEvent::PhaseStart(name.to_string()));
    }

    pub fn phase_end(&self, name: &str, ok: bool) {
        let _ = self.tx.send(UiEvent::PhaseEnd(name.to_string(), ok));
    }

    pub fn progress(&self, done: usize, total: usize, label: &str) {
        let _ = self.tx.send(UiEvent::Progress(done, total, label.to_string()));
    }

    pub fn cancelled(&self) -> bool {
        self.cancel.load(Ordering::Relaxed)
    }

    /// 部署结束：发送 Finish，渲染线程展示汇总屏，按键或 10 秒超时后恢复终端并退出。
    pub fn finish_and_wait(mut self, ok: bool) {
        let _ = self.tx.send(UiEvent::Finish(ok));
        if let Some(w) = self.worker.take() {
            let _ = w.join();
        }
    }
}

impl Drop for TuiHandle {
    fn drop(&mut self) {
        // worker 尚未 join（异常路径）：tx 随 self 一起销毁后渲染线程收到
        // Disconnected 会自行退出并恢复终端，这里只等它收尾。
        if self.worker.is_some() {
            // 先终止渲染循环：cancel 不影响退出逻辑，Disconnect 才是退出条件。
            // worker 拿着 rx，无法在此 join；交给 Disconnect 路径即可。
        }
    }
}

/// 渲染线程主循环：50ms 节流重绘，按键即时响应。
fn run_ui(rx: Receiver<UiEvent>, cancel: Arc<AtomicBool>) {
    let mut terminal = match setup() {
        Some(t) => t,
        None => return,
    };
    let mut phases: Vec<(String, u8)> = Vec::new();
    let mut logs: Vec<String> = Vec::new();
    let mut progress: Option<(usize, usize, String)> = None;
    let mut finished_at: Option<Instant> = None;
    let mut deploy_ok = false;
    let start = Instant::now();

    loop {
        // 1. 收干事件队列；通道断开（部署线程结束且未发 Finish）按失败收场。
        loop {
            match rx.recv_timeout(Duration::from_millis(50)) {
                Ok(ev) => match ev {
                    UiEvent::Log(line) => {
                        logs.push(line);
                        if logs.len() > 800 {
                            logs.drain(0..200);
                        }
                    }
                    UiEvent::PhaseStart(name) => set_phase(&mut phases, &name, RUNNING),
                    UiEvent::PhaseEnd(name, ok) => set_phase(&mut phases, &name, if ok { OK } else { FAIL }),
                    UiEvent::Progress(done, total, label) => progress = Some((done, total, label)),
                    UiEvent::Finish(ok) => {
                        deploy_ok = ok;
                        finished_at = Some(Instant::now());
                        progress = None;
                    }
                },
                Err(RecvTimeoutError::Timeout) => break,
                Err(RecvTimeoutError::Disconnected) => {
                    if finished_at.is_none() {
                        finished_at = Some(Instant::now());
                        deploy_ok = false;
                    }
                }
            }
        }

        // 2. 绘制（Finish 后绘制汇总屏）。
        let _ = terminal.draw(|f| {
            if finished_at.is_some() {
                draw_finish(f, deploy_ok);
            } else {
                draw_deploy(f, &phases, &logs, &progress, start.elapsed());
            }
        });

        // 3. 按键：进行中 Q/Esc/Ctrl-C 请求取消；汇总屏任意确认键或 10 秒后退出。
        if event::poll(Duration::from_millis(50)).unwrap_or(false) {
            if let Ok(Event::Key(key)) = event::read() {
                if key.kind == KeyEventKind::Press {
                    let confirm = matches!(key.code, KeyCode::Char('q') | KeyCode::Char('Q') | KeyCode::Esc | KeyCode::Enter);
                    let cancel_key = confirm
                        || (key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c'));
                    if finished_at.is_some() {
                        if confirm {
                            break;
                        }
                    } else if cancel_key {
                        cancel.store(true, Ordering::Relaxed);
                        logs.push("[WARN] 已请求取消：当前步骤完成后停止".into());
                    }
                }
            }
        }
        if let Some(t) = finished_at {
            if t.elapsed() > Duration::from_secs(10) {
                break;
            }
        }
    }
    restore(&mut terminal);
}

fn set_phase(phases: &mut Vec<(String, u8)>, name: &str, state: u8) {
    match phases.iter_mut().find(|(n, _)| n == name) {
        Some(entry) => entry.1 = state,
        None => phases.push((name.to_string(), state)),
    }
}

fn draw_deploy(f: &mut Frame, phases: &[(String, u8)], logs: &[String], progress: &Option<(usize, usize, String)>, elapsed: Duration) {
    let rows = ratatui::layout::Layout::vertical([
        ratatui::layout::Constraint::Length(1), // 标题
        ratatui::layout::Constraint::Length(1), // 阶段条
        ratatui::layout::Constraint::Min(3),    // 日志
        ratatui::layout::Constraint::Length(3), // 进度条
        ratatui::layout::Constraint::Length(1), // 底栏
    ])
    .split(f.area());

    // 标题行。
    let title = Line::from(vec![
        Span::styled(" Sonder 桌面部署 ", Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        Span::styled(format!("· 已进行 {}s", elapsed.as_secs()), Style::new().fg(Color::DarkGray)),
        Span::styled("（Q 请求取消）", Style::new().fg(Color::DarkGray)),
    ]);
    f.render_widget(Paragraph::new(title), rows[0]);

    // 阶段条：图标 + 名称，按状态着色。
    let mut steps = vec![Span::raw(" ")];
    for (index, (name, state)) in phases.iter().enumerate() {
        if index > 0 {
            steps.push(Span::styled(" ─ ", Style::new().fg(Color::DarkGray)));
        }
        let (icon, color) = match *state {
            PENDING => ("·", Color::DarkGray),
            RUNNING => ("▶", Color::Cyan),
            OK => ("✓", Color::Green),
            _ => ("✗", Color::Red),
        };
        steps.push(Span::styled(format!("{icon} {name}"), Style::new().fg(color).add_modifier(Modifier::BOLD)));
    }
    f.render_widget(Paragraph::new(Line::from(steps)), rows[1]);

    // 日志窗格：按行首标签着色，自动贴底。
    let visible = rows[2].height.saturating_sub(2) as usize;
    let scroll = logs.len().saturating_sub(visible) as u16;
    let lines: Vec<Line> = logs.iter().map(|l| log_line(l)).collect();
    f.render_widget(
        Paragraph::new(lines)
            .block(Block::default().borders(Borders::ALL).title(" 实时日志 "))
            .scroll((scroll, 0)),
        rows[2],
    );

    // 进度条：进行中显示当前包；空闲时提示。
    match progress {
        Some((done, total, label)) => {
            let ratio = if *total == 0 { 0.0 } else { *done as f64 / *total as f64 };
            let gauge = Gauge::default()
                .gauge_style(Style::new().fg(Color::Cyan))
                .ratio(ratio.min(1.0))
                .label(format!(" {}/{} · {} ", done, total, label));
            f.render_widget(gauge, rows[3]);
        }
        None => {
            f.render_widget(
                Paragraph::new(Span::styled(" 等待部署事件…", Style::new().fg(Color::DarkGray))),
                rows[3],
            );
        }
    }

    // 底栏。
    f.render_widget(
        Paragraph::new(Span::styled(" Q/Esc 取消 · 部署在阶段与包之间响应取消，不会打断安装器 ", Style::new().fg(Color::DarkGray))),
        rows[4],
    );
}

fn draw_finish(f: &mut Frame, ok: bool) {
    let (icon, color, text) = if ok {
        ("✔", Color::Green, "部署全部成功")
    } else {
        ("✘", Color::Red, "部署存在失败/跳过项，详见日志")
    };
    let area = ratatui::layout::Layout::vertical([
        ratatui::layout::Constraint::Percentage(35),
        ratatui::layout::Constraint::Length(7),
        ratatui::layout::Constraint::Percentage(35),
    ])
    .split(f.area())[1];
    let lines = vec![
        Line::from(""),
        Line::from(Span::styled(format!("        {icon}  {text}"), Style::new().fg(color).add_modifier(Modifier::BOLD))),
        Line::from(""),
        Line::from(Span::styled("  按任意确认键退出，10 秒后自动关闭", Style::new().fg(Color::DarkGray))),
    ];
    f.render_widget(
        Paragraph::new(lines).block(
            Block::default()
                .borders(Borders::ALL)
                .title(" 部署完成 ")
                .border_style(Style::new().fg(color)),
        ),
        area,
    );
}

/// 单行日志着色：与纯文本模式的标签语义一致。
fn log_line(line: &str) -> Line<'static> {
    let style = if line.starts_with("[OK]") {
        Style::new().fg(Color::Green)
    } else if line.starts_with("[FAIL]") {
        Style::new().fg(Color::Red).add_modifier(Modifier::BOLD)
    } else if line.starts_with("[WARN]") || line.starts_with("[SKIP]") {
        Style::new().fg(Color::Yellow)
    } else if line.starts_with("[INFO]") || line.starts_with("[QUIT]") {
        Style::new().fg(Color::Cyan)
    } else if line.starts_with("====") || line.starts_with("####") {
        Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD)
    } else {
        Style::new()
    };
    Line::from(Span::styled(line.to_string(), style))
}

fn setup() -> Option<Terminal<CrosstermBackend<std::io::Stdout>>> {
    use crossterm::terminal::{enable_raw_mode, EnterAlternateScreen};
    let mut stdout = stdout();
    enable_raw_mode().ok()?;
    crossterm::execute!(stdout, EnterAlternateScreen).ok()?;
    Terminal::new(CrosstermBackend::new(stdout)).ok()
}

fn restore(terminal: &mut Terminal<CrosstermBackend<std::io::Stdout>>) {
    use crossterm::terminal::{disable_raw_mode, LeaveAlternateScreen};
    let _ = crossterm::execute!(terminal.backend_mut(), LeaveAlternateScreen);
    let _ = disable_raw_mode();
    let _ = terminal.show_cursor();
}
