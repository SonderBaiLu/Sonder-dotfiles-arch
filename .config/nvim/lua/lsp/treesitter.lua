return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- 不锁分支：跟随默认 main（Neovim 0.12+ 的当前实现），插件更新走新 API
    lazy = false, -- main 分支不支持懒加载，必须启动时加载
    build = ":TSUpdate", -- 插件更新后同步更新已装解析器
    config = function()
      require("nvim-treesitter").setup()

      -- 需要的语言解析器：已装的会跳过，缺的异步补装（不阻塞启动）
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc", "query", "bash", "python", "rust",
        "javascript", "typescript", "markdown", "markdown_inline",
        "json", "yaml", "toml", "html", "css",
      })

      -- main 分支不再自动开高亮：打开文件时手动启动
      -- 没装解析器的文件类型会报错，用 pcall 静默跳过
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },

  -- 缩进（indentexpr）在新 main 分支仍属实验特性，暂不启用，避免和其他缩进设置冲突
  -- 需要结构跳转（dif/cif/vaf 增强）时按官方 README 的 textobjects 新用法单独添加
}
