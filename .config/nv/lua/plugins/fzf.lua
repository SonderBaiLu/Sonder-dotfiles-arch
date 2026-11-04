return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "查找文件" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "全文搜索 (rg)" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "缓冲区" },
      { "<leader>fh", "<cmd>FzfLua help_tags<CR>", desc = "帮助" },
      { "<leader>fk", "<cmd>FzfLua keymaps<CR>", desc = "键位" },
      { "<leader>fc", "<cmd>FzfLua git_commits<CR>", desc = "Git 提交" },
      { "<leader>fs", "<cmd>FzfLua git_status<CR>", desc = "Git 状态" },
      { "<leader>fr", "<cmd>FzfLua resume<CR>", desc = "恢复上次搜索" },
    },
    config = function()
      require("fzf-lua").setup({
        -- 想用 bat 做预览可加（需装 bat）：
        -- previewers = { bat = { theme = "Catppuccin Mocha" } },
      })
    end,
  },
}
