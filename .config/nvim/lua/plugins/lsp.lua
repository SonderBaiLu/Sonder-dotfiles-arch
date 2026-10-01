return {
  -- 1. 挂载 HTML 与 CSS 的 LSP 语言服务
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
      },
    },
  },

  -- 2. 确保 Tree-sitter 语法高亮解析器完备
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "html", "css", "javascript" })
      end
    end,
  },
}
