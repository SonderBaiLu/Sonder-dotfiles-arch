# Sonder-dotfiles-arch

Arch Linux dotfiles：Hyprland（原生 Lua 配置）+ Alacritty。

标准 stow 布局：仓库内 `.config/<应用>` 直接对应 `~/.config/<应用>`，由 `stow` 子命令创建符号链接。

## 仓库位置

建议放在 `~/Sonder-dotfiles-arch`（git 仓库）。符号链接指向该目录，移动仓库后重新跑一次 `stow` 即可。

## 一键部署

全新 Arch（或 EndeavourOS）上 clone 本仓库后，直接运行：

```bash
./bootstrap.sh
```

它会依次完成：检查并安装构建依赖（`base-devel` / `git` / `rust`）→ 编译 `sonder-installer` →
只读预检 → 完整部署（驱动 + 依赖 + 本地工具 + 符号链接 + 校验）→ 安装 hyprpm 插件（hypr-dynamic-cursors）→
写入 tty1 自动启动 Hyprland 的登录片段。

已有 rust 环境时也可以手动走原流程：

```bash
cd installer && cargo build --release
./installer/target/release/sonder-installer all      # 完整流程
./installer/target/release/sonder-installer --yes    # 非交互，失败直接跳过
```

### 子命令

| 命令          | 作用                                                            |
| ------------- | --------------------------------------------------------------- |
| `all`（默认） | deps + tools + stow + verify 完整流程                           |
| `deps`        | 仅驱动与软件依赖检测安装                                        |
| `tools`       | 构建 `tools/` 内的小工具并安装到 `~/.local/bin`，补 `input` 组  |
| `stow`        | 为 `.config/` 下每个目录创建 `~/.config` 符号链接               |
| `unstow`      | 移除指向本仓库的符号链接（指向外部的不动）                      |
| `verify`      | 仅语法与运行时校验                                              |
| `check`       | **只读预检**：不改动任何文件，提前发现正式运行会遇到的冲突/缺失 |

### 预检（check）

正式部署前先跑 `check`，把会报错的点提前暴露出来：

```bash
./installer/target/release/sonder-installer check
```

检查项：仓库结构、`~/.config` 每个目标条目的现状（符号链接指向哪 / 真实目录与仓库差异数 / 不存在）、依赖缺失、AUR 助手与 git、显卡驱动、Lua/Shell 语法、Hyprland 运行时 `configerrors`、sudo 凭据。

- 符号链接指向仓库**外部** → `[冲突]`，计为**错误**，退出码 `1`
- 真实目录与仓库有差异 / 依赖缺失 / 驱动缺失 → `[警告]`，退出码仍为 `0`（正式运行会自动处理）
- 无错误 → 退出码 `0`，提示"正式运行不会因冲突/缺失报错"

可用于脚本/CI 门禁：`check` 返回非 0 就阻止 `all`。

### 流程说明

1. **驱动检测**：`lspci` 识别显卡（NVIDIA / AMD / Intel），缺失驱动自动安装
2. **依赖检测**：检查 `DEPS` 清单，缺失则安装（官方仓库走 `sudo pacman`，AUR 包走 `paru`；无 paru 时自动从 AUR 构建安装）
3. **失败处理**：安装失败时提示 `R=重试 / S=跳过 / Q=退出`；跳过与失败项全部写入日志
4. **本地工具**：编译 `tools/rightclick` 并安装到 `~/.local/bin`；不在 `input` 组时自动加入（需重新登录生效）
5. **stow**：`.config/` 下每个目录 → `~/.config` 符号链接；目标是真实目录时先备份为 `<名字>.bak-<时间戳>` 再替换
6. **校验**：`luac -p` 检查 Lua、`bash -n` 检查脚本、`hyprctl reload config-only` + `configerrors` 检查运行时配置

`bootstrap.sh` 额外写入 `~/.bash_profile` 的登录片段（带 `>>> sonder-hyprland-autostart >>>` 标记）：
在 tty1 登录时自动 `exec start-hyprland`，其它 TTY 保留纯 shell 便于排障；删掉该段即可恢复手动启动。

