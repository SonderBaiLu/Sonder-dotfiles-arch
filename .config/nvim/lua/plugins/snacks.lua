return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true }, -- 大文件自动降级，防卡顿
      dashboard = {
        enabled = true,
        preset = {
          header = [[
███╗   ██╗██╗   ██╗██╗███╗   ███╗
████╗  ██║██║   ██║██║████╗ ████║
██╔██╗ ██║██║   ██║██║██╔████╔██║
██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
        },
        sections = {
          { section = "header" },
          { icon = " ", title = "最近文件", section = "recent_files", indent = 2, padding = 1 },
          { icon = " ", title = "项目", section = "projects", indent = 2, padding = 1 },
        },
      },
      notifier = { enabled = true },   -- 通知
      indent = { enabled = true },     -- 缩进线
      scope = { enabled = true },      -- 光标所在作用域高亮
      input = { enabled = true },      -- 输入框
      scroll = { enabled = true },     -- 平滑滚动
    },
    keys = {
      { "<leader>gg", function() require("snacks").lazygit() end, desc = "Lazygit" },
      { "<leader>gb", function() require("snacks").git.blame_line() end, desc = "Git blame" },
      { "<leader>bd", function() require("snacks").bufdelete() end, desc = "关闭缓冲区" },
      { "<leader>nt", function() require("snacks").terminal() end, desc = "终端" },
      { "<leader>nh", function() require("snacks").notifier.show_history() end, desc = "通知历史" },
    },
  },
}
