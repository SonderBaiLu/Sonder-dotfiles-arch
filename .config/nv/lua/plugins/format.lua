return {
  {
    "stevearc/conform.nvim", -- 代码格式化引擎（支持保存时自动格式化）
    event = { "BufReadPre", "BufNewFile" }, -- 打开文件就加载，保证保存时可用
    cmd = { "ConformInfo" }, -- 查看当前文件的格式化器状态
    keys = {
      { "<leader>fm", function() require("conform").format({ async = true }) end, desc = "格式化" }, -- 空格+f m 手动格式化
    },
    opts = {
      -- 各文件类型对应的格式化器（用 :Mason 安装对应工具，如 stylua / shfmt / ruff / prettierd）
      formatters_by_ft = {
        lua = { "stylua" },                       -- Lua 用 stylua（你的 nvim 配置语言）
        bash = { "shfmt" },                       -- Bash 用 shfmt
        sh = { "shfmt" },                         -- 覆盖 .sh 文件
        zsh = { "shfmt" },                        -- 覆盖 .zsh 文件
        fish = { "fish_indent" },                 -- fish 用自带 fish_indent
        python = { "ruff_format", "ruff_organize_imports" }, -- Python 用 ruff（格式化 + 整理 import）
        rust = { "rustfmt" },                     -- Rust 用 rustfmt
        javascript = { "prettierd", "prettier" }, -- JS 优先 prettierd，没有则回退 prettier
        typescript = { "prettierd", "prettier" }, -- TS 同上
        json = { "jq" },                          -- JSON 用 jq 整理
        yaml = { "yamlfmt" },                     -- YAML 用 yamlfmt
        toml = { "taplo" },                       -- TOML 用 taplo
        markdown = { "prettierd" },               -- Markdown 用 prettierd
      },
      -- 手动格式化模式：不启用「保存自动格式化」，按空格+f m 才格式化。
      -- 想改回保存自动格式化时，取消下面这段注释即可：
      -- format_on_save = function(bufnr)
      --   -- 两个手动开关：全局 vim.g.disable_autoformat，或单文件 vim.b[bufnr].disable_autoformat
      --   if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      --     return -- 返回 nil = 本次保存跳过格式化
      --   end
      --   return {
      --     timeout_ms = 500,        -- 格式化器 500ms 没跑完就放弃，不卡保存
      --     lsp_format = "fallback", -- 优先用 LSP 的格式化，LSP 没有时才回退到上面的列表
      --   }
      -- end,
    },
  },
}
