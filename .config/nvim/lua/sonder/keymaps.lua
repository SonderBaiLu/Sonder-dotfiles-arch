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

-- 内置键位描述汉化：Neovim 0.12 给 LSP / 诊断 / quickfix / 树节点等内置功能注册了
-- 带英文描述的真实映射，matchit 等运行时插件也会注册无描述的映射，快捷键看板里显示英文。
-- 这里取出原映射的实现重新注册，只换中文描述，行为完全不变。
-- 触发时机：真实使用走 VimEnter；--headless（无 UI）不触发 VimEnter，用延迟执行兜底。
local function apply_cn()
  local function cn(modes, lhs, desc)
      for _, mode in ipairs(type(modes) == "table" and modes or { modes }) do
        local m = vim.fn.maparg(lhs, mode, false, true)
        if m and not vim.tbl_isempty(m) then
          if m.callback then
            vim.keymap.set(mode, lhs, m.callback, { desc = desc })
          elseif m.rhs and m.rhs ~= "" then
            vim.keymap.set(mode, lhs, m.rhs, { desc = desc })
          end
        end
      end
    end

    -- 括号 / 替换 / 复制 / 空行
    cn({ "n", "x" }, "%", "匹配括号")
    cn("n", "g%", "反向匹配括号")
    cn("n", "&", "重复上次替换")
    cn("n", "Y", "复制到行尾")
    cn("n", "[%", "上一个未匹配括号")
    cn("n", "]%", "下一个未匹配括号")
    cn("x", "[%", "上一个未匹配括号")
    cn("x", "]%", "下一个未匹配括号")
    cn("n", "[ ", "上方插入空行")
    cn("n", "] ", "下方插入空行")

    -- 缓冲区跳转
    cn("n", "[b", "上一个缓冲区")
    cn("n", "]b", "下一个缓冲区")
    cn("n", "[B", "第一个缓冲区")
    cn("n", "]B", "最后一个缓冲区")

    -- 参数列表跳转
    cn("n", "[a", "上一个参数文件")
    cn("n", "]a", "下一个参数文件")
    cn("n", "[A", "第一个参数文件")
    cn("n", "]A", "最后一个参数文件")

    -- quickfix 修复列表
    cn("n", "[q", "上一个修复项")
    cn("n", "]q", "下一个修复项")
    cn("n", "[Q", "第一个修复项")
    cn("n", "]Q", "最后一个修复项")
    cn("n", "[<C-Q>", "上一个修复文件")
    cn("n", "]<C-Q>", "下一个修复文件")

    -- 位置列表
    cn("n", "[l", "上一个位置项")
    cn("n", "]l", "下一个位置项")
    cn("n", "[L", "第一个位置项")
    cn("n", "]L", "最后一个位置项")
    cn("n", "[<C-L>", "上一个位置文件")
    cn("n", "]<C-L>", "下一个位置文件")

    -- 标签跳转
    cn("n", "[T", "第一个标签")
    cn("n", "]T", "最后一个标签")
    cn("n", "[<C-T>", "上一个预览标签")
    cn("n", "]<C-T>", "下一个预览标签")

    -- 诊断跳转
    cn("n", "[d", "上一个诊断")
    cn("n", "]d", "下一个诊断")
    cn("n", "[D", "第一个诊断")
    cn("n", "]D", "最后一个诊断")
    cn("n", "<C-W>d", "悬浮诊断详情")
    cn("n", "<C-W><C-D>", "悬浮诊断详情")

    -- LSP 默认键位
    cn("n", "gO", "文档符号列表")
    cn("n", "grt", "转到类型定义")
    cn("n", "gri", "转到实现")
    cn("n", "grr", "查找引用")
    cn("n", "grx", "运行代码镜头")
    cn({ "n", "x" }, "gra", "代码操作")
    cn("n", "grn", "重命名符号")

    -- 注释与打开链接
    cn({ "n", "x" }, "gcc", "注释/取消当前行")
    cn({ "n", "x" }, "gc", "注释操作符")
    cn({ "n", "x" }, "gx", "打开光标下链接")

    -- 插入模式内置键位
    cn("i", "<C-S>", "签名帮助")
    cn("i", "<Tab>", "跳到下一个占位符")
    cn("i", "<S-Tab>", "跳到上一个占位符")
    cn("i", "<C-W>", "删除光标前一词")
    cn("i", "<C-U>", "删除到行首")

    -- 可视模式内置键位
    cn("x", "#", "查找光标词(向上)")
    cn("x", "*", "查找光标词(向下)")
    cn("x", "@", "对选区执行宏")
    cn("x", "Q", "重复命令作用于选区")
    cn("s", "<Tab>", "跳到下一个占位符")
    cn("s", "<S-Tab>", "跳到上一个占位符")
    cn("s", "<C-S>", "签名帮助")

    -- 树节点选择（0.12 内置 treesitter 增选）
    cn("x", "[n", "上一个节点")
    cn("x", "]n", "下一个节点")
    cn("x", "[N", "上一个兄弟节点")
    cn("x", "]N", "下一个兄弟节点")
    cn("x", "an", "外层节点增选")
    cn("x", "in", "内层节点增选")
    cn("x", "a%", "外层匹配块")
    cn("x", "g%", "反向匹配括号")
end

vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = apply_cn })
-- matchit 等运行时插件是延迟加载的，启动几秒后会重新注册映射盖掉中文描述，
-- 这里分多轮幂等重跑兜底；真实使用走 VimEnter 时插件已加载完毕，一轮即可。
vim.defer_fn(apply_cn, 1500)
vim.defer_fn(apply_cn, 4500)
vim.defer_fn(apply_cn, 9000)
