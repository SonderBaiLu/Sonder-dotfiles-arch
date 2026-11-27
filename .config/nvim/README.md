# Sonder Neovim

基于 SonderBaiLu 的 Arch 配置，保留空格前缀、Mocha 配色、Blink 补全和手动格式化。打开编辑器后，依次按 **空格、问号**，输入“格式化”“定义”等中文即可查找当前缓冲区可用的快捷键。停在空格前缀上还会出现分组提示。[上游配置与基准版本](https://github.com/SonderBaiLu/Sonder-dotfiles-arch/tree/409f952524bb64088570920a28cd9fe910eba673/.config/nvim)

## 安装

使用 **Neovim 0.12.x**、Git、Node.js 22 LTS 或更新的受支持版本、npm、ripgrep、curl 和 tar。Mason 下载部分工具还需要解压程序，Linux 建议备好 unzip、gzip；Windows 可使用 PowerShell。Tree-sitter 需要 C 编译器和 tree-sitter CLI 0.26.1 或更高版本，CLI 已列入 Mason 安装清单。[Neovim 发行包](https://github.com/neovim/neovim/releases/tag/v0.12.6) · [Tree-sitter 的安装要求](https://github.com/nvim-treesitter/nvim-treesitter#requirements)

- **Windows** 可在 PATH 中使用 WinLibs / MinGW-w64 的 gcc，也可以从带 cl 的 Visual Studio 开发者终端运行。用 `Get-Command nvim,git,node,npm.cmd,rg` 检查当前终端。
- **Linux** 可使用发行版提供的 gcc 或 clang。Arch 可用 pacman 安装 neovim、git、nodejs、npm、ripgrep、base-devel、curl、tar、gzip、unzip。其他发行版请先用 `nvim --version` 核对版本；需要时使用上方的官方构建。桌面环境如需共享剪贴板，Wayland 可安装 wl-clipboard，X11 可使用 xclip 或 xsel。
- **Rust** 使用项目当前的 rustup 工具链。在 Rust 工程目录运行 `rustup component add rust-analyzer rustfmt rust-src`，分别提供语言服务、格式化与标准库源码。

解压配置包。将整个 `nvim` 目录放在 Neovim 的配置位置，确保 `init.lua` 位于该位置的第一层。Windows 默认是 `%LOCALAPPDATA%\nvim`，Linux 默认是 `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`。已有配置先改名备份。使用 NVIM_APPNAME 或自定义 XDG 变量时，可通过 `nvim --clean --headless "+lua print(vim.fn.stdpath('config'))" +qa` 获取准确目录。

首次启动 `nvim` 会按 `lazy-lock.json` 安装插件。需要联网访问 GitHub、Mason 注册表和 npm。待插件就绪，在编辑器依次执行以下命令。第一步等待外部工具全部下载，第二步等待语法解析器编译完成。

```vim
:MasonToolsInstallSync
:SonderParsers!
:checkhealth sonder
```

重新打开已打开的文件即可加载新解析器。以后可用 `:Mason` 查看外部工具，用 `:ConformInfo` 查看当前文件的格式化器，用 `:checkhealth vim.lsp` 查看当前客户端。升级插件可用 `:Lazy update`，随后执行 `:TSUpdate` 同步解析器。恢复交付时的插件版本可从配置包还原锁文件后执行 `:Lazy restore`。

## 语言与写作

| 文件 | 语言服务 | 格式化与编辑 |
| --- | --- | --- |
| Rust | rust-analyzer | rustfmt 读取项目 edition，支持 Cargo 工作区 |
| Vue 3 | vue_ls + vtsls | 模板与 TS 脚本联动，Prettier 整体排版，成对标签同步修改 |
| JS / JSX / TS / TSX | vtsls | 成员补全、定义跳转、Prettier |
| HTML / CSS | html / cssls | 标签与属性补全、颜色预览、Prettier |
| Markdown | Marksman | 标题和链接导航、Prettier、软换行，j/k 按显示行移动 |
| JSON / JSONC | jsonls | schema 补全与校验，Prettier 保留 JSONC 注释 |
| TOML | Taplo | 语法诊断、schema 与 Taplo 排版 |
| YAML | yamlls | YAML 结构与 schema 支持、Prettier |
| POSIX Shell / Bash | bashls + ShellCheck | ShellCheck 诊断、shfmt 排版 |
| Lua | lua_ls | 编辑本配置时识别 Neovim API，StyLua 排版 |

Vue 项目应包含 `package.json` 和适用的 `tsconfig.json`，并安装项目声明的依赖。Markdown 工作区可由 Git 根目录或 `.marksman.toml` 标记。Prettier 优先使用项目安装的版本并遵循项目规则。默认保存保留原排版，`空格 t f` 只切换当前文件的保存格式化。

HTML 支持额外的严格校验。项目可通过 `npm install -D html-validate` 使用自己的规则与版本，也可以用下方对应平台的命令将工具安装到 Neovim 专用目录。本次 Windows 部署已安装此工具。

```powershell
# Windows 默认数据目录；工具仅供本套编辑器使用。
npm.cmd install --prefix "$env:LOCALAPPDATA/nvim-data/sonder-tools" html-validate@9
```

```sh
# Linux 默认数据目录，兼容用户设置的 XDG_DATA_HOME。
npm install --prefix "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/sonder-tools" html-validate@9
```

## 中英文输入法切换

编辑器按光标上下文自动切换输入法：代码用英文，注释和 Markdown/纯文本用中文，字符串保持英文。进入插入模式时判断一次；在空行打出 `//`、`#`、`--`、`/*`、`<!--` 等注释符后立即切中文；回车到新的代码行或离开插入模式时切回英文。手动用 Shift/Ctrl+Space 切走的输入法不会被反复抢回，可用 `:SonderIME` 查看当前状态，`:SonderIME off` / `on` 临时关闭或开启。只在能拿到终端窗口的会话里生效，远程 SSH 无法切换本机输入法。

Windows 需要系统里同时有中文（微软拼音）与英文（美式键盘）布局，并准备 `im-select.exe`。下载 64 位版本到 Neovim 专用工具目录（配置会自动识别，也可以放入 PATH）：

```powershell
New-Item -ItemType Directory -Force "$env:LOCALAPPDATA/nvim-data/sonder-tools" | Out-Null
curl.exe -L -o "$env:LOCALAPPDATA/nvim-data/sonder-tools/im-select.exe" https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe
```

切换的是窗口键盘布局；如果微软拼音停在内部「英文模式」，切到中文后再按一次 Shift 即可。中文布局 ID 默认 `2052`，需要时可设 `SONDER_IME_ZH`。

Linux 使用 fcitx5，`fcitx5-remote` 随 fcitx5 提供；中文输入法名默认 `rime`：

```sh
sudo pacman -S --needed fcitx5 fcitx5-im
fcitx5-remote -n   # 在中文模式下确认输出为 rime
```

使用 ibus 时自动改用 `ibus engine`（英文 `xkb:us::eng`，中文默认 `libpinyin`）。Linux 上如果 Rime 停在 ASCII 模式，切到中文后按一次 Shift。`SONDER_IME_ZH` 可覆盖中文输入法名，`SONDER_IME=0` 可整体关闭。

输入法组词时会先消费 Esc：组词状态下第一次 Esc 只取消候选，`jk` 也会被当作拼音输入，不会退出插入模式；再按一次 Esc 即可。

## 常用键位

| 按键 | 操作 |
| --- | --- |
| 空格 ? / 空格 f k | 搜索当前快捷键，Esc 返回编辑器 |
| 空格 z a / 空格 z c / 空格 z o | 切换 / 折叠 / 展开光标所在的代码块 |
| 空格 z M / 空格 z R | 折叠 / 展开当前窗口里的全部代码块（M、R 为大写） |
| 空格 e / 空格 f f / 空格 f g | 文件树 / 项目文件 / 项目全文搜索 |
| 空格 f b / 空格 f o / 空格 f r | 缓冲区 / 最近文件 / 上次搜索 |
| gd / gr / K | 定义 / 引用 / 悬浮文档 |
| 空格 r n / 空格 c a / 空格 d f | 重命名 / 代码操作 / 当前诊断 |
| Ctrl+Space / Ctrl+j、Ctrl+k / Enter | 插入模式呼出补全 / 选择候选 / 接受选中项 |
| Tab / Shift+Tab | 跳转片段占位符，也可在候选间移动 |
| 空格 f m / 空格 t f | 格式化当前文件 / 切换保存格式化 |
| 空格 t g | 切换编辑区实色与终端底色 |
| 空格 w / 空格 u | 保存 / 查看撤销历史树 |
| 空格 g g / 空格 h p | Git 面板 / 预览光标处改动块 |
| 空格 p o / 空格 p c | HTML 项目本机预览 / 关闭预览 |

## Mocha 实色窗口

专属窗口在 Windows 与 Arch 共用 **JetBrainsMono Nerd Font Mono**，字号 12 pt。文件树按扩展名显示图标，补全列表用图标区分方法、变量等候选类型。其他终端中直接运行 `nvim` 时，在该终端的字体设置选同一字体。临时使用普通字体时，设 `SONDER_NERD_FONT=0` 后重新启动。编辑区默认使用 Mocha 实色，文件树略深，浮窗略亮。环境变量 `SONDER_GLASS=1` 可让编辑区沿用终端底色，终端窗口本身的不透明度由 Alacritty 控制。

Arch 可运行 `sudo pacman -Syu --needed ttf-jetbrains-mono-nerd alacritty` 安装字体和终端。`fc-match "JetBrainsMono Nerd Font Mono"` 可检查实际匹配的字体。中文正文使用系统的中文回退字体，需要时可安装 `noto-fonts-cjk`。[Arch 字体包](https://archlinux.org/packages/extra/any/ttf-jetbrains-mono-nerd/)

沿用现有配置文件名 `alacritty-glass.toml`，以便已有入口继续加载。窗口使用 100% 不透明度并关闭模糊。Windows 可从开始菜单打开 **Sonder Neovim (Mocha)**，Linux 可使用下方命令。

```sh
# 用专属终端窗口打开当前目录下的项目。
alacritty --config-file "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/alacritty-glass.toml" -e nvim .
```

## Arch 滚动更新

`lazy-lock.json` 记录各插件的 Git 提交。正常的 `pacman -Syu` 独立更新系统软件，例如 Neovim、Node.js；Mason 工具和 Tree-sitter 解析器也有各自的版本。更新前保留锁文件，更新后用 `:checkhealth sonder` 检查工具和高亮，再用常用项目检查补全。若主动执行 `:Lazy update` 后出现插件回归，可还原之前的锁文件并执行 `:Lazy restore`。若升级的是 Neovim 本体，仍需检查其与插件的兼容性。[lazy.nvim 锁文件](https://lazy.folke.io/usage/lockfile) · [Arch 系统维护](https://wiki.archlinux.org/title/System_maintenance)

## 配置位置

`init.lua` 负责引导和模块装配。编辑选项和基础按键在 `lua/sonder/options.lua`、`keymaps.lua`，语言与工具清单在 `language_tools.lua`，补全与格式化在 `languages.lua`。语法解析在 `syntax.lua`，编辑增强在 `editing.lua`，HTML 校验和预览分别在 `html.lua`、`preview.lua`。中英文输入法切换在 `ime.lua`，主题、导航、看板与状态栏集中在 `ui.lua`。各配置模块均附中文注释，锁文件使用插件管理器要求的标准 JSON。
