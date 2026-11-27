-- 图标随编辑器总开关切换，文件树、状态栏与快捷键提示共用所选字体。
local icons = vim.g.sonder_nerd_font
local glass = vim.env.SONDER_GLASS == "1" -- 默认实色；显式设为 1 时才沿用终端底色。

local function apply_theme()
  -- 编辑区使用 Mocha 底色，侧栏略深，浮窗略亮；边界和光标行只提供轻微对比。
  require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = glass,
    float = { transparent = false, solid = false },
    custom_highlights = function(c)
      return {
        SnacksPicker = { fg = c.text, bg = c.mantle },
        SnacksPickerBorder = { fg = c.surface2, bg = c.mantle },
        SnacksPickerTitle = { fg = c.lavender, bg = c.mantle, bold = true },
        NormalFloat = { fg = c.text, bg = "#242436" },
        FloatBorder = { fg = c.surface2, bg = "#242436" },
        WhichKeyNormal = { link = "NormalFloat" }, WhichKeyBorder = { link = "FloatBorder" },
        CursorLine = { bg = "#29293b" }, ColorColumn = { bg = "#252536" },
        Comment = { fg = c.overlay1, italic = true },
      }
    end,
  })
  vim.cmd.colorscheme("catppuccin-mocha")
end

-- 用当前文件查找项目根目录；独立文件使用其所在目录，空缓冲区从当前工作目录开始。
local function project_dir()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = vim.bo.buftype == "" and file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
  return vim.fs.root(dir, { ".git" }) or dir
end

local function files()
  local cwd = project_dir()
  if vim.fn.executable("rg") == 1 or vim.fn.executable("fd") == 1 or vim.fn.executable("fdfind") == 1 then
    return Snacks.picker.files({ cwd = cwd, hidden = true, title = "项目文件" })
  end
  -- Git 可以列出跟踪及未跟踪文件；普通目录仍可通过文件树浏览，兼容 Windows 的 find.exe。
  if vim.fs.root(cwd, ".git") then
    return Snacks.picker.git_files({ cwd = cwd, untracked = true, title = "项目文件" })
  end
  return Snacks.explorer({ cwd = cwd })
end

local function grep()
  local cwd = project_dir()
  if vim.fn.executable("rg") == 1 then
    return Snacks.picker.grep({ cwd = cwd, hidden = true, title = "搜索项目内容" })
  end
  if vim.fs.root(cwd, ".git") then
    return Snacks.picker.git_grep({ cwd = cwd, untracked = true, title = "搜索 Git 项目内容" })
  end
  vim.notify("请安装 ripgrep（rg）以全文搜索普通目录。", vim.log.levels.WARN)
end

local function board()
  -- 实时读取全局与当前缓冲区映射，连接 LSP 后也能搜到当前语言的操作。
  return Snacks.picker.keymaps({ title = "快捷键看板", layout = { preset = "select" } })
end

