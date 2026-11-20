use std::{
    env, fs,
    io::Read,
    path::PathBuf,
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use anyhow::{anyhow, Context, Result};
use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use serde_json::{json, Value};
use tokio::{
    sync::{broadcast, watch},
    time::{interval, sleep, MissedTickBehavior},
};
use tokio_tungstenite::tungstenite::{
    client::IntoClientRequest,
    http::HeaderValue,
    Message as WsMessage,
};
use tower_http::services::ServeDir;
use tracing::{debug, info, warn};

const USER_AGENT: &str =
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";
// B 站直播 web 接口的 w_rid 签名盐，来自公开的前端实现。
const W_RID_SALT: &str = "ea1db124af3c7062474693fa704f4ff8";

#[derive(Debug, Clone, Deserialize)]
#[serde(default)]
struct Config {
    /// 直播间房号；0 表示只提供静态覆盖层，不连弹幕。
    room_id: u64,
    /// 本地 HTTP / WebSocket 端口。
    port: u16,
    /// 默认只监听本机，不要暴露到公网。
    host: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            room_id: 0,
            port: 9100,
            host: "127.0.0.1".to_string(),
        }
    }
}

#[derive(Debug, Clone, Default)]
struct BridgeStatus {
    connected: bool,
    live: bool,
    room_id: u64,
    online: u64,
    watched: u64,
    uptime: u64,
    title: String,
}

#[derive(Clone)]
struct AppState {
    tx: broadcast::Sender<String>,
    status: watch::Receiver<BridgeStatus>,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "obs_overlay_bridge=info,tower_http=warn".into()),
        )
        .init();

    let cfg = load_config();
    let (tx, _) = broadcast::channel::<String>(512);
    let (status_tx, status_rx) = watch::channel(BridgeStatus {
        room_id: cfg.room_id,
        ..Default::default()
    });
    let state = AppState {
        tx: tx.clone(),
        status: status_rx,
    };

    if cfg.room_id == 0 {
        warn!("config.toml 里没有 room_id：覆盖层可以打开，但不会连接 B 站弹幕");
    } else {
        tokio::spawn(run_bilibili(cfg.room_id, tx.clone(), status_tx.clone()));
        spawn_now_playing(tx.clone());
    }

    let app = Router::new()
        .route("/ws", get(ws_handler))
        .route("/api/status", get(api_status))
        .fallback_service(ServeDir::new(web_dir()))
        .with_state(state);

    let addr = format!("{}:{}", cfg.host, cfg.port);
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .with_context(|| format!("绑定 {addr} 失败"))?;
    info!("覆盖层: http://{addr}/  WebSocket: ws://{addr}/ws");
    axum::serve(listener, app).await?;
    Ok(())
}

fn load_config() -> Config {
    let mut cfg = match fs::read_to_string("config.toml") {
        Ok(text) => match toml::from_str::<Config>(&text) {
            Ok(value) => value,
            Err(err) => {
                warn!("config.toml 解析失败，使用默认配置: {err}");
                Config::default()
            }
        },
        Err(_) => Config::default(),
    };

    if let Ok(value) = env::var("BILI_ROOM_ID") {
        if let Ok(room_id) = value.parse() {
            cfg.room_id = room_id;
        }
    }
    if let Ok(value) = env::var("OVERLAY_PORT") {
        if let Ok(port) = value.parse() {
            cfg.port = port;
        }
    }
    cfg
}

fn web_dir() -> PathBuf {
    let local = PathBuf::from("web");
    if local.join("index.html").exists() {
        return local;
    }
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("web")
}

/* ---------------- HTTP / WebSocket 服务 ---------------- */

