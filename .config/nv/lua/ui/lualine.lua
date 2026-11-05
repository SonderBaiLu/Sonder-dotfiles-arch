return {
  {
    "nvim-lualine/lualine.nvim", -- 底部状态栏插件
    event = "VeryLazy", -- 启动后空闲时加载，不拖慢启动速度
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- 文件类型图标库（filename 组件显示图标用）
    },
    opts = {
      options = {
        theme = "catppuccin-nvim", -- 用 catppuccin 提供的 lualine 主题，自动跟随 mocha 配色
        globalstatus = true, -- 全局状态栏：整个屏幕只保留一条，而不是每个窗口各一条
        component_separators = { left = "", right = "" }, -- 组件之间的分隔符（细竖线）
        section_separators = { left = "", right = "" }, -- 区块之间的分隔符（实心三角）：彩色分块观感来自这里
        disabled_filetypes = { -- 这些文件类型不显示状态栏
          statusline = { "dashboard", "alpha", "snacks_dashboard" }, -- 启动仪表盘不显示
          winbar = {}, -- 顶部窗口栏（本配置没启用，留空即可）
        },
      },
      -- 布局照抄 NvChad：mode | file | git │ lsp_msg diagnostics lsp cwd cursor
      sections = {
        lualine_a = { "mode" }, -- 最左：当前模式（NORMAL / INSERT / VISUAL）
        lualine_b = { "branch", "diff" }, -- 左二：git 分支名 + 增删改统计（对应 NvChad 的 git 段）
        lualine_c = { -- 左三：文件名（对应 NvChad 的 file 段）
          {
            "filename", -- 文件名组件
            path = 1, -- 显示相对路径（0=仅文件名，1=相对路径，2=绝对路径）
            symbols = { -- 文件名前的状态标记
              modified = " ", -- 有未保存修改
              readonly = " ", -- 只读
              unnamed = "[无标题]", -- 未命名缓冲区
              newfile = "[新文件]", -- 新文件
            },
          },
        },
        lualine_x = { -- 右侧第一组：诊断 + LSP + 项目名（对应 NvChad 的 diagnostics / lsp / cwd）
          {
            "diagnostics", -- 诊断数量（错误/警告/信息/提示）
            symbols = {
              error = "󰅗 ", -- 错误：方框 ×（U+F0157）
              warn = "󰀧 ", -- 警告：方框 !（U+F0027）
              info = "󰬐 ", -- 信息：方框字母 I（U+F0B10）
              hint = "󰞋 ", -- 提示：方框 ?（U+F078B）
            },
          },
          {
            "lsp_status", -- LSP 状态：建索引时转圈，空闲时显示客户端名
            icon = "", -- 齿轮图标
            show_name = true, -- 显示 LSP 客户端名（如 lua_ls / vue_ls）
            symbols = {
              spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- 加载动画
              done = "", -- 加载完成的标记
            },
          },
          {
            function() return vim.fn.fnamemodify(vim.fn.getcwd(), ":t") end, -- 取当前目录最后一段作为项目名
            icon = "", -- 文件夹图标
          },
        },
        lualine_y = {}, -- 右二：留空（NvChad 没有进度百分比这一段）
        lualine_z = { "location" }, -- 最右：行:列（对应 NvChad 的 cursor）
      },
      extensions = { "oil", "quickfix", "mason", "lazy" }, -- 给这些界面套用对应的专用配色
    },
  },
}
