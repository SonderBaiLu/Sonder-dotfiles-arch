return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "切换固定缓冲区" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "删除未固定的缓冲区" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "关闭右侧缓冲区" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "关闭左侧缓冲区" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "缓冲区前移" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "缓冲区后移" },
      { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "选择缓冲区" },
    },
    opts = {
      options = {
        -- stylua: ignore
        close_command = function(n) require("snacks").bufdelete(n) end,
        -- stylua: ignore
        right_mouse_command = function(n) require("snacks").bufdelete(n) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        diagnostics_indicator = function(_, _, diag)
          local ret = (diag.error and "󰅗" .. diag.error .. " " or "")
            .. (diag.warning and "󰀧" .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left" },
          { filetype = "snacks_layout_box" },
        },
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}
