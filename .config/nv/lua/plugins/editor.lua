return {
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

  -- 括号/引号自动配对
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- 注释：gcc 行注释 / gc 可视块注释
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
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

  -- 按键提示（按 leader 后弹窗）
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic", -- 经典布局风格
      delay = 200,        -- 按 leader 后停顿 200ms 弹出提示
      spec = {            -- 给 leader 前缀分组，让空格菜单显示中文组名
        { "<leader>b", group = "缓冲区", mode = "n" },     -- 空格+b → 缓冲区操作
        { "<leader>d", group = "诊断", mode = "n" },       -- 空格+d → LSP 诊断
        { "<leader>e", group = "文件树", mode = "n" },     -- 空格+e → neo-tree
        { "<leader>f", group = "查找", mode = "n" },       -- 空格+f → fzf 查找
        { "<leader>g", group = "Git", mode = "n" },        -- 空格+g → lazygit/blame
        { "<leader>h", group = "Hunk", mode = "n" },       -- 空格+h → 暂存/撤销 hunk
        { "<leader>n", group = "通知/终端", mode = "n" },  -- 空格+n → 终端/通知历史
        { "<leader>o", group = "Obsidian", mode = "n" },   -- 空格+o → 笔记操作
        { "<leader>S", group = "会话", mode = "n" },       -- 空格+S → 会话保存/恢复
        { "<leader>u", group = "撤销树", mode = "n" },     -- 空格+u → 撤销历史
      },
    },
  },
}
