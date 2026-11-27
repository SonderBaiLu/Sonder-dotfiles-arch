-- 核心键位（只用内置功能，不依赖插件）
-- 各插件的键位随其配置声明，空格加问号可查看当前缓冲区的完整映射。
local map = vim.keymap.set

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 退出插入模式更顺滑
map("i", "jk", "<Esc>", { desc = "退出插入模式" })

-- 窗口移动（Ctrl+hjkl）
map("n", "<C-h>", "<C-w>h", { desc = "左窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "下窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "上窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "右窗口" })

-- 调整窗口大小
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "增高" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "降低" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "变窄" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "变宽" })

-- 移动行（Alt+j/k）
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "下移行" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "上移行" })
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "下移行" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "上移行" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "下移选区" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "上移选区" })

-- 缩进保持选中
map("v", "<", "<gv", { desc = "左缩进" })
map("v", ">", ">gv", { desc = "右缩进" })

-- 缓冲区切换
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "下一个缓冲区" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "上一个缓冲区" })

-- 清除搜索高亮
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "清除搜索高亮" })

-- 拼接行不移动光标
map("n", "J", "mzJ`z", { desc = "拼接行（保持光标）" })

-- 翻页保持居中
map("n", "<C-d>", "<C-d>zz", { desc = "下半屏" })
map("n", "<C-u>", "<C-u>zz", { desc = "上半屏" })
-- 搜索后自动展开目标折叠并居中；Vim 自带的计数仍然有效。
map("n", "n", "nzzzv", { desc = "下一个匹配并居中" })
map("n", "N", "Nzzzv", { desc = "上一个匹配并居中" })

-- 普通模式用空格 z 管理当前窗口的折叠；小写处理光标处，大写处理整个文件。
-- 直接映射到内置 z 命令，保留计数前缀，也可以继续使用原始键位。
map("n", "<leader>za", "za", { desc = "切换当前代码块折叠" })
map("n", "<leader>zc", "zc", { desc = "折叠当前代码块" })
map("n", "<leader>zo", "zo", { desc = "展开当前代码块" })
map("n", "<leader>zM", "zM", { desc = "折叠全部代码块" })
map("n", "<leader>zR", "zR", { desc = "展开全部代码块" })

-- 保存 / 退出
map("n", "<leader>w", "<cmd>w<CR>", { desc = "保存" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "退出" })