日志位置：`~/.local/state/sonder-dotfiles/install.log`

退出码：`0` 全部成功；`2` 有失败/跳过项（详见日志）。

## 目录结构

```
bootstrap.sh          # 全新系统引导：装构建依赖 → 编译 → 部署 → 登录片段
.config/
  hypr/               # Hyprland 原生 Lua 配置（入口 hyprland.lua，模块在 lua/）
  alacritty/          # Alacritty 配置与主题
  wallust/            # 壁纸取色（wallust.toml + templates）
  noctalia/           # Noctalia 外壳调色板
  nvim/               # NvChad 配置
  fish/               # fish shell 配置
  fastfetch/          # fastfetch 配置与 logo
  fcitx5/             # 输入法配置（profile / config / conf，不含运行时缓存）
  environment.d/      # systemd 用户会话环境（输入法等变量）
  libreoffice/        # LibreOffice 用户配置（Catppuccin 调色板；registrymodifications 等运行时状态不入库）
  systemd/            # systemd 用户服务单元（aria2 / protonplus.timer 等；ollama、openclaw-gateway 留在本机不入库，*.wants 链接不入库）
  vlc/                # VLC 配置（含混合显卡 avcodec-hw=none 软解修复）
installer/            # Rust 部署工具（cargo build --release）
  src/
    main.rs           # 入口：参数解析 + 子命令分发
    state.rs          # 运行时状态、日志、命令执行、汇总
    util.rs           # 通用小工具（时间/PATH 查找/相对路径等）
    deps.rs           # 驱动与软件依赖检测安装（DEPS 清单在此）
    tools.rs          # 构建并安装 tools/ 内小工具
    stow.rs           # stow / unstow 符号链接管理
    verify.rs         # 语法与运行时校验
    preflight.rs      # check 只读预检
tools/
  rightclick/         # 连点器（binds.lua 调用 ~/.local/bin/rightclick）
system/
  grub-catppuccin/    # GRUB Catppuccin Frappé 主题（sudo bash system/grub-catppuccin/install.sh 安装，--revert 回滚）
```

## 重装系统后的还原步骤

1. `git clone git@github.com:SonderBaiLu/Sonder-dotfiles-arch.git ~/Sonder-dotfiles-arch`
2. `cd ~/Sonder-dotfiles-arch && ./bootstrap.sh`
3. 可选：`sudo bash system/grub-catppuccin/install.sh` 应用 GRUB 主题（`--revert` 回滚）
4. 按需启用用户服务：`systemctl --user daemon-reload && systemctl --user enable --now aria2.service protonplus.timer`
5. 重建 `~/.config/fish/secrets.fish`（模板见 `secrets.fish.example`，未入库）
6. 重新登录（`input` 组生效），从 tty1 登录即自动进入 Hyprland

仓库外的内容需要自行恢复：`/etc/fstab`（btrfs 子卷、`/mnt/数据`、NFS）、额外用户组、
`~/.config/fish/secrets.fish`、壁纸（`~/Pictures/wallpapers`）。

## 维护提示

- 新增应用配置：把 `~/.config/<应用>` 放进仓库 `.config/`，跑 `stow` 即生效
- 修改依赖清单：`installer/src/deps.rs` 顶部的 `DEPS` 数组（`包名, 是否AUR`）
- 修改 Hyprland 配置后用 `hyprctl reload config-only` 生效，`hyprctl configerrors` 检查错误
- Hyprland 升级后跑 `hyprpm update` 按新版本重建插件，重启 Hyprland 生效
- LibreOffice 主题调色板在 `.config/libreoffice/4/user/config/`，新环境部署后在颜色选择器的调色板里重新选一次
- 校验语法：`luac -p hyprland.lua`（Lua）、`bash -n scripts/xxx.sh`（shell）

## 注意

- 仓库历史中曾提交过 `.webui_secret_key`（明文 token），如仍在服务端使用请立即撤销/轮换。

