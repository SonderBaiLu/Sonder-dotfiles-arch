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
      ensure_installed = { "lua_ls" }, -- 先把配 nvim 自己的 lua 装上，其它按需加
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
      local lspconfig = require("lspconfig")
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

      -- 自动给 mason 装好的每个 server 套统一配置
      vim.lsp.config("*",{
        capabilities = capabilities,
      })
    end,
  },
}
