# OBS 直播覆盖层（Minecraft 混合风格）

一个给 OBS 浏览器源用的 **2560×1440** 覆盖层：像素中文、暗黑霓虹游戏框、B 站实时弹幕、最近获得、物品栏和状态栏。聊天由本地 Rust 桥接直接连 B 站，不经过第三方云服务。

![预览](preview.png)

## 组成

| 路径 | 作用 |
| --- | --- |
| `web/` | 覆盖层 HTML / CSS / JS、像素图标、Fusion Pixel 字体 |
| `src/main.rs` | B 站弹幕桥接 + 本地 HTTP / WebSocket 服务 |
| `config.toml` | 本地配置（已 gitignore），填直播间房号 |
| `config.example.toml` | 配置模板 |
| `systemd/obs-overlay-bridge.service` | 用户级 systemd 单元 |
| `preview.png` | 演示模式截图 |

## 快速开始

```bash
cd ~/Sonder-dotfiles-arch/tools/obs-overlay
cp config.example.toml config.toml
$EDITOR config.toml          # 填 room_id
cargo build --release
./target/release/obs-overlay-bridge
```

打开 <http://127.0.0.1:9100/?demo=1&preview=1> 可以先看演示效果：

- `demo=1`：循环假弹幕/礼物/SC，方便调视觉
- `preview=1`：给游戏洞加一个深色占位背景；OBS 里不要带这两个参数

OBS 浏览器源只填：

```text
http://127.0.0.1:9100/
```

## OBS 接入

1. 场景里先放 **游戏画面**：推荐“窗口采集 (PipeWire)”选 Minecraft 窗口，不要用整屏采集，否则桌面上的聊天窗口/浏览器也会被录进去。
2. 游戏画面放在覆盖层**下面**，位置和尺寸对齐游戏洞：

   ```text
   X = 48, Y = 196
   宽 = 1680, 高 = 945
   ```

   这是 16:9 区域；窗口采集后用“缩放/裁剪”填满即可。
3. 新增“浏览器”源，URL 填 `http://127.0.0.1:9100/`，宽高 **2560×1440**，放在最上层。
   - 自定义帧率：**90**
   - 不要勾“通过 OBS 控制音频”
   - 透明背景由页面自身处理，不需要额外设置
4. 音频照旧：桌面音频 + 麦克风。

> 覆盖层是 2560×1440 设计的；如果 OBS 画布是 1920×1080，页面会等比缩放，但建议直接用 2560×1440 录制/直播。

## 自定义

- `web/config.js`：标题、副标题、房间号显示、BGM 占位、物品栏 9 格、最近获得列表。
- `web/style.css`：颜色、尺寸、边框。主要变量在 `:root`，例如 `--accent`（草绿）、`--gold`、`--red`。
- 字体是 [Fusion Pixel](https://github.com/TakWolf/fusion-pixel-font) 12px，OFL 许可，许可证在 `web/fonts/OFL.txt`。
- 底部 HUD 目前是**装饰性**的；要接真实背包/坐标/成就，需要在桥接里加数据源（mod、RCON 或日志解析），前端事件接口已经留好：`recent_item`、`stats`。
- BGM：桥接每 4 秒调用一次 `playerctl metadata --format '{{artist}} - {{title}}'`；装了 `playerctl` 且有播放器就会自动更新，否则显示 `config.js` 里的 `bgm`。

## B 站弹幕桥接

- 使用 `getDanmuInfo` 的 `w_rid` 签名 + `buvid3/buvid4` Cookie，匿名连接，不需要登录。
- 支持：普通弹幕、礼物、SC、上舰、进场（JSON 版 `INTERACT_WORD`）。
- `INTERACT_WORD_V2` 是 protobuf 消息，当前忽略；不影响弹幕/礼物。
- 房间离线时桥接仍保持连接，开播后自动变 LIVE；`/api/status` 可以直接看状态。
- 如果 B 站以后改协议，可以换用 [blivechat](https://github.com/xfgryujk/blivechat)（或 [DoodleBears 改版](https://github.com/DoodleBears/blivechat)）作为备用后端；本覆盖层的 `/ws` 事件格式很简单，写个适配器即可。

`config.toml` 已经在 `.gitignore` 里，不会把房号提交进仓库；模板是 `config.example.toml`。

## systemd（可选）

```bash
mkdir -p ~/.config/systemd/user
cp systemd/obs-overlay-bridge.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now obs-overlay-bridge.service
systemctl --user status obs-overlay-bridge.service
journalctl --user -u obs-overlay-bridge.service -f
```

## 录制 2K 90fps 的配套设置

这部分和覆盖层无关，但和“录制时卡顿”直接相关：

- OBS 输出：`2560×1440`，`90 FPS`，基础/输出分辨率一致，不要缩到 1080p。
- 编码器：**NVIDIA NVENC HEVC**，Rate Control **CQP**，CQ **20**，Preset **P5**，Multipass **qres**，Look-ahead **关**，B-frames **2**，Adaptive Quantization **开**。
- 分段：按大小 **8 GB**。实际码率大约 30–80 Mbps，8 GB 约 14–36 分钟一段；234 GB 可用空间大约能录 6–13 小时。
- OBS 必须用 **4070** 启动：桌面入口已经设置 `__EGL_VENDOR_LIBRARY_FILENAMES` 指向 NVIDIA EGL；从 Noctalia 的 OBS Control 按钮启动也已加同样环境变量。否则 OBS 会回到 610M 核显，NVENC 走非纹理回退，1440p90 会明显卡。
- Noctalia 的 `obs-control` 是社区插件；更新插件可能覆盖本地补丁（强制 NVIDIA EGL、容忍 replay/virtualcam 未启用）。如果状态栏启动 OBS 又回到核显，把这三行环境变量补回 `launch()` 即可。
- Minecraft 侧：`maxFps:90`、`enableVsync:false`。160Hz 屏上 100fps + VSync 会产生 1.6 倍刷新节奏，录制出来会一顿一顿。
- 如果还卡：游戏改窗口化/无边框，采集用窗口采集；必要时临时把 `misc:vrr` 设为 0 测试。

## 排障

```bash
ss -tlnp | grep 9100
curl http://127.0.0.1:9100/api/status
journalctl --user -u obs-overlay-bridge.service -f
```

- 浏览器源空白：确认桥接在跑、URL 没有 `?demo`/`?preview`、尺寸是 2560×1440。
- 弹幕不显示：先看 `/api/status` 的 `connected` / `live`；房间没开播时聊天区会是空的，这是正常的。
- 端口被占：改 `config.toml` 的 `port`，同时改 OBS 浏览器源 URL 和 systemd 不变（端口在 config 里）。