return {
  -- Snacks 文件树和状态栏按需读取扩展名图标，Rust、Vue、Markdown 等各有标记。
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false,
    config = apply_theme,
    keys = {
      { "<leader>tg", function()
        glass = not glass
        apply_theme()
      end, desc = "切换编辑区实色与终端底色" },
    },
  },
  {
    -- 文件树与模糊查找共享同一套导航操作；rg 同时供文件和全文搜索使用。
    "folke/snacks.nvim", priority = 900, lazy = false,
    opts = {
      bigfile = { enabled = true },    -- 降低大文件的高亮和渲染开销。
      indent = { enabled = true },     -- 细线标记缩进，便于阅读 Vue 和 YAML 的嵌套结构。
      input = { enabled = true },
      notifier = { enabled = true },  -- 一套通知记录，同时承接 vim.notify 和消息历史。
      explorer = { enabled = true },
      picker = {
        enabled = true,
        prompt = "> ",
        -- 查找时输入框处于插入模式，按一次 Esc 即可返回原来的文件和光标位置。
        win = { input = { keys = { ["<Esc>"] = { "cancel", mode = { "i", "n" } } } } },
        -- 仅指定普通字体缺少的字形；文件树的连接线和诊断等级均可直接辨认。
        icons = not icons and {
          files = { enabled = false },
          keymaps = { nowait = "" },
          ui = { live = "* " },
          git = { commit = "# ", staged = "+", added = "+", deleted = "-", ignored = "~", renamed = ">", unmerged = "!" },
          diagnostics = { Error = "E ", Warn = "W ", Hint = "H ", Info = "I " },
        } or nil,
        sources = {
          explorer = { title = "文件树", hidden = true, exclude = { ".git" } },
        },
      },
      dashboard = {
        enabled = true,
        preset = {
          header = "Sonder / Neovim",
          keys = {
            { key = "f", desc = "查找项目文件", action = files },
            { key = "g", desc = "搜索项目内容", action = grep },
            { key = "r", desc = "最近编辑", action = function() Snacks.picker.recent() end },
            { key = "?", desc = "查看快捷键", action = board },
          },
        },
        sections = { { section = "header" }, { section = "keys", gap = 1, padding = 1 } },
      },
    },
    keys = {
      -- 沿用上游空格键序列，增加可按中文描述或键名过滤的快捷键看板。
      { "<leader>?", board, desc = "快捷键看板" },
      { "<leader>fk", board, desc = "搜索快捷键" },
      { "<leader>e", function() Snacks.explorer({ cwd = project_dir() }) end, desc = "切换文件树" },
      { "<leader>ff", files, desc = "查找项目文件" },
      { "<leader>fg", grep, desc = "搜索项目内容" },
      { "<leader>fb", function() Snacks.picker.buffers({ title = "缓冲区" }) end, desc = "查找缓冲区" },
      { "<leader>fh", function() Snacks.picker.help({ title = "帮助主题" }) end, desc = "搜索帮助" },
      { "<leader>fc", function() Snacks.picker.git_log({ cwd = project_dir() }) end, desc = "查看 Git 提交" },
      { "<leader>fs", function() Snacks.picker.git_status({ cwd = project_dir() }) end, desc = "查看 Git 状态" },
      { "<leader>fr", function() Snacks.picker.resume() end, desc = "恢复上次搜索" },
      { "<leader>fo", function() Snacks.picker.recent({ title = "最近编辑" }) end, desc = "打开最近文件" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "关闭缓冲区" },
      { "<leader>gb", function() Snacks.git.blame_line() end, desc = "查看当前行提交记录" },
      { "<leader>gg", function()
        -- 有 Lazygit 时开启交互面板，只有 Git 的环境仍能查看工作区状态。
        if vim.fn.executable("lazygit") == 1 then Snacks.lazygit({ cwd = project_dir() })
        else Snacks.picker.git_status({ cwd = project_dir() }) end
      end, desc = "打开 Git 面板" },
      { "<leader>nt", function() Snacks.terminal() end, desc = "切换终端" },
      { "<leader>nh", function() Snacks.notifier.show_history() end, desc = "查看通知历史" },
    },
  },
  {
    -- 空格后短暂停顿显示可用的下一键；动作描述来自各模块的 desc，避免维护两份按键表。
    "folke/which-key.nvim", event = "VeryLazy",
    opts = {
      preset = "modern", delay = 220,
      win = { -- 面板固定在屏幕右侧（col/row 为负 = 距右/下缘 1 格；width 为屏宽比例），不遮挡下方代码区
        col = -1, row = -1, width = 0.3,
        border = "rounded", padding = { 1, 2 }, wo = { winblend = 0 },
      },
      icons = { -- 有 Nerd Font 时按描述关键词自动上彩色图标；没有则降级为纯文字键名提示
        mappings = icons, colors = icons,
        rules = icons and {
          -- 动作词（规则有先后：具体词在前，泛化方向词在最后兜底）
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
          { pattern = "代码",     icon = "\u{f121}", color = "blue" },     -- 代码分组
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
          { pattern = "改动块",   icon = "󰏬", color = "orange" },          -- 同 hunk（新组名）
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
          { pattern = "Hunk",     icon = "󰏬", color = "orange" },
          { pattern = "诊断详情", icon = "󰅗", color = "red" },
          -- 内置键位词（z / g / C-w / ] [ 系列）
          { pattern = "折叠",   icon = "\u{f035D}", color = "grey" },
          { pattern = "窗口",   icon = "\u{f2d0}", color = "cyan" },
          { pattern = "标签页", icon = "\u{f008b}", color = "azure" },
          { pattern = "拼写",   icon = "\u{f0d64}", color = "yellow" },
          { pattern = "方法",   icon = "\u{f0862}", color = "purple" },
          { pattern = "参数",   icon = "\u{f0279}", color = "grey" },
          { pattern = "修复项", icon = "\u{f0ad}", color = "orange" },
          { pattern = "位置项", icon = "\u{f03a}", color = "azure" },
          { pattern = "分屏",   icon = "\u{f0db}", color = "cyan" },
          { pattern = "注释",   icon = "\u{f075}", color = "green" },
          { pattern = "粘贴",   icon = "\u{f0ea}", color = "cyan" },
          { pattern = "大写",   icon = "\u{f031}", color = "violet" },
          { pattern = "小写",   icon = "\u{f031}", color = "violet" },
          { pattern = "大小写", icon = "\u{f031}", color = "violet" },
          { pattern = "编码",   icon = "\u{f292}", color = "grey" },
          { pattern = "重选",   icon = "\u{f877}", color = "yellow" },
          { pattern = "插入",   icon = "\u{f877}", color = "yellow" },
          { pattern = "修改",   icon = "󰏬", color = "orange" },
          { pattern = "匹配括号", icon = "\u{f121}", color = "blue" },
          { pattern = "滚",     icon = "\u{f07e}", color = "cyan" },
          { pattern = "显示行", icon = "\u{f06e}", color = "azure" },
          { pattern = "行尾",   icon = "\u{f07e}", color = "azure" },
          { pattern = "合并",   icon = "\u{f066}", color = "cyan" },
          { pattern = "交换",   icon = "\u{f0ec}", color = "cyan" },
          { pattern = "轮换",   icon = "\u{f074}", color = "cyan" },
          { pattern = "移到",   icon = "\u{f047}", color = "cyan" },
          { pattern = "符号",   icon = "\u{f022}", color = "violet" },
          { pattern = "作用域", icon = "\u{f047}", color = "cyan" },
          { pattern = "切换",   icon = "\u{f205}", color = "green" },      -- toggle 开关
          -- 方向词最泛化，放最后兜底
          { pattern = "下一个",   icon = "\u{f0054}", color = "azure" },
          { pattern = "上一个",   icon = "\u{f0040}", color = "azure" },
          { pattern = "最后一个", icon = "\u{f0054}", color = "azure" },
          { pattern = "第一个",   icon = "\u{f0040}", color = "azure" },
        } or nil,
        keys = not icons and { Space = "空格", C = "Ctrl-", M = "Alt-", S = "Shift-" } or nil,
      },
      spec = {
        { "<leader>b", group = "缓冲区" }, { "<leader>c", group = "代码" },
        { "<leader>d", group = "诊断" }, { "<leader>f", group = "查找" },
        { "<leader>g", group = "Git" }, { "<leader>h", group = "改动块" },
        { "<leader>n", group = "终端与通知" }, { "<leader>t", group = "切换" },
        { "<leader>r", group = "重命名" }, { "<leader>p", group = "网页预览" },
        { "<leader>z", group = "代码折叠" }, -- 暂停在空格 z 可查看折叠和展开操作。
        -- Neovim 内置键位的中文描述（纯显示覆盖，不改变按键行为）：
        -- ] = 下一个系列，[ = 上一个系列；插件已注册中文 desc 的键位优先显示
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
        -- g 前缀：跳转 / 操作（挂 LSP 的 buffer 里 gd/gi/gD/gr 等优先显示 LSP 描述）
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
      },
    },
  },
  {
    -- 保留上游状态栏中的 Git、诊断和 LSP；文件名旁清楚区分已修改、只读及新建状态。
    "nvim-lualine/lualine.nvim", event = "VeryLazy",
    opts = {
      options = {
        theme = "auto", globalstatus = true, icons_enabled = icons,
        component_separators = "", section_separators = "",
        disabled_filetypes = { statusline = { "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { "mode" }, lualine_b = { "branch", "diff" },
        lualine_c = { { "filename", path = 1, symbols = { modified = "[+]", readonly = "[只读]", unnamed = "[无标题]", newfile = "[新建]" } } },
        lualine_x = {
          { "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
          { "lsp_status", icon = "", symbols = { done = "" }, cond = function() return vim.o.columns >= 100 end },
        },
        lualine_y = { "filetype" }, lualine_z = { "location" },
      },
    },
  },
}
