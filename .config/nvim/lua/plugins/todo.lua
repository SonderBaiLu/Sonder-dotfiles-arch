return {
  {
    "folke/todo-comments.nvim", -- TODO/FIXME/HACK 等标记高亮与跳转
    event = { "BufReadPost", "BufNewFile" }, -- 打开文件就生效
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "下一个 TODO" }, -- 跳到下一个标记
      { "[t", function() require("todo-comments").jump_prev() end, desc = "上一个 TODO" }, -- 跳到上一个标记
      { "<leader>ft", function() require("todo-comments.fzf").search() end, desc = "TODO 列表" }, -- 空格+ft 用 fzf 列出全部标记
    },
    opts = {
      signs = true, -- 行号列显示标记图标
      highlight = {
        keyword = "wide", -- 关键词高亮方式：wide = 整行底色，一眼扫出待办
        after = "fg",     -- 关键词后面的文字用前景色，不再额外加底色
      },
    },
  },
}
