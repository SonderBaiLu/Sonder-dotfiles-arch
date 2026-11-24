return {
  -- 括号/引号自动配对
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- 文本对象增强：va" / di' / ci) 等，自动识别 treesitter 语言对象（跟 mini.surround 同一家）
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = {
      n_lines = 500, -- 超过 500 行的文本对象不处理，防止大文件卡顿
    },
  },

  -- 环绕操作：ysiw" / ds" / cs"'
  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "ys", delete = "ds", replace = "cs",
        find = "sf", find_left = "sF",
        highlight = "sh", update_n_lines = "sn",
      },
    },
  },

  -- 按键提示（按 leader 后弹出）
  -- 注释功能不再装 Comment.nvim：Neovim 0.10+ 内置 gc（可视块）/ gcc（单行）已完全够用
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      win = {
        col = -1,               -- 右对齐（-1 = 距右缘 1 列；0.5 居中 / 正数绝对列）
        row = -1,               -- 贴底（-1 = 距底缘 1 行）
        width = 0.3,            -- 面板宽度 = 屏宽 30%，右侧栏不挤占代码区
        height = { min = 4, max = 25 },
        padding = { 1, 2 },
        wo = { winblend = 0 },
      },
      layout = { spacing = 4 },
      delay = 200,        -- 按 leader 后停顿 200ms 弹出提示
      icons = {
        colors = true,    -- 图标彩色显示
        rules = {         -- 按中文描述自动匹配彩色图标（面板里的键位都会命中）
          { pattern = "删除",     icon = "\u{f01b4}", color = "red" },     -- 垃圾桶
          { pattern = "关闭",     icon = "\u{f0156}", color = "red" },     -- ×
          { pattern = "退出",     icon = "󰈐", color = "red" },
          { pattern = "保存会话", icon = "󰦓", color = "violet" },
          { pattern = "恢复会话", icon = "󰦓", color = "violet" },
          { pattern = "切换会话", icon = "󰦓", color = "violet" },
          { pattern = "保存",     icon = "\u{f0190}", color = "green" },   -- 软盘
          { pattern = "撤销",     icon = "󰆜", color = "cyan" },
          { pattern = "恢复上次", icon = "󰐊", color = "cyan" },
          { pattern = "重命名",   icon = "󰑮", color = "yellow" },
          { pattern = "格式化",   icon = "\u{f0262}", color = "cyan" },    -- 对齐格式
          { pattern = "代码操作", icon = "󰌵", color = "yellow" },
          { pattern = "悬浮文档", icon = "󰆘", color = "violet" },
          { pattern = "诊断",     icon = "󰅗", color = "red" },
          { pattern = "转到定义", icon = "󰒋", color = "azure" },
          { pattern = "转到声明", icon = "󰒋", color = "azure" },
          { pattern = "转到实现", icon = "󰒋", color = "azure" },
          { pattern = "查找引用", icon = "󰒋", color = "azure" },
          { pattern = "悬浮",     icon = "󰒋", color = "azure" },
          { pattern = "行历史",   icon = "󰊢", color = "orange" },
          { pattern = "暂存",     icon = "󰄬", color = "green" },
          { pattern = "预览",     icon = "󰈈", color = "azure" },
          { pattern = "hunk",     icon = "󰏬", color = "orange" },         -- 修改铅笔
          { pattern = "Git",      icon = "󰊢", color = "orange" },
          { pattern = "TODO",     icon = "󰄲", color = "green" },          -- 复选框
          { pattern = "终端",     icon = "󰆍", color = "cyan" },
          { pattern = "通知",     icon = "󰂚", color = "yellow" },
          { pattern = "消息",     icon = "󰂚", color = "yellow" },
          { pattern = "搜索",     icon = "󰱽", color = "blue" },
          { pattern = "查找文件", icon = "󰍉", color = "yellow" },          -- 放大镜
          { pattern = "查找",     icon = "󰍉", color = "yellow" },
          { pattern = "键位",     icon = "󰌌", color = "azure" },
          { pattern = "帮助",     icon = "󰋗", color = "violet" },
          { pattern = "服务器",   icon = "󰈈", color = "green" },
          { pattern = "文件树",   icon = "󰙅", color = "green" },
          { pattern = "文件管理器", icon = "󰙅", color = "green" },
          { pattern = "文件",     icon = "\u{f0646}", color = "yellow" },  -- 文档
          { pattern = "缓冲区",   icon = "󰓩", color = "azure" },
          { pattern = "会话",     icon = "󰦓", color = "violet" },
          { pattern = "撤销树",   icon = "󰆜", color = "cyan" },
          { pattern = "Hunk",     icon = "󰏬", color = "orange" },         -- 修改铅笔
          { pattern = "诊断详情", icon = "󰅗", color = "red" },
        },
      },
      spec = {            -- leader 分组（组名同样会命中上面的图标规则）
        { "<leader>b", group = "缓冲区", mode = "n" },     -- 空格+b → 缓冲区操作
        { "<leader>c", group = "代码操作", mode = "n" },   -- 空格+ca → LSP 代码操作
        { "<leader>d", group = "诊断", mode = "n" },       -- 空格+d → LSP 诊断
        { "<leader>e", group = "文件树", mode = "n" },     -- 空格+e → neo-tree
        { "<leader>f", group = "查找", mode = "n" },       -- 空格+f → fzf 查找
        { "<leader>g", group = "Git", mode = "n" },        -- 空格+g → lazygit/blame
        { "<leader>h", group = "Hunk", mode = "n" },       -- 空格+h → 暂存/撤销 hunk
        { "<leader>n", group = "通知/终端", mode = "n" },  -- 空格+n → 终端/通知历史
        { "<leader>p", group = "预览", mode = "n" },       -- 空格+p → prelive 网页预览
        { "<leader>r", group = "重命名", mode = "n" },     -- 空格+rn → LSP 重命名
        { "<leader>S", group = "会话", mode = "n" },       -- 空格+S → 会话保存/恢复
        -- Neovim 内置 ] / [ 系列键位的中文描述（纯显示覆盖，不改变按键行为）
        -- ] = 下一个系列，[ = 上一个系列；已由插件注册中文 desc 的（如 ]t）不受影响
        { "]a", desc = "下一个参数" },   { "]A", desc = "最后一个参数" },
        { "[a", desc = "上一个参数" },   { "[A", desc = "第一个参数" },
        { "]d", desc = "下一个诊断" },   { "]D", desc = "最后一个诊断" },
        { "[d", desc = "上一个诊断" },   { "[D", desc = "第一个诊断" },
        { "]i", desc = "作用域底部" },   { "[i", desc = "作用域顶部" },
        { "]l", desc = "下一个位置项" }, { "]L", desc = "最后一个位置项" },
        { "[l", desc = "上一个位置项" }, { "[L", desc = "第一个位置项" },
        { "]m", desc = "下一个方法" },   { "]M", desc = "最后一个方法" },
        { "[m", desc = "上一个方法" },   { "[M", desc = "第一个方法" },
        { "]q", desc = "下一个修复项" }, { "]Q", desc = "最后一个修复项" },
        { "[q", desc = "上一个修复项" }, { "[Q", desc = "第一个修复项" },
        { "]s", desc = "下一个拼写错误" }, { "]S", desc = "最后一个拼写错误" },
        { "[s", desc = "上一个拼写错误" }, { "[S", desc = "第一个拼写错误" },
        { "]%", desc = "下一个未匹配组" },
        { "](", desc = "下一个 (" }, { "])", desc = "下一个 )" },
        { "[(", desc = "上一个 (" }, { "[)", desc = "上一个 )" },
        { "]<", desc = "下一个 <" }, { "]>", desc = "下一个 >" },
        { "[<", desc = "上一个 <" }, { "[>", desc = "上一个 >" },
        { "]{", desc = "下一个 {" }, { "[}", desc = "上一个 }" },
        -- z 前缀：折叠 / 滚动 / 拼写
        { "za", desc = "切换折叠" },     { "zA", desc = "切换全部折叠" },
        { "zc", desc = "关闭折叠" },     { "zC", desc = "关闭全部折叠" },
        { "zo", desc = "打开折叠" },     { "zO", desc = "打开全部折叠" },
        { "zr", desc = "减少折叠层级" }, { "zR", desc = "展开全部折叠" },
        { "zm", desc = "增加折叠层级" }, { "zM", desc = "折叠全部" },
        { "zv", desc = "展开光标所在折叠" }, { "zx", desc = "刷新折叠" },
        { "zf", desc = "创建折叠" },     { "zd", desc = "删除折叠" },
        { "zE", desc = "删除全部折叠" },
        { "zt", desc = "光标行滚到顶部" }, { "zz", desc = "光标行滚到中间" },
        { "zb", desc = "光标行滚到底部" },
        { "zH", desc = "左滚半屏" }, { "zL", desc = "右滚半屏" },
        { "zg", desc = "标记好拼写" },   { "zG", desc = "标记好拼写(永久)" },
        { "zw", desc = "标记坏拼写" },   { "zW", desc = "标记坏拼写(永久)" },
        { "zug", desc = "撤销好拼写标记" }, { "zuw", desc = "撤销坏拼写标记" },
        { "z=", desc = "拼写建议" },
        -- g 前缀：跳转 / 操作（带 LSP 的 buffer 里 gd/gi/gD/gr 等会优先显示 LSP 描述）
        { "gd", desc = "转到定义" },  { "gD", desc = "转到声明" },
        { "gi", desc = "转到实现" },  { "gI", desc = "行首插入" },
        { "gr", desc = "查找引用" },
        { "grn", desc = "重命名符号" }, { "grr", desc = "查找引用" },
        { "gri", desc = "转到实现" }, { "gO", desc = "文档符号列表" },
        { "g?", desc = "悬浮诊断详情" },
        { "gg", desc = "跳到文件开头" },
        { "gj", desc = "下移显示行" }, { "gk", desc = "上移显示行" },
        { "gJ", desc = "合并行(无空格)" },
        { "gt", desc = "下一个标签页" }, { "gT", desc = "上一个标签页" },
        { "gq", desc = "格式化选区" },
        { "gu", desc = "转小写" }, { "gU", desc = "转大写" }, { "g~", desc = "翻转大小写" },
        { "ga", desc = "查看字符编码" },
        { "gp", desc = "粘贴到光标后" }, { "gP", desc = "粘贴到光标前" },
        { "gf", desc = "打开光标下文件" }, { "gF", desc = "打开文件并跳行" },
        { "g;", desc = "上次修改位置" }, { "g,", desc = "下次修改位置" },
        { "gv", desc = "重选上次选区" },
        { "gc", desc = "注释操作符" }, { "gcc", desc = "注释/取消当前行" },
        { "g_", desc = "跳到行尾(不含空格)" },
        -- <C-w> 前缀：窗口操作
        { "<C-w>s", desc = "上下分屏" },  { "<C-w>v", desc = "左右分屏" },
        { "<C-w>c", desc = "关闭窗口" },  { "<C-w>o", desc = "只留当前窗口" },
        { "<C-w>n", desc = "新建空白窗口" }, { "<C-w>q", desc = "退出窗口" },
        { "<C-w>=", desc = "均分窗口" },
        { "<C-w>+", desc = "窗口增高" },  { "<C-w>-", desc = "窗口降低" },
        { "<C-w>_", desc = "窗口最大高度" }, { "<C-w>|", desc = "窗口最大宽度" },
        { "<C-w><", desc = "窗口变窄" },  { "<C-w>>", desc = "窗口变宽" },
        { "<C-w>x", desc = "交换窗口" },
        { "<C-w>r", desc = "向下轮换窗口" }, { "<C-w>R", desc = "向上轮换窗口" },
        { "<C-w>T", desc = "移到新标签页" },
        { "<C-w>w", desc = "下一个窗口" }, { "<C-w>W", desc = "上一个窗口" },
        { "<C-w>p", desc = "上次窗口" },
        { "<C-w>h", desc = "左窗口" }, { "<C-w>j", desc = "下窗口" },
        { "<C-w>k", desc = "上窗口" }, { "<C-w>l", desc = "右窗口" },
        { "<C-w>H", desc = "移到最左" }, { "<C-w>J", desc = "移到最下" },
        { "<C-w>K", desc = "移到最上" }, { "<C-w>L", desc = "移到最右" },
        -- 常用单键动作
        { "G", desc = "跳到文件结尾" }, { "%", desc = "匹配括号" },
        { "*", desc = "查找光标词(向下)" }, { "#", desc = "查找光标词(向上)" },
        -- 说明：撤销树是单键位（空格+u 直接触发），不再单设组，避免面板展开是空的
      },
    },
  },
}
