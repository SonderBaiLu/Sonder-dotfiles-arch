## 启动方式
```fish
nvim   # 直接启动；旧命令 nv 保留为同义别名
```

- 配置目录：`~/.config/nvim/`
- 数据目录：`~/.local/share/nvim/`（插件本体）
- 状态/缓存：`~/.local/state/nvim/`、`~/.cache/nvim/`

## 目录结构

```
nvim/
├── init.lua            # 入口：引导 lazy.nvim，加载 options/keymaps/插件
└── lua/
    ├── options.lua     # 编辑器基础选项
    ├── keymaps.lua     # 不依赖插件的核心键位
    ├── core/           # 诊断图标等核心设置
    ├── lsp/            # LSP、blink.cmp 补全、treesitter
    ├── ui/             # 主题、lualine、bufferline、noice 等界面
    └── plugins/        # 每个文件 = 一个/一组插件（lazy.nvim 自动导入）
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

或在 `lua/lsp/lsp.lua` 的 `ensure_installed` 里加名字（如 `"pyright"`、`"rust_analyzer"`）。

## 常用键位

| 键 | 作用 |
|---|---|
| `Space ff` | 查找文件 |
| `Space fg` | 全文搜索（需 ripgrep） |
| `Space e` | 文件树（neo-tree） |
| `gd` | 转到定义 |
| `Space rn` | 重命名 |
| `K` | 悬浮文档 |
| `gcc` | 注释一行 |
| `Space fm` | 格式化（conform） |
| `Space gg` | lazygit |
| `Space oo` / `Space os` | 今日日记 / 搜索笔记（Obsidian） |
