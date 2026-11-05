return {
  {
    "jiaoshijie/undotree", -- 可视化撤销历史树（比 mbbill 原版更活跃的纯 Lua 维护版）
    dependencies = "nvim-lua/plenary.nvim", -- 工具库依赖
    cmd = "UndotreeToggle", -- 首次执行命令才加载
    keys = {
      { "<leader>u", "<Cmd>UndotreeToggle<CR>", desc = "撤销树" }, -- 空格+u 开关撤销历史树
    },
    config = function()
      require("undotree").setup({
        -- 全部用默认即可：j/k 上下移动、回车回退到选中节点、? 看帮助
        -- 想改窗口位置/透明度再回来加 window = {} 配置
      })
    end,
  },
}