---

# 项目架构与修改指南（详解）

> 本章节面向"以后要改东西的时候"：先讲清楚整体架构和数据流向，再按「我想改 X → 动哪个文件 → 怎么验证」逐条给出操作步骤。所有路径均相对仓库根 `~/Sonder-dotfiles-arch`。

## A. 整体架构

### A.1 一图看懂：仓库 → 家目录 → 运行时

```
┌─────────────────────────────────────────────────────────────┐
│ ~/Sonder-dotfiles-arch（git 仓库 = 唯一事实源）               │
│                                                             │
│  bootstrap.sh             全新系统引导入口（bash）           │
│  .config/                 12 个 stow 包 + 2 个单文件         │
│  installer/               Rust 部署器 sonder-installer      │
│  tools/rightclick/        本地 Rust 小工具（连点器）         │
│  system/grub-catppuccin/  GRUB 主题（需 sudo 安装到 /boot）  │
└──────────────┬──────────────────────────────────────────────┘
               │ 符号链接：~/.config/<应用> → ../Sonder-dotfiles-arch/.config/<应用>
               ▼
┌─────────────────────────────────────────────────────────────┐
│ ~/.config/<应用>                                            │
│   改仓库里的文件 = 直接改了本机配置，不存在"复制"这一步       │
└──────────────┬──────────────────────────────────────────────┘
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 运行时                                                      │
│  tty1 登录 → ~/.bash_profile 自动片段 → start-hyprland      │
│  （start-hyprland 是 hyprland 包自带的启动器，非仓库内容）    │
│  Hyprland（原生 Lua 配置）+ Noctalia 外壳 + systemd 用户服务  │
└─────────────────────────────────────────────────────────────┘
```

**核心心智模型**：本机所有配置都活在仓库里。家目录里看到的是符号链接；改配置就是改仓库文件，改完跑对应验证命令即可生效；git 负责记忆一切。

### A.2 `.config/` 各 stow 包一览

| 包 | 作用 | 关键文件 | 生效方式 |
| --- | --- | --- | --- |
| `hypr/` | **核心**：Hyprland 原生 Lua 配置 | `hyprland.lua` + `lua/*.lua` + `scripts/` | `hyprctl reload config-only` |
| `alacritty/` | 终端配置与主题 | `alacritty.toml` + `themes/` | 重开终端 |
| `fish/` | fish shell（fisher 插件、tide 提示符、ai 函数） | `config.fish`、`fish_plugins`、`functions/ai*.fish` | 新开 shell；插件变更跑 `fisher update` |
| `fcitx5/` | 输入法（profile/config/conf） | `profile`（输入法组） | `fcitx5 -r` 重启输入法 |
| `environment.d/` | systemd 用户会话环境变量（输入法） | `im.conf` | 重新登录（systemd 用户管理器重建环境） |
| `noctalia/` | Noctalia 外壳的调色/状态栏覆盖 | `bar.toml`、`palettes/sllh-mc.json` | noctalia 热重载（自动） |
| `wallust/` | 壁纸取色配置与模板 | `wallust.toml`、`templates/` | 下次换壁纸时经 `WallustAwww.sh` 生效 |
| `nvim/` | NvChad 定制版 | `lua/` | 重开 nvim |
| `fastfetch/` | 终端系统信息展示 | config + logo | 下次运行 |
| `libreoffice/` | 仅跟踪 `4/user/config/`（Catppuccin 调色板） | `catppuccin-frappe-blue.soc` | 重开 LibreOffice；调色板在颜色选择器里重选一次 |
| `systemd/` | 用户服务单元（仅 `aria2`、`protonplus.service/.timer`） | `user/*.service|*.timer` | `systemctl --user daemon-reload` |
| `vlc/` | VLC 配置（含混合显卡 `avcodec-hw=none` 修复） | `vlcrc` | 重开 VLC |
| `user-dirs.dirs` / `.locale` | 英文 XDG 目录名 | — | `xdg-user-dirs-update` |

