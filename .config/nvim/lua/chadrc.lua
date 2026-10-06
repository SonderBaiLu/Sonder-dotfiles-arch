-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(
--
-- chadrc.lua 是 NvChad 的「主配置文件」:UI、主题、mason 等全局选项都在这里改。
-- 它会和 NvChad 的默认值(nvconfig.lua)做深度合并,所以只需要写想改的部分。

---@type ChadrcConfig
local M = {}

-- ------------------------------------------------------------
-- 主题
-- ------------------------------------------------------------
-- base46 内置的 catppuccin 即 Catppuccin mocha(深色)变体。
-- 想换主题:按 <leader>th 打开选择器可实时预览,选中后写回这里。
M.base46 = {
  theme = "catppuccin",

  -- 透明背景:nvim 不再自己画编辑区背景色,而是透出终端(alacritty)的
  -- 背景与透明度。这同时解决两个问题:
  --   1. 终端是 Catppuccin Frappe、nvim 内置主题是 Mocha,两块深色不一致,
  --      加上终端 18×16px 的窗口 padding,四周会出现一圈明显的「缝隙」;
  --      透明后 padding 区域和编辑区是同一个颜色,缝隙消失
  --   2. 配合 alacritty 已有的 opacity = 0.96 + blur = true(Hyprland 模糊),
  --      nvim 整体获得真正的半透明毛玻璃效果
  -- 想更透/更实,调 alacritty.toml 里的 window.opacity(0.85 更透,1.0 不透)
  transparency = true,
  -- 更改背景色
  hl_override = {
    Comment = { fg = "light_grey" }, -- 传统语法组
    ["@comment"] = { fg = "light_grey" }, -- treesitter 语法组
  },
}

-- ------------------------------------------------------------
-- Mason:语言服务器 / 格式化器的安装器
-- ------------------------------------------------------------
-- :MasonInstallAll 命令安装两部分之和(实现见 ui 仓库 nvchad/mason/init.lua):
--   1. 自动推导 —— 已启用的 LSP(configs/lspconfig.lua)+ 已声明的格式化器
--      (configs/conform.lua),经内置映射表转成 mason 包名
--      (例如 vue_ls → vue-language-server、cssls → css-lsp)
--   2. 下面的 pkgs —— 本配置显式声明的包
-- 为什么两者都留:自动推导只在 lspconfig 已加载的会话里生效(空启动的
-- nvim 推导不出 LSP 包),显式列出则与会话状态无关;install_all 内部
-- 会自动去重,两边同时存在也不会重复安装。
M.mason = {
  pkgs = {
    -- treesitter 编译语法 parser 需要的命令行工具
    -- (它不是 LSP 也不是格式化器,自动推导永远看不到,必须显式列出)
    "tree-sitter-cli",
    -- 语言服务器(mason 包名,对应 configs/lspconfig.lua 启用的服务器)
    "lua-language-server", -- Lua(也用于编辑 nvim 配置本身)
    "html-lsp", -- HTML
    "css-lsp", -- CSS
    "vue-language-server", -- Vue 3(模板/CSS 部分)
    "vtsls", -- TypeScript/JS(也负责 .vue 里的 TS)
    "unocss-language-server", -- UnoCSS 类名补全
    "yaml-language-server", -- YAML
    -- 格式化器(对应 configs/conform.lua)
    "prettier", -- js/ts/vue/css/html/yaml/json
    "stylua", -- Lua
    "sqlfmt", -- SQL
    -- 注意两个「故意不装」:
    --   rust-analyzer —— rustup 已自带一份且随工具链升级,再装一份是冗余
    --   SQL 的 LSP    —— 目前没有可用的(sqlls 已死、sqls 需要 Go、
    --                    sqlfluff 无 LSP 模式),详见 configs/lspconfig.lua
  },

  -- skip:「自动推导结果」的排除名单。
  -- rust-analyzer 排除在外:rustup 已自带一份且随工具链升级自动更新,
  -- 再用 mason 装一份属于冗余,还可能产生版本不一致的问题。
  skip = { "rust-analyzer" },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
