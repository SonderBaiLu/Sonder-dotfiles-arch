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

  -- 按键提示（按 leader 后弹窗）
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",
      delay = 200,
    },
  },
}