async fn ws_handler(ws: WebSocketUpgrade, State(state): State<AppState>) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(mut socket: WebSocket, state: AppState) {
    let mut rx = state.tx.subscribe();
    let initial = status_json(&state.status.borrow()).to_string();
    if socket.send(Message::Text(initial.into())).await.is_err() {
        return;
    }

    loop {
        tokio::select! {
            message = rx.recv() => {
                match message {
                    Ok(text) => {
                        if socket.send(Message::Text(text.into())).await.is_err() {
                            break;
                        }
                    }
                    Err(broadcast::error::RecvError::Lagged(_)) => continue,
                    Err(_) => break,
                }
            }
            incoming = socket.next() => {
                match incoming {
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(Message::Ping(payload))) => {
                        if socket.send(Message::Pong(payload)).await.is_err() {
                            break;
                        }
                    }
                    Some(Err(_)) => break,
                    _ => {}
                }
            }
        }
    }
}

async fn api_status(State(state): State<AppState>) -> impl IntoResponse {
    Json(status_json(&state.status.borrow()))
}

fn status_json(status: &BridgeStatus) -> Value {
    json!({
        "type": "status",
        "connected": status.connected,
        "live": status.live,
        "room_id": status.room_id,
        "online": status.online,
        "watched": status.watched,
        "uptime": status.uptime,
        "title": status.title,
    })
}

/* ---------------- B 站弹幕连接 ---------------- */

async fn run_bilibili(
    room_id: u64,
    tx: broadcast::Sender<String>,
    status_tx: watch::Sender<BridgeStatus>,
) {
    let client = match reqwest::Client::builder().user_agent(USER_AGENT).build() {
        Ok(client) => client,
        Err(err) => {
            warn!("创建 HTTP 客户端失败: {err}");
            return;
        }
    };
    let mut live_since: Option<Instant> = None;

    loop {
        match connect_once(room_id, &client, &tx, &status_tx, &mut live_since).await {
            Ok(()) => info!("B 站弹幕连接已结束，准备重连"),
            Err(err) => warn!("B 站弹幕连接失败: {err:#}"),
        }

        let mut status = status_tx.borrow().clone();
        status.connected = false;
        let _ = status_tx.send(status.clone());
        let _ = tx.send(status_json(&status).to_string());
        sleep(Duration::from_secs(5)).await;
    }
}