**刻意不入库的**：`systemd/user/ollama.service`、`openclaw-gateway.service`（个人服务，文件只留在本机，见 `.gitignore`）；`libreoffice` 的 `registrymodifications.xcu`、`vlc` 的 `vlc-qt-interface.conf`、所有 `*.wants/` 链接目录（运行时状态）。

### A.3 `.config/hypr/` 内部（改动最频繁，重点展开）

`hyprland.lua` 是入口，**模块按顺序加载**，顺序有意义（后面的可引用前面的常量）：

```
hyprland.lua
  ├─ require("lua.defaults")      # 常量：终端/编辑器/文件管理器/脚本目录、显示器布局、触摸板设备
  ├─ require("lua.environment")   # 环境变量清单（输入法 / NVIDIA / Wayland / GSYNC）
  ├─ require("lua.layout")        # 布局（Dwindle）、输入、手势、渲染、光标
  ├─ require("lua.appearance")    # 主题色（写死 Noctalia 静态色板值）、边框、阴影、模糊
  ├─ require("lua.rules")         # 窗口规则：先打 tag 归类，再按 tag/class 施加浮动/透明/尺寸
  ├─ require("lua.behavior")      # urgent 钩子：任务栏点 QQ → 窗口拉到眼前
  ├─ require("lua.binds")         # 全部快捷键
  ├─ require("lua.plugins")       # hyprpm 权限放行 + hypr-dynamic-cursors 参数
  ├─ require("lua.startup")       # 启动项（见 A.5）
  ├─ require("noctalia").apply_theme()   # Noctalia 主题注入
  └─ pcall(dofile ~/.cache/noctalia/HVE/overlay.lua)  # HVE 可视化编辑器覆盖层（无则跳过）
```

其余成员：

- `lua/animations/`：**五套动画方案**（`bounce` / `drop` / `flow` / `snap` / `veil`），`init.lua` 在登录和每次 reload 时**随机选一套**。
- `scripts/`：被快捷键调用的辅助脚本（壁纸取色 `WallustAwww.sh`、夜间模式 `Hyprsunset.sh`、截屏 `ScreenShot.sh`、亮度/音量/媒体控制、游戏模式、概览切换、触摸板开关等约 20 个）。
- `hypridle.conf`：空闲管理，触发 noctalia 锁屏（`noctalia msg session lock`）/ 休眠 / 关屏。
- `initial-boot.sh`：首次进系统的一次性精装（壁纸、配色、深色模式），跑完留 `.initial_startup_done` 标记（已 gitignore）。
- `wallust/`：wallust 渲染产物目录（生成物，不手工编辑）。

### A.4 `installer/`（Rust 部署器 `sonder-installer`）

| 文件 | 职责 |
| --- | --- |
| `main.rs` | 参数解析 + 子命令分发：`all`（默认）/ `deps` / `tools` / `stow` / `unstow` / `verify` / `check` |
| `deps.rs` | **`DEPS` 清单在此**（格式 `("包名", 是否AUR)`）+ 显卡驱动自动检测（NVIDIA/AMD/Intel）+ paru 自举 |
| `tools.rs` | 编译 `tools/` 内小工具装到 `~/.local/bin`，补 `input` 组 |
| `stow.rs` | 为 `.config/` 下每个条目（目录或单文件，跳过 `.` 开头）建符号链接；目标已是真实目录则先备份为 `<名>.bak-<时间戳>` |
| `verify.rs` | `luac -p` 校验 Lua、`bash -n` 校验脚本、`hyprctl reload config-only` + `configerrors` 运行时校验 |
| `preflight.rs` | `check` 只读预检（CI 门禁用，非 0 阻断 `all`） |
| `state.rs` / `util.rs` | 运行状态、日志（`~/.local/state/sonder-dotfiles/install.log`）、通用小工具 |

退出码：`0` 全成功；`2` 有失败/跳过项（查日志）。

### A.5 一次开机到底发生了什么（按时间顺序）

