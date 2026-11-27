-- 编辑器基础选项（vim.opt 集中放这里）
local opt = vim.opt

-- 打开文件时显示全部代码，折叠层级由用户在当前窗口按需调整。
opt.foldlevelstart = 99

-- 行号与相对行号
opt.number = true
opt.relativenumber = false

-- 交互
opt.mouse = "a"
opt.showmode = false -- 状态栏插件会显示模式
-- 有系统剪贴板提供程序时才共享寄存器，纯 SSH / 无桌面环境仍可正常复制粘贴。
if vim.fn.has("clipboard") == 1 then opt.clipboard = "unnamedplus" end
opt.termguicolors = true

-- 缩进
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- 显示
opt.signcolumn = "yes"
opt.cursorline = true
opt.colorcolumn = "88" -- 行长度参考线，只做视觉提示，不自动换行
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.winblend = 0

-- 搜索
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.inccommand = "split"

-- 补全
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10

-- 历史与持久化
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- 响应速度
opt.updatetime = 250
opt.timeoutlen = 300

-- 分割窗口方向
opt.splitright = true
opt.splitbelow = true

-- 浮窗统一圆角边框（补全菜单、文档浮窗、lazygit 等都会用上）
opt.winborder = "rounded"

-- 文件树、状态栏、补全和诊断共用图标开关。临时使用普通字体时可设 SONDER_NERD_FONT=0。
vim.g.sonder_nerd_font = vim.env.SONDER_NERD_FONT ~= "0"
local icons = vim.g.sonder_nerd_font and { "󰅗", "󰀧", "󰬐", "󰞋" } or { "E", "W", "I", "H" }
vim.diagnostic.config({
  virtual_text = false, virtual_lines = { current_line = true }, underline = true,
  signs = { text = icons }, severity_sort = true, update_in_insert = false,
})

-- Markdown 和纯文本文档按单词折行，中文写作时 j/k 按屏幕行移动，带计数仍按实际行移动。
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("SonderWriting", { clear = true }),
  pattern = { "markdown", "text" },
  callback = function(ev)
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.colorcolumn = ""
    vim.opt_local.formatoptions:remove("t") -- 只改变显示，不插入硬换行。
    for _, key in ipairs({ "j", "k" }) do
      vim.keymap.set({ "n", "x" }, key, function()
        return vim.v.count == 0 and "g" .. key or key
      end, { buffer = ev.buf, expr = true, desc = key == "j" and "下移显示行" or "上移显示行" })
    end
  end,
})