async fn connect_once(
    room_id: u64,
    client: &reqwest::Client,
    tx: &broadcast::Sender<String>,
    status_tx: &watch::Sender<BridgeStatus>,
    live_since: &mut Option<Instant>,
) -> Result<()> {
    let room = fetch_room_info(client, room_id).await?;
    let mut status = BridgeStatus {
        connected: false,
        live: room.live,
        room_id,
        online: 0,
        watched: 0,
        uptime: 0,
        title: room.title.clone(),
    };
    if status.live {
        *live_since = Some(Instant::now());
    } else {
        *live_since = None;
    }

    let _ = status_tx.send(status.clone());
    let _ = tx.send(status_json(&status).to_string());
    let _ = tx.send(
        json!({"type": "live", "live": status.live, "title": status.title}).to_string(),
    );
    let _ = tx.send(json!({
        "type": "room",
        "room_id": room_id,
        "title": status.title,
        "live": status.live,
    })
    .to_string());

    let (buvid3, buvid4) = fetch_buvid(client).await?;
    let danmu = fetch_danmu_info(client, room_id, &buvid3, &buvid4).await?;
    info!(
        "连接弹幕服务器 {}:{}（房间 {}）",
        danmu.host, danmu.port, room_id
    );

    let url = format!("wss://{}:{}/sub", danmu.host, danmu.port);
    let mut request = url
        .as_str()
        .into_client_request()
        .context("构造 B 站 WebSocket 请求失败")?;
    request
        .headers_mut()
        .insert("User-Agent", HeaderValue::from_static(USER_AGENT));
    request.headers_mut().insert(
        "Origin",
        HeaderValue::from_static("https://live.bilibili.com"),
    );
    request.headers_mut().insert(
        "Referer",
        HeaderValue::from_str(&format!("https://live.bilibili.com/{room_id}"))?,
    );

    let (mut ws, _) = tokio_tungstenite::connect_async(request)
        .await
        .context("连接 B 站弹幕 WebSocket 失败")?;

    let auth = json!({
        "uid": 0,
        "roomid": room_id,
        "protover": 3,
        "platform": "web",
        "type": 2,
        "key": danmu.token,
    });
    ws.send(WsMessage::Binary(
        build_packet(7, auth.to_string().as_bytes(), 1).into(),
    ))
    .await
    .context("发送 B 站弹幕认证包失败")?;

    status.connected = true;
    let _ = status_tx.send(status.clone());
    let _ = tx.send(status_json(&status).to_string());

    let mut heartbeat = interval(Duration::from_secs(30));
    heartbeat.set_missed_tick_behavior(MissedTickBehavior::Delay);
    heartbeat.tick().await;
    let mut stats_tick = interval(Duration::from_secs(10));
    stats_tick.set_missed_tick_behavior(MissedTickBehavior::Delay);
    stats_tick.tick().await;

    loop {
        tokio::select! {
            _ = heartbeat.tick() => {
                ws.send(WsMessage::Binary(build_packet(2, b"[object Object]", 1).into()))
                    .await
                    .context("发送弹幕心跳失败")?;
            }
            _ = stats_tick.tick() => {
                if let Some(start) = live_since {
                    status.uptime = start.elapsed().as_secs();
                }
                let _ = tx.send(json!({
                    "type": "stats",
                    "online": status.online,
                    "watched": status.watched,
                    "uptime": status.uptime,
                }).to_string());
            }
            message = ws.next() => {
                match message {
                    Some(Ok(WsMessage::Binary(data))) => {
                        let mut values = Vec::new();
                        parse_packet(&data, &mut values);
                        for value in values {
                            handle_bili_value(&value, &mut status, live_since, tx);
                        }
                        let _ = status_tx.send(status.clone());
                    }
                    Some(Ok(WsMessage::Text(text))) => {
                        if let Ok(value) = serde_json::from_str::<Value>(&text) {
                            handle_bili_value(&value, &mut status, live_since, tx);
                            let _ = status_tx.send(status.clone());
                        }
                    }
                    Some(Ok(WsMessage::Ping(payload))) => {
                        ws.send(WsMessage::Pong(payload)).await?;
                    }
                    Some(Ok(WsMessage::Close(_))) | None => return Ok(()),
                    Some(Ok(_)) => {}
                    Some(Err(err)) => return Err(err.into()),
                }
            }
        }
    }
}

struct RoomInfo {
    live: bool,
    title: String,
}

async fn fetch_room_info(client: &reqwest::Client, room_id: u64) -> Result<RoomInfo> {
    let url = format!("https://api.live.bilibili.com/room/v1/Room/get_info?room_id={room_id}");
    let value = get_json(client, &url, "https://live.bilibili.com/", None).await?;
    let data = value.get("data").unwrap_or(&Value::Null);
    Ok(RoomInfo {
        live: data.get("live_status").and_then(Value::as_u64) == Some(1),
        title: data
            .get("title")
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string(),
    })
}

async fn fetch_buvid(client: &reqwest::Client) -> Result<(String, String)> {
    let value = get_json(
        client,
        "https://api.bilibili.com/x/frontend/finger/spi",
        "https://www.bilibili.com/",
        None,
    )
    .await?;
    let data = value
        .get("data")
        .context("finger/spi 响应缺少 data")?;
    let buvid3 = data
        .get("b_3")
        .and_then(Value::as_str)
        .context("finger/spi 响应缺少 b_3")?
        .to_string();
    let buvid4 = data
        .get("b_4")
        .and_then(Value::as_str)
        .context("finger/spi 响应缺少 b_4")?
        .to_string();
    Ok((buvid3, buvid4))
}

struct DanmuInfo {
    token: String,
    host: String,
    port: u16,
}

