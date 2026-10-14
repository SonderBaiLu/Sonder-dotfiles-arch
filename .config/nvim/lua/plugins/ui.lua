return{
  "folke/noice.nvim",
	event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim"
  },
  config = function()
    require("noice").setup({
      -- 一些官方或者社区内置的UI
      presets = {
         bottom_search = false, -- 不使用内置的底部样式搜索
         command_palette = true, -- 将命令行 :  居中悬浮为调色板弹窗
         long_message_to_split = true -- 当一条日志或报错信息过长时，自动在新分屏中打开
      },
      lsp = {
        -- 将 cmp 与语法高亮的基础字段交给 Noice 接管
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true
        }
      }
    })
  end
}
