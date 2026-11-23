return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- 锁 master：main 分支是面向 Nvim 0.12 nightly 的重写版，API 全变
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "query", "bash", "python", "rust",
          "javascript", "typescript", "markdown", "markdown_inline",
          "json", "yaml", "toml", "html", "css",
        },
        auto_install = true, -- 打开没装的语言自动补装
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- 可选：结构跳转（dif/cif/vaf 增强）。需要时取消注释并 :Lazy sync
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   event = "VeryLazy",
  --   config = function()
  --     require("nvim-treesitter.configs").setup({
  --       textobjects = {
  --         select = { enable = true },
  --         move = { enable = true },
  --       },
  --     })
  --   end,
  -- },
}
