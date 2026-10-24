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
  systemd/            # systemd 用户服务单元（aria2 / wayvnc 等；ollama、openclaw-gateway 留在本机不入库，*.wants 链接不入库）
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
4. 按需启用用户服务：`systemctl --user daemon-reload && systemctl --user enable --now aria2.service wayvnc.service protonplus.timer`
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
