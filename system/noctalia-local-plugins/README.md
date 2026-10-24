# noctalia 本地插件（fork 收编）

SUPER+/ 快捷键速查面板、状态栏歌词组件的实际程序就在这里。两者都是
noctalia 社区插件的**本地 fork**（拷贝出来改 ID 后从本地目录加载）， fork
原因与全部定制差异见下文——这是以后更新上游、继续修改的唯一依据。

## 程序到底在哪（三层结构）

```
仓库 system/noctalia-local-plugins/keybind-cheatsheet/   ← 唯一事实源（改这里）
仓库 system/noctalia-local-plugins/media-lyrics/
        │  sonder-installer plugins / all 的「本地插件」阶段自动建链
        ▼
~/.local/share/noctalia-local-plugins/<插件>             ← 指向仓库的符号链接
        │  noctalia 的 local 源（settings.toml 里 kind="path" 注册）
        ▼
noctalia 运行时加载（日志 ~/.cache/noctalia/noctalia.log）
```

- **改代码只改仓库里的文件**，`~/.local/share` 下是符号链接，不要直接在那里建真实目录（安装器检测到真实目录会备份后替换回链接）。
- 注册信息在 `~/.local/state/noctalia/settings.toml` 的 `[plugins]` 段（`enabled` 列表 + `[[plugins.source]]` 的 local 条目），由安装器自动维护。

## 两个插件是什么

| 插件 | fork 自 | 打开方式 |
| --- | --- | --- |
| `qicat/keybind-cheatsheet` | `kenn/keybind-cheatsheet` 0.3.0（社区） | SUPER+/ 或 `noctalia msg panel-toggle qicat/keybind-cheatsheet:cheatsheet` |
| `qicat/media-lyrics` | `tranzem/media-lyrics` 0.9.7（社区） | 常驻状态栏（bar.toml 引用 `qicat/media-lyrics:now-playing[-right]`） |

## 日常怎么改

| 想改什么 | 改哪里 |
| --- | --- |
| 面板尺寸 / 列数 | `keybind-cheatsheet/plugin.toml` 的 `[[panel]]`（当前 2200×980 浮动居中）与 `columns` 的 `default`（当前 4，上限 4） |
| 键帽大小 / 字号 | `panel.luau` 的 `keyPill`（fontSize 14、内边距 11×6、圆角 7、minWidth 30） |
| 描述文字字号 | `panel.luau` 的 `bindingRow` 内 description label（fontSize 15） |
| 大分类切块粒度 | `panel.luau` 顶部 `CHUNK_ROWS = 28`（每块行数，决定多列铺满程度） |

改完生效（三连）：

```bash
noctalia msg plugins disable qicat/keybind-cheatsheet
noctalia msg plugins enable  qicat/keybind-cheatsheet
noctalia msg panel-toggle    qicat/keybind-cheatsheet:cheatsheet
# 验证无报错（重点看 CPU budget / parse error）：
grep -aE 'loaded plugin|error|exceeded' ~/.cache/noctalia/noctalia.log | tail
```

media-lyrics 同理，把命令里的插件名换成 `qicat/media-lyrics`（无常驻面板，重载后看状态栏歌词是否恢复）。

⚠️ **CPU 预算红线**：noctalia 给每个插件回调约 25ms CPU，硬编码不可配。改
`service.luau`（扫描/刷新逻辑）时重活必须分片跨回调推进；塞进单个回调会被
中途杀掉，面板卡在加载中。panel.luau 的纯 UI 调整不受影响。

## 重装系统会失效吗

不会。fork 本体在仓库里，`git clone` 即回；`./bootstrap.sh`（内部
`sonder-installer all` 的「本地插件」阶段）自动完成：建 `~/.local/share`
符号链接 + 在 settings.toml 注册 local 源与启用清单。全新系统首次部署时
noctalia 尚未运行，写入即时生效；在运行中的系统上重复执行是幂等无写入的，
但手动改 settings.toml 后需重启 noctalia。

手动等价操作（不想跑完整部署时）：

```bash
./installer/target/release/sonder-installer plugins
```

## 上游更新怎么办

上游是否值得跟：`noctalia msg plugins list` 看社区版版本号（kenn 上游已到
0.3.2，本 fork 基于 0.3.0）；面板工作正常就没有必须更新的理由——**更新意味着
把下面这份差异清单在新版上重新套一遍**。

### keybind-cheatsheet 相对上游 0.3.0 的全部差异（合并依据）

1. `service.luau`：Lua 配置树扫描改为逐文件逐行分片（`luaScanStep`，fork 初衷——
   上游把整棵扫描塞单个回调，超 CPU 预算被杀，面板永远卡在 Reading keybinds）
2. `service.luau`：include 跟随时跳过 `~/.cache/` 下的动态 overlay
   （HVE 的 `dofile ~/.cache/noctalia/HVE/overlay.lua` 挂载行不再报「读不到文件」）
3. `panel.luau`：`keyPill` 键帽加大（fontSize 13→14、内边距 8×4→11×6、
   圆角 4→7、minWidth 20→30）
4. `panel.luau`：描述 fontSize 13→15、行距 paddingV 0→2 / gap 8、列间距 22→16
5. `panel.luau`：分类头改为「主色竖条 + 大写分类名 + 总数徽标」
6. `panel.luau`：新增 `chunkedGroups`（`CHUNK_ROWS = 28`）——超过 28 行的分类
   切块分到各列、列头重复，解决「巨分类占满一列、其余列整列空白」
7. `plugin.toml`：`id` 改 `qicat/keybind-cheatsheet`；`[[panel]]` 1500×760→2200×980；
   `columns` default 3→4

### media-lyrics 相对上游 0.9.7 的差异

`id` 改 `qicat/media-lyrics`；`panel.luau` / `plugin.toml` 有本地定制（未逐行
审计）。上游 0.9.8 新增了 desktop.luau 桌面歌词组件，若想要该功能再考虑跟进。

### 更新操作步骤（以 keybind-cheatsheet 为例）

```bash
# 1. 取回上游新版材质化副本（社区源被停用时副本会被清理，需临时启用）
noctalia msg plugins enable kenn/keybind-cheatsheet
ls ~/.local/state/noctalia/plugins/materialized/community/keybind-cheatsheet
noctalia msg plugins disable kenn/keybind-cheatsheet
# 2. 与本目录 diff，评估上游改了什么
diff -rq ~/.local/state/noctalia/plugins/materialized/community/keybind-cheatsheet \
          ~/Sonder-dotfiles-arch/system/noctalia-local-plugins/keybind-cheatsheet
# 3. 把上方差异清单逐条套到新版文件上（id 改名别忘了），拷回本目录
# 4. 重载验证（上方三连命令），git commit 留档
```

若上游已修复 CPU 预算 bug 且不再需要视觉定制，也可放弃 fork 直接用社区版：
删除本目录对应插件、重跑 `sonder-installer plugins` 前先手动清掉
`~/.local/share/noctalia-local-plugins/` 下的悬空链接，再
`noctalia msg plugins enable kenn/keybind-cheatsheet`——但键帽/铺列等定制会一并丢失。

## 注意

- 删除本目录某插件前，先确认没有别处引用（bar.toml 的歌词组件引用
  `qicat/media-lyrics:now-playing`，速查面板绑定 SUPER+/）。
- 上游同名社区版保持 **disabled**（曾经与 fork 同时启用过，已清理；同时启用
  会出现重复服务与组件冲突）。
