return {
  -- 括号/引号自动配对
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- 文本对象增强：va" / di' / ci) 等，自动识别 treesitter 语言对象（跟 mini.surround 同一家）
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = {
      n_lines = 500, -- 超过 500 行的文本对象不处理，防止大文件卡顿
    },
  },

  -- 环绕操作：ysiw" / ds" / cs"'
  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "ys", delete = "ds", replace = "cs",
        find = "sf", find_left = "sF",
        highlight = "sh", update_n_lines = "sn",
      },
    },
  },

  -- 按键提示（按 leader 后弹出）
  -- 注释功能不再装 Comment.nvim：Neovim 0.10+ 内置 gc（可视块）/ gcc（单行）已完全够用
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      win = {
        position = "right", -- 提示面板显示在屏幕右侧（不遮挡下方代码区）
        padding = { 1, 2 },
        wo = { winblend = 0 },
      },
      layout = { spacing = 4 },
      delay = 200,        -- 按 leader 后停顿 200ms 弹出提示
      icons = {
        colors = true,    -- 图标彩色显示
        rules = {         -- 按中文描述自动匹配彩色图标（面板里的键位都会命中）
          { pattern = "删除",     icon = "", color = "red" },
          { pattern = "关闭",     icon = "", color = "red" },
          { pattern = "退出",     icon = "󰈐", color = "red" },
          { pattern = "保存会话", icon = "󰦓", color = "violet" },
          { pattern = "恢复会话", icon = "󰦓", color = "violet" },
          { pattern = "切换会话", icon = "󰦓", color = "violet" },
          { pattern = "保存",     icon = "", color = "green" },
          { pattern = "撤销",     icon = "󰆜", color = "cyan" },
          { pattern = "恢复上次", icon = "󰐊", color = "cyan" },
          { pattern = "重命名",   icon = "󰑮", color = "yellow" },
          { pattern = "格式化",   icon = "", color = "cyan" },
          { pattern = "代码操作", icon = "󰌵", color = "yellow" },
          { pattern = "悬浮文档", icon = "󰆘", color = "violet" },
          { pattern = "诊断",     icon = "󰅗", color = "red" },
          { pattern = "转到定义", icon = "󰒋", color = "azure" },
          { pattern = "转到声明", icon = "󰒋", color = "azure" },
          { pattern = "转到实现", icon = "󰒋", color = "azure" },
          { pattern = "查找引用", icon = "󰒋", color = "azure" },
          { pattern = "悬浮",     icon = "󰒋", color = "azure" },
          { pattern = "行历史",   icon = "󰊢", color = "orange" },
          { pattern = "暂存",     icon = "󰄬", color = "green" },
          { pattern = "预览",     icon = "󰈈", color = "azure" },
          { pattern = "hunk",     icon = "", color = "orange" },
          { pattern = "Git",      icon = "󰊢", color = "orange" },
          { pattern = "TODO",     icon = "", color = "green" },
          { pattern = "终端",     icon = "󰆍", color = "cyan" },
          { pattern = "通知",     icon = "󰂚", color = "yellow" },
          { pattern = "消息",     icon = "󰂚", color = "yellow" },
          { pattern = "搜索",     icon = "󰱽", color = "blue" },
          { pattern = "查找文件", icon = "", color = "yellow" },
          { pattern = "查找",     icon = "󰍉", color = "yellow" },
          { pattern = "键位",     icon = "󰌌", color = "azure" },
          { pattern = "帮助",     icon = "󰋗", color = "violet" },
          { pattern = "服务器",   icon = "󰈈", color = "green" },
          { pattern = "文件树",   icon = "󰙅", color = "green" },
          { pattern = "文件管理器", icon = "󰙅", color = "green" },
          { pattern = "文件",     icon = "", color = "yellow" },
          { pattern = "缓冲区",   icon = "󰓩", color = "azure" },
          { pattern = "会话",     icon = "󰦓", color = "violet" },
          { pattern = "撤销树",   icon = "󰆜", color = "cyan" },
          { pattern = "Hunk",     icon = "", color = "orange" },
          { pattern = "诊断详情", icon = "󰅗", color = "red" },
        },
      },
      spec = {            -- leader 分组（组名同样会命中上面的图标规则）
        { "<leader>b", group = "缓冲区", mode = "n" },     -- 空格+b → 缓冲区操作
        { "<leader>d", group = "诊断", mode = "n" },       -- 空格+d → LSP 诊断
        { "<leader>e", group = "文件树", mode = "n" },     -- 空格+e → neo-tree
        { "<leader>f", group = "查找", mode = "n" },       -- 空格+f → fzf 查找
        { "<leader>g", group = "Git", mode = "n" },        -- 空格+g → lazygit/blame
        { "<leader>h", group = "Hunk", mode = "n" },       -- 空格+h → 暂存/撤销 hunk
        { "<leader>n", group = "通知/终端", mode = "n" },  -- 空格+n → 终端/通知历史
        { "<leader>S", group = "会话", mode = "n" },       -- 空格+S → 会话保存/恢复
        -- 说明：撤销树是单键位（空格+u 直接触发），不再单设组，避免面板展开是空的
      },
    },
  },
}