async fn fetch_danmu_info(
    client: &reqwest::Client,
    room_id: u64,
    buvid3: &str,
    buvid4: &str,
) -> Result<DanmuInfo> {
    let wts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .context("系统时间早于 Unix epoch")?
        .as_secs();
    let query = format!("id={room_id}&type=0&wts={wts}");
    let w_rid = format!("{:x}", md5::compute(format!("{query}{W_RID_SALT}")));
    let url = format!(
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo?{query}&w_rid={w_rid}"
    );
    let referer = format!("https://live.bilibili.com/{room_id}");
    let cookie = format!("buvid3={buvid3}; buvid4={buvid4}");
    let value = get_json(client, &url, &referer, Some(&cookie)).await?;
    let data = value
        .get("data")
        .context("getDanmuInfo 响应缺少 data")?;
    let token = data
        .get("token")
        .and_then(Value::as_str)
        .context("getDanmuInfo 响应缺少 token")?
        .to_string();
    let host_list = data
        .get("host_list")
        .and_then(Value::as_array)
        .context("getDanmuInfo 响应缺少 host_list")?;
    let first = host_list.first().context("getDanmuInfo 的 host_list 为空")?;
    let host = first
        .get("host")
        .and_then(Value::as_str)
        .context("host_list 条目缺少 host")?
        .to_string();
    let port = first
        .get("wss_port")
        .and_then(Value::as_u64)
        .unwrap_or(443) as u16;
    Ok(DanmuInfo { token, host, port })
}

async fn get_json(
    client: &reqwest::Client,
    url: &str,
    referer: &str,
    cookie: Option<&str>,
) -> Result<Value> {
    let mut request = client
        .get(url)
        .header("User-Agent", USER_AGENT)
        .header("Referer", referer)
        .header("Origin", "https://live.bilibili.com");
    if let Some(cookie) = cookie {
        request = request.header("Cookie", cookie);
    }

    let response = request
        .send()
        .await
        .with_context(|| format!("请求 {url} 失败"))?;
    let status = response.status();
    let value: Value = response
        .json()
        .await
        .with_context(|| format!("解析 {url} 响应失败"))?;
    if !status.is_success() || value.get("code").and_then(Value::as_i64) != Some(0) {
        return Err(anyhow!(
            "{url}: HTTP {status}, code={}, message={}",
            value.get("code").map(Value::to_string).unwrap_or_else(|| "?".into()),
            value
                .get("message")
                .and_then(Value::as_str)
                .unwrap_or("")
        ));
    }
    Ok(value)
}

/* ---------------- 弹幕包解析 ---------------- */

fn build_packet(op: u32, body: &[u8], seq: u32) -> Vec<u8> {
    let packet_len = body.len() + 16;
    let mut out = Vec::with_capacity(packet_len);
    out.extend_from_slice(&(packet_len as u32).to_be_bytes());
    out.extend_from_slice(&16u16.to_be_bytes());
    out.extend_from_slice(&1u16.to_be_bytes());
    out.extend_from_slice(&op.to_be_bytes());
    out.extend_from_slice(&seq.to_be_bytes());
    out.extend_from_slice(body);
    out
}

fn parse_packet(data: &[u8], out: &mut Vec<Value>) {
    if data.len() < 16 {
        return;
    }
    let packet_len = be_u32(&data[0..4]) as usize;
    let header_len = be_u16(&data[4..6]) as usize;
    let proto_ver = be_u16(&data[6..8]);
    let op = be_u32(&data[8..12]);
    if packet_len < header_len || packet_len > data.len() {
        return;
    }
    let body = &data[header_len..packet_len];

    match op {
        5 => match proto_ver {
            2 => {
                if let Ok(payload) = zlib_decompress(body) {
                    parse_nested(&payload, out);
                }
            }
            3 => {
                if let Ok(payload) = brotli_decompress(body) {
                    parse_nested(&payload, out);
                }
            }
            _ => {
                if let Ok(value) = serde_json::from_slice(body) {
                    out.push(value);
                }
            }
        },
        8 => debug!("B 站弹幕认证回复: {}", String::from_utf8_lossy(body)),
        _ => {}
    }
}

