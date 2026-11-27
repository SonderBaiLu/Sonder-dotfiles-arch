-- 保留上游的文本对象、自动闭合、改动块、待办与撤销历史；按场景加载。
local icons = vim.g.sonder_nerd_font -- Git 改动和待办标记沿用全局字体设置。

return {
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} }, -- 普通括号与引号成对输入。
  { "echasnovski/mini.ai", event = "VeryLazy", opts = { n_lines = 500 } }, -- 扩展引号、括号等文本对象。
  {
    "echasnovski/mini.surround", event = "VeryLazy",
    opts = { mappings = { add = "ys", delete = "ds", replace = "cs",
      find = "sf", find_left = "sF", highlight = "sh", update_n_lines = "sn" } },
  },
  {
    -- 根据解析树自动闭合 HTML/Vue/JSX 标签；修改起始标签时同步结束标签。
    "windwp/nvim-ts-autotag", ft = { "html", "vue", "javascriptreact", "typescriptreact" },
    opts = { opts = { enable_close = true, enable_rename = true, enable_close_on_slash = false } },
  },
  {
    -- 保留 CSS 颜色预览；只在会出现颜色字面量的文件中加载。
    "NvChad/nvim-colorizer.lua", ft = { "css", "scss", "html", "vue", "lua" }, opts = {},
  },
  {
    "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = icons and "󰐖" or "+" }, change = { text = icons and "󰏬" or "~" },
        delete = { text = icons and "󰍵" or "_" }, topdelete = { text = icons and "󰜸" or "‾" },
        changedelete = { text = icons and "󰏬" or "~" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
        end
        -- diff 窗口保留其原生跳转；普通文件按 Git 的改动块移动。
        for key, direction in pairs({ ["]c"] = "next", ["[c"] = "prev" }) do
          map(key, function()
            if vim.wo.diff then vim.cmd.normal({ vim.v.count1 .. key, bang = true })
            else gs.nav_hunk(direction, { count = vim.v.count1 }) end
          end, key == "]c" and "下一个改动块" or "上一个改动块")
        end
        map("<leader>hs", gs.stage_hunk, "暂存改动块")
        map("<leader>hr", gs.reset_hunk, "撤销改动块")
        map("<leader>hp", gs.preview_hunk, "预览改动块")
        map("<leader>hb", gs.blame_line, "查看当前行的 Git 作者")
      end,
    },
  },
  {
    "folke/todo-comments.nvim", dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = { signs = icons, highlight = { keyword = "wide", after = "fg" } },
    keys = {
      -- 跳转文件内标记，也可在整个项目中查找待办。
      { "]t", function() require("todo-comments").jump_next() end, desc = "下一个待办" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "上一个待办" },
      { "<leader>ft", function() Snacks.picker.todo_comments() end, desc = "搜索项目待办" },
    },
  },
  {
    "jiaoshijie/undotree", dependencies = { "nvim-lua/plenary.nvim" }, opts = {},
    keys = {
      { "<leader>u", function() require("undotree").toggle() end, desc = "查看撤销历史树" },
    },
  },
}