1. **tty1 登录** → `~/.bash_profile` 里的 `>>> sonder-hyprland-autostart >>>` 片段在 tty1 上 `exec start-hyprland`（hyprland 包自带二进制，读取 `hyprland.lua`）。
2. **Lua 模块加载**（A.3 顺序）——只注册配置，不阻塞。
3. **`startup.lua` 派发启动项**（`hyprland.start` 回调内逐个 exec，不阻塞合成器）：
   `hyprpm reload && hyprctl reload config-only`（加载插件）→ `awww-daemon`（壁纸守护）→ `dbus-update-activation-environment` + `systemctl --user import-environment`（同步会话环境给 systemd 服务）→ `hypridle`（空闲管理）→ `noctalia`（外壳：状态栏/启动器/控制中心/通知/Polkit/锁屏）→ `fcitx5` → `wl-paste | cliphist`（文本+图片剪贴板历史）。
4. **换壁纸时**：noctalia 壁纸模块调 `awww` → `scripts/WallustAwww.sh` → `wallust` 从壁纸取色（kmeans / labmixed / dark16）→ 渲染两个模板：`colors-hyprland.conf → ~/.config/hypr/wallust/wallust-hyprland.conf`、`qml_color.json → ~/.config/quickshell/qml_color.json`（Noctalia 面板取色）。
   ⚠️ `appearance.lua` 里的 Hyprland 主题色是**写死的 Noctalia 静态色板值**——因为 wallust 动态色会被 noctalia 覆盖，写死避免"先上色再被覆盖"的闪烁。想全局换主题色看 §C.8。
5. **systemd 用户服务**（仓库跟踪：`aria2`、`protonplus.timer`；本机独有：`ollama`、`openclaw-gateway`）随 `default.target` 起。普通 GUI 程序的环境变量来自 `lua/environment.lua`；systemd/D-Bus 激活的程序（portal 弹窗等）来自 `environment.d/im.conf`——**两处必须保持一致**。

### A.6 GRUB 主题（`system/grub-catppuccin/`）

`install.sh`（root）：备份 `/etc/default/grub` → 复制主题到 `/boot/grub/themes/catppuccin-frappe-eos/` → 写入 `GRUB_THEME` / `GRUB_GFXMODE`、禁用 EndeavourOS 的 `GRUB_BACKGROUND` → `grub-mkconfig`。`--revert` 用最近一份 `.bak` 还原。主题素材（背景/字体/图标）都在仓库内，改外观直接改 `catppuccin-frappe-eos/theme.txt` 与图片。

## B. 项目走向（Roadmap）

### 已完成（截至 2026-10-25）
裸机一键恢复主体（bootstrap → installer all）、全部核心配置 stow 化、Hyprland 迁移到原生 Lua、壁纸栈 swww→awww、锁屏/通知/Polkit 归 noctalia、NvChad 收编、输入法双通道（environment.lua + environment.d）、LibreOffice/VLC/systemd 单元/GRUB 主题入库、hyprpm 插件（dynamic-cursors）接入与部署自动化。

### 近期待办 / 待决策
1. **推送远端**：本阶段改动还在本地（`git status -sb` 看 ahead 数），确认后 `git push`。
2. **卸载 wayvnc 包**：`sudo pacman -Rns wayvnc`（服务/单元/配置已清，只差包）。
3. **`~/.config/autostart/` 的 .desktop 收编决策**：Clash Verge / FlClash / jetbrains-toolbox / todesk / 百度网盘——装哪些、走哪个代理是用户决策，定了之后可入库。
4. **gtk-3.0 / gtk-4.0 `settings.ini`**：目前靠 nwg-look 现场重设；若想一键恢复外观可收编（noctalia 生成的 `gtk.css`/`noctalia.css` 不收）。
5. **`.config/yazi/` 存废**：包已弃用但配置还在仓库，确认彻底不要后 `git rm -r`。
6. **HVE 可视化编辑器**：bar.toml 入口已加、overlay 挂载点已备，是否启用待用户定（见记忆/速查）。

