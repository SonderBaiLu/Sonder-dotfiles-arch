return {
  {
    "NvChad/nvim-colorizer.lua", -- 颜色代码实时上色：代码里的 #ff0000 直接显示色块
    event = { "BufReadPost", "BufNewFile" }, -- 打开文件就生效
    opts = {
      -- 全部用默认：常见文件类型（css/html/lua 等）自动上色，无需额外配置
      -- 想调样式再加 user_default_options = { mode = "virtualtext" } 之类
    },
  },
}