fn parse_nested(data: &[u8], out: &mut Vec<Value>) {
    let mut offset = 0;
    while offset + 16 <= data.len() {
        let packet_len = be_u32(&data[offset..offset + 4]) as usize;
        if packet_len < 16 || offset + packet_len > data.len() {
            break;
        }
        let header_len = be_u16(&data[offset + 4..offset + 6]) as usize;
        let op = be_u32(&data[offset + 8..offset + 12]);
        if op == 5 && header_len <= packet_len {
            let body = &data[offset + header_len..offset + packet_len];
            if let Ok(value) = serde_json::from_slice(body) {
                out.push(value);
            }
        }
        offset += packet_len;
    }
}

fn be_u16(bytes: &[u8]) -> u16 {
    u16::from_be_bytes([bytes[0], bytes[1]])
}

fn be_u32(bytes: &[u8]) -> u32 {
    u32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]])
}

fn zlib_decompress(input: &[u8]) -> Result<Vec<u8>> {
    let mut decoder = flate2::read::ZlibDecoder::new(input);
    let mut out = Vec::new();
    decoder.read_to_end(&mut out)?;
    Ok(out)
}

fn brotli_decompress(input: &[u8]) -> Result<Vec<u8>> {
    let mut decoder = brotli::Decompressor::new(input, 4096);
    let mut out = Vec::new();
    decoder.read_to_end(&mut out)?;
    Ok(out)
}

/* ---------------- 消息转成覆盖层事件 ---------------- */

