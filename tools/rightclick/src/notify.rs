use notify_rust::{Notification, Timeout};
/// 出发系统桌面通知 非堵塞 静默降级
pub fn send_notification(summary: &str, body: &str){
    let _= Notification::new()
        .summary(summary)
        .body(body)
        .icon("input-mouse")
        .timeout(Timeout::Milliseconds(2000))
        .show();
}
