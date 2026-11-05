return {
  {
    "epwalsh/obsidian.nvim", -- Obsidian 笔记增强（日记/反链/搜索）
    version = "*", -- 用最新稳定版
    ft = "markdown", -- 只在编辑 markdown 时加载
    dependencies = {
      "nvim-lua/plenary.nvim", -- 工具库依赖
    },
    keys = {
      { "<leader>on", "<Cmd>ObsidianNew<CR>", desc = "新建笔记" },       -- 空格+o n 新建一篇笔记
      { "<leader>oo", "<Cmd>ObsidianOpen<CR>", desc = "打开今日日记" },   -- 空格+o o 打开今天日记
      { "<leader>os", "<Cmd>ObsidianSearch<CR>", desc = "搜索笔记" },     -- 空格+o s 全文搜索
      { "<leader>ob", "<Cmd>ObsidianBacklinks<CR>", desc = "反向链接" },  -- 空格+o b 查反链
    },
    opts = {
      workspaces = {
        {
          name = "SondeNote",           -- 工作区名字
          path = "~/Obsidian/SondeNote", -- ⚠️ 改成你的 Obsidian 仓库实际路径
        },
      },
      -- 还没有 vault 的话，把上面 workspaces 整段删掉即可：
      -- 从 vault 目录里启动 nvim 时，obsidian.nvim 会自动以当前目录为工作区
      daily_notes = {
        folder = "日记",         -- 日记存放的子目录名
        date_format = "%Y-%m-%d", -- 日记文件名日期格式
      },
    },
  },
}
