-- Claude Code 面板，后端自动走 ~/.claude/settings.json 里的 DeepSeek 配置
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    opts = {
      terminal = {
        provider = "snacks",              -- 用 snacks 的窗口管理，样式可调
        split_side = "right",
        split_width_percentage = 0.42,    -- 默认 0.30 太窄，加宽
        auto_insert = true,               -- 切到面板自动进入输入模式
        snacks_win_opts = {
          border = "rounded",             -- 圆角边框
          title = " Claude Code ",
          title_pos = "center",
          wo = { winblend = 0 },
        },
      },
    },
    cmd = {
      "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel",
      "ClaudeCodeAdd", "ClaudeCodeSend", "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus", "ClaudeCodeStart", "ClaudeCodeStop",
      "ClaudeCodeOpen", "ClaudeCodeClose",
      "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>",      desc = "Toggle Claude 面板" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "聚焦 Claude 面板" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "恢复历史会话" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "继续最近会话" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "选择模型" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "把当前文件发给 Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "把选中代码发给 Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "接受 diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "拒绝 diff" },
    },
  },
}

