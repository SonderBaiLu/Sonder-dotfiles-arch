## 启动方式
```fish
nv    # 等价于 NVIM_APPNAME=nv nvim
```

- 配置目录：`~/.config/nv/`
- 数据目录：`~/.local/share/nv/`（插件本体）
- 状态/缓存：`~/.local/state/nv/`、`~/.cache/nv/`

## 目录结构

```
nv/
├── init.lua            # 入口：引导 lazy.nvim，加载 options/keymaps/plugins
└── lua/
    ├── options.lua     # 编辑器基础选项
    ├── keymaps.lua     # 不依赖插件的核心键位
    └── plugins/        # 每个文件 = 一个/一组插件（lazy.nvim 自动导入）
        ├── colorscheme.lua   # catppuccin
        ├── icons.lua         # nvim-web-devicons
        ├── treesitter.lua    # 语法高亮
        ├── lsp.lua           # mason + lspconfig
        ├── blink.lua         # blink.cmp 补全
        ├── fzf.lua           # fzf-lua 模糊查找
        ├── oil.lua           # oil 文件管理
        ├── snacks.lua        # snacks.nvim（状态栏/仪表盘/通知等）
        ├── git.lua           # gitsigns
        └── editor.lua        # surround/autopairs/comment/which-key
```

## 加一个插件

在 `lua/plugins/` 新建 `xxx.lua`：

```lua
return {
  { "作者/插件名", opts = {} },
}
```

然后重启，或 `:Lazy sync`。

## 装一个语言服务器

```vim
:Mason          " 打开面板，选中语言安装
```

或在 `lua/plugins/lsp.lua` 的 `ensure_installed` 里加名字（如 `"pyright"`、`"rust_analyzer"`）。

## 常用键位

| 键 | 作用 |
|---|---|
| `Space ff` | 查找文件 |
| `Space fg` | 全文搜索（需 ripgrep） |
| `Space e` / `-` | oil 文件管理 |
| `gd` | 转到定义 |
| `Space rn` | 重命名 |
| `K` | 悬浮文档 |
| `gcc` | 注释一行 |
| `Space gg` | lazygit |
