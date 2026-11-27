-- 语言配置入口。Mason 安装工具，LSP 提供语义，Blink 展示补全，Conform 负责格式化。
local tools = require("sonder.language_tools")

local function formatting_options()
  local by_ft = {
    rust = { "rustfmt" }, toml = { "taplo" }, lua = { "stylua" },
    sh = { "shfmt" }, bash = { "shfmt" }, zsh = { "shfmt" },
    fish = { "fish_indent" }, -- 安装 fish 时附带；仅编辑 fish 的机器需要它
    python = { "ruff_organize_imports", "ruff_format" }, -- 先整理导入，再排版
  }
  -- Web、数据和文档统一遵循项目的 Prettier 配置；JSONC 的注释会保留。
  -- Conform 优先解析项目 node_modules 中的 Prettier，其次使用 Mason 或 PATH。
  for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue",
    "html", "css", "scss", "less", "json", "jsonc", "yaml", "markdown", "markdown.mdx" }) do
    by_ft[ft] = { "prettier" }
  end
  return {
    formatters_by_ft = by_ft,
    default_format_opts = { lsp_format = "fallback" }, -- 没装外部格式化器时可用 LSP 顶上
    format_on_save = function(buf)
      -- 延续上游手动格式化习惯；只在当前缓冲区显式打开开关后改变保存行为。
      if vim.b[buf].sonder_format_on_save then
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end
    end,
  }
end

return {
  {
    "mason-org/mason.nvim",
    lazy = false, -- 提前加入 Mason 的 bin 路径，让 LSP 与格式化器共享工具。
    opts = { ui = { border = "rounded" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false, -- 启动时注册 VimEnter 钩子，首次安装不会错过检查。
    dependencies = { "mason-org/mason.nvim" },
    opts = function()
      local packages = tools.packages()
      return {
        ensure_installed = packages,
        auto_update = false, -- 手动运行 :MasonToolsUpdate 更新工具。
        -- 全部就绪后跳过启动时的注册表刷新；离线打开已有项目也保持轻快。
        run_on_start = not vim.iter(packages):all(require("mason-registry").is_installed),
        start_delay = 1500,
        -- 清单统一使用 Mason 包名，无需第二套自动启用或安装逻辑。
        integrations = { ["mason-lspconfig"] = false, ["mason-null-ls"] = false, ["mason-nvim-dap"] = false },
      }
    end,
  },
  {
    "saghen/blink.cmp", version = "1.*",
    event = "InsertEnter", dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      fuzzy = { implementation = "lua" }, -- 两端均可直接使用，无需编译或下载原生扩展。
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      keymap = {
        preset = "default", -- Ctrl+Space 请求补全，Ctrl+E 关闭菜单。
        ["<C-j>"] = { "select_next", "fallback" }, ["<C-k>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" }, -- 选中后回车确认；无选择时正常换行。
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      },
      completion = {
        list = { selection = { preselect = false, auto_insert = false } },
        -- 图标紧挨候选名称，保留文字类型和来源；普通字体模式会自动隐藏图标列。
        menu = { border = "rounded", max_height = 12, draw = {
          columns = { vim.g.sonder_nerd_font and { "kind_icon", "label", "label_description", gap = 1 }
            or { "label", "label_description", gap = 1 }, { "kind" }, { "source_name" } },
        } },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
      },
      signature = { enabled = true, window = { border = "rounded" } }, -- 输入实参时显示签名。
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = tools.setup_lsp, -- 使用 Neovim 原生 vim.lsp.config 和 vim.lsp.enable。
  },
  {
    "stevearc/conform.nvim", event = { "BufReadPre", "BufNewFile" }, cmd = "ConformInfo",
    keys = {
      { "<leader>fm", function() require("conform").format({ async = true }) end, desc = "格式化当前文件" },
      { "<leader>tf", function()
        vim.b.sonder_format_on_save = not vim.b.sonder_format_on_save
        vim.notify("当前文件保存格式化" .. (vim.b.sonder_format_on_save and "已开启" or "已关闭"))
      end, desc = "切换当前文件保存格式化" },
    },
    opts = formatting_options,
  },
}
