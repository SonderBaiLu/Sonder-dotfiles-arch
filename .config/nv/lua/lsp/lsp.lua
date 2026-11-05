return {
  -- 统一安装/管理各类 language server
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {},
  },

  -- mason 与 lspconfig 之间的桥；ensure_installed 可自动装 LSP
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls", -- 配 nvim 自己的 lua（写配置时补全/诊断）
        "vtsls",  -- TypeScript 客户端：vue_ls 的硬性依赖（Volar 需要它处理 script 部分）
        "vue_ls", -- Vue 官方的 Volar：模板语法、组件跳转、标签补全
      },
    },
  },

  -- 格式化器等代码工具的自动安装（conform 只负责调用工具，不负责装，装靠这个）
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy", -- 启动后空闲时加载，随后自动补装缺失工具
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { -- 启动时自动检查并补装这些工具（第一次启动会自动下载）
        "stylua",    -- Lua 格式化
        "shfmt",     -- shell 格式化
        "ruff",      -- Python 格式化 + import 整理
        "prettierd", -- JS/TS/Markdown 格式化
        "jq",        -- JSON 格式化
        "yamlfmt",   -- YAML 格式化
        "taplo",     -- TOML 格式化
      },
      auto_update = false, -- 不自动升级工具版本，保持稳定
      run_on_start = true, -- nvim 启动时自动补装缺失的工具
    },
  },

  -- LSP 客户端配置
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- 把 blink.cmp 的补全能力桥接给 LSP
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- LSP 键位（buffer 局部，只有 LSP 挂上后才生效）
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local buf = ev.buf
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "转到定义")
          map("gD", vim.lsp.buf.declaration, "转到声明")
          map("gr", vim.lsp.buf.references, "查找引用")
          map("gi", vim.lsp.buf.implementation, "转到实现")
          map("<leader>rn", vim.lsp.buf.rename, "重命名")
          map("<leader>ca", vim.lsp.buf.code_action, "代码操作")
          map("K", vim.lsp.buf.hover, "悬浮文档")
          map("<leader>df", vim.diagnostic.open_float, "诊断详情")
          map("[d", vim.diagnostic.goto_prev, "上一个诊断")
          map("]d", vim.diagnostic.goto_next, "下一个诊断")
        end,
      })

      -- 全局默认配置："*" 表示对所有 server 生效（新版 nvim-lspconfig API）
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- vtsls：TypeScript/JavaScript，并扩展支持 .vue（Volar 需要它处理 <script> 部分）
      vim.lsp.config("vtsls", {
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }, -- 让 vtsls 也接管 .vue
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = { -- 让 TS 服务认识 Vue 语法
                {
                  name = "@vue/typescript-plugin", -- Vue 官方 TS 插件
                  location = vim.fn.expand("~/.local/share/nv/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin"), -- 插件实际位置
                  languages = { "vue" }, -- 只对 .vue 生效
                },
              },
            },
          },
        },
      })

      -- 启用这两个 server（vue_ls 依赖 vtsls 已附加，否则会报 Could not find ts_ls/vtsls）
      vim.lsp.enable({ "vtsls", "vue_ls" })
    end,
  },
}
