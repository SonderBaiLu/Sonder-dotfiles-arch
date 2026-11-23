return {
  {
    "jiaoshijie/undotree", -- 可视化撤销历史树（比 mbbill 原版更活跃的纯 Lua 维护版）
    dependencies = "nvim-lua/plenary.nvim", -- 工具库依赖
    keys = {
      -- 这个维护版没有 :UndotreeToggle 命令，官方用法是直接调 toggle()
      { "<leader>u", function() require("undotree").toggle() end, desc = "撤销树" }, -- 空格+u 开关撤销历史树
    },
    config = function()
      require("undotree").setup({})
      -- 全部用默认即可：j/k 上下移动、回车回退到选中节点、? 看帮助
      -- 想自定义键位/窗口位置再回来加 keymaps = {} / window = {} 配置
    end,
  },
}