fn handle_bili_value(
    value: &Value,
    status: &mut BridgeStatus,
    live_since: &mut Option<Instant>,
    tx: &broadcast::Sender<String>,
) {
    let cmd = value.get("cmd").and_then(Value::as_str).unwrap_or("");
    let data = value.get("data").unwrap_or(&Value::Null);

    if cmd.starts_with("DANMU_MSG") {
        let Some(info) = value.get("info").and_then(Value::as_array) else {
            return;
        };
        let text = info.get(1).and_then(Value::as_str).unwrap_or("");
        if text.is_empty() {
            return;
        }
        let user_info = info.get(2).and_then(Value::as_array);
        let uid = user_info
            .and_then(|items| items.first())
            .and_then(Value::as_u64)
            .unwrap_or(0);
        let user = user_info
            .and_then(|items| items.get(1))
            .and_then(Value::as_str)
            .unwrap_or("匿名");
        let medal = info.get(3).and_then(Value::as_array).and_then(|items| {
            let name = items.get(1).and_then(Value::as_str).unwrap_or("");
            if name.is_empty() {
                None
            } else {
                let level = items.first().and_then(Value::as_u64).unwrap_or(0);
                Some(format!("{name} {level}"))
            }
        });
        let guard = info.get(7).and_then(Value::as_u64).unwrap_or(0);
        let _ = tx.send(
            json!({
                "type": "chat",
                "user": user,
                "uid": uid,
                "text": text,
                "guard": guard,
                "medal": medal,
                "anchor": false,
            })
            .to_string(),
        );
        return;
    }

    match cmd {
        "SEND_GIFT" => {
            let user = data
                .get("uname")
                .and_then(Value::as_str)
                .unwrap_or("匿名");
            let gift = data
                .get("giftName")
                .and_then(Value::as_str)
                .unwrap_or("礼物");
            let num = data.get("num").and_then(Value::as_u64).unwrap_or(1);
            let price = data.get("price").and_then(Value::as_u64).unwrap_or(0);
            let coin_type = data
                .get("coin_type")
                .and_then(Value::as_str)
                .unwrap_or("");
            let _ = tx.send(
                json!({
                    "type": "gift",
                    "user": user,
                    "gift": gift,
                    "num": num,
                    "price": price,
                    "coin_type": coin_type,
                })
                .to_string(),
            );
        }
        "SUPER_CHAT_MESSAGE" => {
            let user = data
                .get("user_info")
                .and_then(|value| value.get("uname"))
                .and_then(Value::as_str)
                .unwrap_or("匿名");
            let text = data.get("message").and_then(Value::as_str).unwrap_or("");
            let price = data.get("price").and_then(Value::as_u64).unwrap_or(0);
            let _ = tx.send(
                json!({
                    "type": "superchat",
                    "user": user,
                    "text": text,
                    "price": price,
                })
                .to_string(),
            );
        }
        "GUARD_BUY" => {
            let user = data
                .get("username")
                .and_then(Value::as_str)
                .unwrap_or("匿名");
            let gift = data
                .get("gift_name")
                .and_then(Value::as_str)
                .unwrap_or("舰长");
            let num = data.get("num").and_then(Value::as_u64).unwrap_or(1);
            let _ = tx.send(
                json!({
                    "type": "guard",
                    "user": user,
                    "gift": gift,
                    "num": num,
                })
                .to_string(),
            );
        }
        "INTERACT_WORD" => {
            let user = data
                .get("uname")
                .and_then(Value::as_str)
                .unwrap_or("观众");
            let msg_type = data.get("msg_type").and_then(Value::as_u64).unwrap_or(1);
            let text = match msg_type {
                2 => "关注了主播",
                3 => "分享了直播间",
                4 => "特别关注了主播",
                5 => "互相关注了",
                _ => "进入了直播间",
            };
            let _ = tx.send(
                json!({
                    "type": "enter",
                    "user": user,
                    "text": text,
                })
                .to_string(),
            );
        }
        "ONLINE_RANK_COUNT" => {
            let count = data
                .get("count")
                .and_then(Value::as_u64)
                .or_else(|| data.get("online_count").and_then(Value::as_u64))
                .unwrap_or(0);
            status.online = count;
            send_stats(status, tx);
        }
        "WATCHED_CHANGE" => {
            status.watched = data.get("num").and_then(Value::as_u64).unwrap_or(0);
            send_stats(status, tx);
        }
        "LIVE" => {
            let was_live = status.live;
            status.live = true;
            if live_since.is_none() {
                *live_since = Some(Instant::now());
            }
            if !was_live {
                let _ = tx.send(
                    json!({"type": "live", "live": true, "title": status.title}).to_string(),
                );
            }
        }
        "PREPARING" => {
            let was_live = status.live;
            status.live = false;
            status.uptime = 0;
            *live_since = None;
            if was_live {
                let _ = tx.send(
                    json!({"type": "live", "live": false, "title": status.title}).to_string(),
                );
                send_stats(status, tx);
            }
        }
        "ROOM_CHANGE" => {
            if let Some(title) = data.get("title").and_then(Value::as_str) {
                status.title = title.to_string();
                let _ = tx.send(
                    json!({
                        "type": "room",
                        "room_id": status.room_id,
                        "title": status.title,
                        "live": status.live,
                    })
                    .to_string(),
                );
            }
        }
        _ => debug!("忽略弹幕消息: {cmd}"),
    }
}

fn send_stats(status: &BridgeStatus, tx: &broadcast::Sender<String>) {
    let _ = tx.send(
        json!({
            "type": "stats",
            "online": status.online,
            "watched": status.watched,
            "uptime": status.uptime,
        })
        .to_string(),
    );
}

/* ---------------- 可选：MPRIS 当前播放 ---------------- */

fn spawn_now_playing(tx: broadcast::Sender<String>) {
    tokio::spawn(async move {
        let mut last = String::new();
        loop {
            let output = tokio::process::Command::new("playerctl")
                .args(["metadata", "--format", "{{artist}} - {{title}}"])
                .output()
                .await;

            if let Ok(output) = output {
                if output.status.success() {
                    let text = String::from_utf8_lossy(&output.stdout).trim().to_string();
                    let text = text.trim_matches('-').trim().to_string();
                    if !text.is_empty() && text != last {
                        last = text.clone();
                        let _ = tx.send(
                            json!({"type": "now_playing", "text": text}).to_string(),
                        );
                    }
                }
            }
            sleep(Duration::from_secs(4)).await;
        }
    });
}
