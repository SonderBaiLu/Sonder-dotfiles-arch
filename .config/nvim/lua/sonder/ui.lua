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
      win = { border = "rounded", padding = { 1, 2 }, wo = { winblend = 0 } },
      icons = { mappings = icons, keys = not icons and { Space = "空格", C = "Ctrl-", M = "Alt-", S = "Shift-" } or nil },
      spec = {
        { "<leader>b", group = "缓冲区" }, { "<leader>c", group = "代码" },
        { "<leader>d", group = "诊断" }, { "<leader>f", group = "查找" },
        { "<leader>g", group = "Git" }, { "<leader>h", group = "改动块" },
        { "<leader>n", group = "终端与通知" }, { "<leader>t", group = "切换" },
        { "<leader>r", group = "重命名" }, { "<leader>p", group = "网页预览" },
        { "<leader>z", group = "代码折叠" }, -- 暂停在空格 z 可查看折叠和展开操作。
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
