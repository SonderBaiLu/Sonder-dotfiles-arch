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
      notifier = { enabled = false },  -- 通知交给 noice.nvim + nvim-notify，别开两套通知系统
      indent = { enabled = true },     -- 缩进线
      scope = { enabled = true },      -- 光标所在作用域高亮
      input = { enabled = true },      -- 输入框
      scroll = { enabled = true },     -- 平滑滚动
    },
    keys = {
      { "<leader>gg", function() require("snacks").lazygit() end, desc = "Git 面板" },
      { "<leader>gb", function() require("snacks").git.blame_line() end, desc = "行历史 (Git)" },
      { "<leader>bd", function() require("snacks").bufdelete() end, desc = "关闭缓冲区" },
      { "<leader>nt", function() require("snacks").terminal() end, desc = "终端" },
      -- 空格+nh 已交给 noice 的「消息历史」，这里不再重复绑定，避免按键冲突
    },
  },
}
