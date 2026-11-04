return {
  {
    "saghen/blink.cmp", -- 补全引擎（Rust 实现，速度快）
    version = "1.*", -- 锁 1.x 大版本，避免上游破坏性更新
    event = "InsertEnter", -- 进入插入模式才加载，不拖慢启动
    dependencies = { "rafamadriz/friendly-snippets" }, -- 常用代码片段库
    opts = {
      -- ─────────────── 键位 ───────────────
      keymap = {
        preset = "default", -- 先继承官方默认（Ctrl+Space 呼出、Ctrl+E 取消、上下滚动文档等）
        ["<C-j>"] = { "select_next", "fallback" }, -- Ctrl+j 向下移动选项；菜单没开时回退成默认行为
        ["<C-k>"] = { "select_prev", "fallback" }, -- Ctrl+k 向上移动选项；菜单没开时回退成默认行为
        ["<CR>"] = { "accept", "fallback" }, -- 回车确认当前选中的补全项
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" }, -- Tab 也能向下选，并能跳到下一个片段占位符
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" }, -- Shift+Tab 向上选 / 回到上一个占位符
      },
      -- ─────────────── 外观 ───────────────
      appearance = {
        nerd_font_variant = "mono", -- 用等宽 Nerd Font 字形，图标和文字能对齐
        -- kind_icons 不覆盖：官方默认就是 Material 方框风格，跟 neo-tree 那套图标一致
      },

      -- ─────────────── 补全行为 ───────────────
      completion = {
        -- 补全菜单窗口
        menu = {
          border = "rounded", -- 圆角边框
          winblend = 0, -- 窗口不透明度：0 = 完全实色，不透明
          max_height = 12, -- 菜单最多显示 12 项，超出用滚动条
          scrollbar = false, -- 右侧显示滚动条
          draw = { -- 每一行长什么样
            padding = 1, -- 左右各留 1 格内边距
            gap = 1, -- 列与列之间留 1 格空隙
            columns = { -- 菜单分三列渲染
              { "kind_icon" }, -- 第 1 列：类型图标（函数/变量/类…）
              { "label", "label_description", gap = 1 }, -- 第 2 列：补全文字 + 类型/签名说明
              { "source_name" }, -- 第 3 列：来源（lsp / snippets / buffer…）
            },
          },
        },

        -- 列表的选择逻辑
        list = {
          selection = {
            preselect = true, -- 菜单一打开就自动高亮第一项
            auto_insert = false, -- 上下移动只改高亮、不直接写入文本；按键确认后才插入
          },
        },

        -- 文档浮窗（选中项的函数签名/注释）
        documentation = {
          auto_show = true, -- 选中项自动弹出文档
          auto_show_delay_ms = 200, -- 延迟 200 毫秒再弹，快速翻选项时不闪烁
          window = {
            border = "rounded", -- 文档窗口也用圆角边框
          },
        },

        -- 行内灰色预览（ghost text）
        ghost_text = {
          enabled = true, -- 开启行内预览
          show_with_menu = true, -- 菜单打开时显示预览
          show_without_menu = false, -- 菜单关闭时不显示，避免视线干扰
        },
      },

      -- ─────────────── 补全来源 ───────────────
      sources = {
        default = { "lsp", "path", "snippets", "buffer" }, -- 依次：语言服务 / 文件路径 / 代码片段 / 当前缓冲区
      },
    },
    opts_extend = { "sources.default" }, -- 允许其他插件往来源列表里追加，而不是覆盖
  },
}