### 长期关注
- **Hyprland 0.57**：传统 `.conf` 将被移除——本仓库已是纯 Lua 原生配置，无迁移负担；关注上游 Lua API 变更即可。
- **Hyprland 升级后**：`hyprpm update` 按新版本重建插件，再重启 Hyprland。
- **仓库外还原项**（重装时手动）：`/etc/fstab`（btrfs 子卷、`/mnt/数据`、NFS）、额外用户组、`~/.config/fish/secrets.fish`、fcitx5 rime 词库（`~/.local/share/fcitx5/rime`）、壁纸（`~/Pictures/wallpapers`）、`ollama`/`openclaw-gateway` 单元。

### 长期原则（历史约定，动仓库前默念）
- **不留死软件痕迹**：卸载某软件时，包、配置、绑定、注释、文件名一起清干净。
- **桌面服务归 noctalia 一家**：与 noctalia 功能重叠的包（启动器/通知/锁屏/Polkit）不加回。
- **面向用户的脚本提示一律中文**；通知图标用 freedesktop 标准名（Papirus 里 find 验证过再用）。
- **安装/卸载类命令写给用户自己跑**，agent 不碰 sudo。
- **敏感文件永不入库**：`secrets*`、`*.token`、`*.pem`、密码类配置（如原 wayvnc config）。

## C. 修改指南（我想改 X）

> 每条 = 改哪里 → 怎么改 → 怎么验证。改完的通用验证见 §C.17。

### C.1 加 / 改快捷键
1. 打开 `.config/hypr/lua/binds.lua`，照已有格式加一行：
   `hl.bind(MOD .. " + X", hl.dsp.exec_cmd("命令"), { description = "中文描述" })`
2. 组合键写法：`MOD`（SUPER）、`CTRL + SHIFT + Escape` 等；调脚本用 `M.scripts .. "/xxx.sh"`。
3. 验证：`hyprctl reload config-only && hyprctl configerrors`。

### C.2 加窗口规则
1. 打开 `.config/hypr/lua/rules.lua`。
2. 同类应用先加 `tag` 规则，再按 tag 施加 float/center/size/opacity 等；静态效果只在窗口创建时评估一次。
3. 验证：开目标应用 + `hyprctl configerrors`。

### C.3 换 / 改动画
1. 五套方案在 `.config/hypr/lua/animations/`（bounce/drop/flow/snap/veil），`init.lua` 每次登录和 reload 随机选一套。
2. 想固定某套：改 `animations/init.lua` 的选择逻辑；想调曲线：改对应方案文件。
3. 验证：`hyprctl reload config-only` 后拖动窗口看效果。

### C.4 改环境变量
1. 普通 GUI 程序：`.config/hypr/lua/environment.lua` 的 `vars` 表。
2. systemd/D-Bus 激活的程序（portal 文件弹窗等）：`.config/environment.d/im.conf`。
3. ⚠️ 输入法三件套（`GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS`）**两处都要改、保持一致**。
4. 验证：Hyprland 重启后 `hyprctl getoption` 或直接在应用里试。

### C.5 加自启动项
1. 打开 `.config/hypr/lua/startup.lua`，在 `hl.on("hyprland.start", ...)` 回调里加 `hl.exec_cmd("命令")`。
2. 只做一次性派发，不要写阻塞命令。
3. 验证：重启 Hyprland 后 `pgrep 进程名`。

### C.6 Hyprland 插件
- 配置参数：改 `.config/hypr/lua/plugins.lua`（当前 hypr-dynamic-cursors：tilt + shake）。
- 换插件源/新插件：`hyprpm add <仓库URL>` 后在此文件加对应配置块。
- **Hyprland 版本升级后**：`hyprpm update` 重建，再重启 Hyprland；bootstrap.sh 会自动装插件但不会自动 update。

### C.7 换显示器 / 触摸板
改 `.config/hypr/lua/defaults.lua`（显示器布局常量与设备名集中在那里），验证 `hyprctl monitors`。

