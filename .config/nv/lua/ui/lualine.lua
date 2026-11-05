return {
  {
    "nvim-lualine/lualine.nvim", -- 底部状态栏插件
    event = "VeryLazy", -- 启动后空闲时加载，不拖慢启动速度
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- 文件类型图标库（filename 组件显示图标用）
    },
    opts = {
      options = {
        theme = "catppuccin-nvim", -- 用 catppuccin 提供的 lualine 主题，会自动跟随你设的 frappe 配色
        globalstatus = true, -- 全局状态栏：整个屏幕只保留一条，而不是每个窗口各一条
        component_separators = { left = "", right = "" }, -- 组件之间的分隔符（细竖线）
        section_separators = { left = "", right = "" }, -- 区块之间的分隔符（斜切块）
        disabled_filetypes = { -- 这些文件类型不显示状态栏
          statusline = { "dashboard", "alpha", "snacks_dashboard" }, -- 启动仪表盘不显示
          winbar = {}, -- 顶部窗口栏（本配置没启用，留空即可）
        },
      },
      sections = {
        lualine_a = { "mode" }, -- 最左：当前模式（NORMAL / INSERT / VISUAL）
        lualine_b = {
          "branch", -- git 分支名（带分支图标）
          "diff",   -- 与 git HEAD 的增删改统计
          {
            "diagnostics", -- 诊断数量
            symbols = {
              error = "󰅗 ", -- 错误：方框 ×（U+F0157）
              warn = "󰀧 ",  -- 警告：方框 !（U+F0027）
              info = "󰬐 ",  -- 信息：方框字母 I（U+F0B10）
              hint = "󰞋 ",  -- 提示：方框 ?（U+F078B）
            },
          },
        },
        lualine_c = { { "filename", path = 1 } }, -- 左三：文件名（path = 1 显示相对路径）
        lualine_x = { "encoding", "fileformat", "filetype" }, -- 右三：编码、换行格式、文件类型
        lualine_y = { "progress" }, -- 右二：光标在文件中的百分比位置
        lualine_z = { "location" }, -- 最右：当前行:列
      },
      extensions = { "oil", "quickfix", "mason", "lazy" }, -- 给这些界面套用对应的专用配色
    },
  },
}
