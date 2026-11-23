return {
  {
    "folke/persisted.nvim", -- 会话管理：记住上次打开的文件和窗口布局
    enabled = false, -- ⚠️ 暂时禁用：此仓库还没过 GitHub「网页允许」白名单，克隆被拒。
    -- 放行后（浏览器打开 github.com/folke/persisted.nvim 通过审核），删掉本行再 :Lazy sync 即可启用
    cmd = { "SessionToggle", "SessionSave", "SessionRestore", "SessionDelete" }, -- 手动命令才懒加载
    keys = {
      { "<leader>Ss", "<Cmd>SessionSave<CR>", desc = "保存会话" },    -- 空格+S s 手动保存当前会话
      { "<leader>Sr", "<Cmd>SessionRestore<CR>", desc = "恢复会话" }, -- 空格+S r 恢复最近会话
      { "<leader>St", "<Cmd>SessionToggle<CR>", desc = "切换会话" },  -- 空格+S t 保存/恢复一键切换
    },
    opts = {
      save_dir = vim.fn.stdpath("state") .. "/sessions/", -- 会话文件存放位置（state 目录，不进 dotfiles 仓库）
      autosave = true,       -- 退出 nvim 时自动保存会话
      autoload = false,      -- 启动时不自动恢复（用空格+S r 手动恢复，避免开错项目）
      use_git_branch = true, -- 不同 git 分支各存一份会话，互不污染
    },
  },
}