### C.8 全局换主题色
1. Hyprland 侧：`.config/hypr/lua/appearance.lua`（主题色写死于此，注释说明了原因）。
2. Noctalia 侧：`.config/noctalia/palettes/sllh-mc.json` + noctalia 自身设置。
3. 壁纸动态取色规则：`.config/wallust/wallust.toml`（backend/color_space/palette 三参数）与 `templates/`。
4. 验证：`hyprctl reload config-only`，noctalia 自动热重载。

### C.9 Noctalia 状态栏
改 `.config/noctalia/bar.toml`（当前两端共 6 个 sysmon + 歌词 + HVE 入口）。noctalia 热重载；若没生效检查 noctalia 是否有 state 层覆盖（state 层优先于手写层）。

### C.10 fish
- 加函数：`.config/fish/functions/<名>.fish`（参考 `ai.fish`，`function --description` 用中文）。
- 加/删插件：改 `fish_plugins` 后 `fisher update`。
- 提示符：tide（`fish_variables` 存配置）；主题：catppuccin。

### C.11 alacritty
改 `.config/alacritty/alacritty.toml`；主题在 `themes/` 下切换。重开终端生效。

### C.12 新应用的配置入库（标准流程）
1. `mv ~/.config/<app> /home/qicat/Sonder-dotfiles-arch/.config/<app>`
2. `ln -s ../Sonder-dotfiles-arch/.config/<app> ~/.config/<app>`（相对链接，与现有条目一致）
3. 决定 gitignore 策略：有运行时状态/缓存/密码 → 在 `.gitignore` 写白名单或排除项（参考 libreoffice/systemd/vlc 的写法）。
4. 需要装包的话在 `installer/src/deps.rs` 的 `DEPS` 加 `("包名", 是否AUR)`。
5. `cd installer && cargo check`（改了 deps.rs 就必须跑）。
6. `git add .config/<app> ... && git commit`（中文 conventional message，一个主题一个提交）。

### C.13 往 DEPS 加包 / 改安装器
- 加包：`deps.rs` 顶部 `DEPS` 数组，格式 `("包名", false)`（官方仓库）或 `("包名", true)`（AUR，走 paru）。
- 改安装器逻辑：按 §A.4 表找对应文件；改完 `cd installer && cargo check`，重部署前先跑 `sonder-installer check` 只读预检。

### C.14 GRUB 主题
改 `system/grub-catppuccin/catppuccin-frappe-eos/` 下的 `theme.txt` 与图片，然后 `sudo bash system/grub-catppuccin/install.sh` 重新安装（会覆盖 `/boot` 旧主题），`--revert` 回滚。

### C.15 systemd 用户服务
- 入库的（aria2 / protonplus）：直接改仓库 `systemd/user/*.service`，改完 `systemctl --user daemon-reload`。
- 新增要入库的服务：单元文件放进 `systemd/user/` + `systemctl --user enable --now <名>` + README §还原步骤的启用命令同步 + 提交。
- 个人服务不入库：写进 `.gitignore`（参考 ollama/openclaw-gateway 两条）。

### C.16 LibreOffice 主题
调色板文件在 `.config/libreoffice/4/user/config/*.soc`，直接改或新增；`registrymodifications.xcu` 是运行时状态不要手工编辑也不要入库。新环境部署后到颜色选择器里重选一次。

### C.17 通用验证清单（改完任何东西过一遍）
```bash
cd ~/Sonder-dotfiles-arch
luac -p .config/hypr/hyprland.lua        # Lua 语法
bash -n .config/hypr/scripts/xxx.sh      # 改过的脚本
(cd installer && cargo check)            # 动过 deps.rs / 安装器
hyprctl reload config-only && hyprctl configerrors   # 动过 hypr 配置（本机）
git status                               # 确认没有把运行时垃圾带进来
```
提交规范：中文 conventional commits（`feat:` / `fix:` / `chore:` / `docs:` / `refactor:`），一个主题一个提交；改完 README 相关小节要同步。

