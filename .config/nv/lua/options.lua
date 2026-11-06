-- 编辑器基础选项（vim.opt 集中放这里）
local opt = vim.opt

-- 行号与相对行号
opt.number = true
opt.relativenumber = false

-- 交互
opt.mouse = "a"
opt.showmode = false -- 状态栏插件会显示模式
opt.clipboard = "unnamedplus" -- 系统剪贴板
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
