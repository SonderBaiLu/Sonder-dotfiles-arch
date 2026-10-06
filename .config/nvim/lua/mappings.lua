-- 快捷键配置
-- 第一行加载 NvChad 的全部内置快捷键(leader 键默认是空格):
--   - 普通模式下按「空格」稍等,which-key 会弹出快捷键菜单
--   - 按 <leader>ch 可打开 NvChad 的全屏速查表(会显示本文件的中文描述)
require "nvchad.mappings"

local map = vim.keymap.set
-- 给 <leader> 分组起中文名(which-key 的 +N keymaps 会变成这些名字)
require("which-key").add {
  { "<leader>f", group = "查找" },
  { "<leader>w", group = "工作目录/帮助" },
  { "<leader>r", group = "行号与重命名" },
  { "<leader>c", group = "速查/Git" },
  { "<leader>m", group = "标记/Mason" },
  { "<leader>l", group = "LSP操作" },
}

-- ------------------------------------------------------------
-- 一、自己的基础快捷键
-- ------------------------------------------------------------
map("n", ";", ":", { desc = "进入命令行模式" })
map("i", "jk", "<Esc>", { desc = "退出插入模式" })
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "打开/关闭文件树" })
-- ------------------------------------------------------------
-- 二、汉化:NvChad 内置快捷键的描述
-- ------------------------------------------------------------
-- 原理:用 vim.fn.maparg() 读出原映射的「目标(rhs/回调)」,
--       然后原样重新注册一遍,只把描述(desc)换成中文。
-- 好处:功能完全由 NvChad 决定,这里只负责翻译 —— NvChad 升级改了行为,
--       这里自动跟随,不需要维护两份实现;删掉某条翻译也不影响功能。
local function zh(mode, lhs, desc)
  local old = vim.fn.maparg(lhs, mode, false, true)

  -- 原映射不存在(可能 NvChad 改版移除了),静默跳过,不报错
  if not old or vim.tbl_isempty(old) then
    return
  end
  -- 只处理全局映射;缓冲区本地的(如 LSP 的 gd)在 lspconfig.lua 里汉化
  if old.buffer and old.buffer ~= 0 then
    return
  end

  vim.keymap.set(mode, lhs, old.callback or old.rhs, {
    desc = desc,
    silent = old.silent == 1,
    expr = old.expr == 1,
    nowait = old.nowait == 1,
    remap = old.noremap ~= 1, -- 原映射若允许再次映射(如 gcc),保留该特性
  })
end

-- 【插入模式】emacs 风格的光标移动
zh("i", "<C-b>", "移动到行首")
zh("i", "<C-e>", "移动到行尾")
zh("i", "<C-h>", "光标左移")
zh("i", "<C-l>", "光标右移")
zh("i", "<C-j>", "光标下移")
zh("i", "<C-k>", "光标上移")

-- 【普通模式】窗口与基础操作
zh("n", "<C-h>", "切换到左边的窗口")
zh("n", "<C-l>", "切换到右边的窗口")
zh("n", "<C-j>", "切换到下边的窗口")
zh("n", "<C-k>", "切换到上边的窗口")
zh("n", "<Esc>", "清除搜索高亮")
zh("n", "<C-s>", "保存文件")
zh("n", "<C-c>", "复制整个文件")

-- 【普通模式】显示与格式化
zh("n", "<leader>n", "切换行号显示")
zh("n", "<leader>rn", "切换相对行号")
zh("n", "<leader>ch", "打开 NvChad 速查表")
zh("n", "<leader>fm", "格式化当前文件")
zh("x", "<leader>fm", "格式化当前文件")

-- 【普通模式】诊断(LSP 报错)
zh("n", "<leader>ds", "打开诊断列表(当前文件的问题)")

-- 【普通模式】缓冲区(标签栏)管理
zh("n", "<leader>b", "新建缓冲区")
zh("n", "<Tab>", "下一个缓冲区")
zh("n", "<S-tab>", "上一个缓冲区")
zh("n", "<leader>x", "关闭当前缓冲区")

-- 【普通/可视模式】注释
zh("n", "<leader>/", "切换注释")
zh("v", "<leader>/", "切换注释")

-- 【普通模式】telescope 模糊查找
zh("n", "<leader>ff", "按名称查找文件")
zh("n", "<leader>fa", "查找所有文件(含隐藏/被忽略的)")
zh("n", "<leader>fw", "全局搜索文本")
zh("n", "<leader>fb", "列出已打开的缓冲区")
zh("n", "<leader>fh", "搜索帮助文档")
zh("n", "<leader>ma", "查找标记(marks)")
zh("n", "<leader>fo", "最近打开的文件")
zh("n", "<leader>fz", "在当前文件内搜索")
zh("n", "<leader>cm", "查看 git 提交历史")
zh("n", "<leader>gt", "查看 git 改动状态")
zh("n", "<leader>pt", "选择隐藏的终端")
zh("n", "<leader>th", "打开主题选择器")

-- 【终端/普通模式】终端管理
zh("t", "<C-x>", "退出终端模式")
zh("n", "<leader>h", "新建水平分屏终端")
zh("n", "<leader>v", "新建垂直分屏终端")
zh("n", "<A-v>", "切换垂直终端")
zh("t", "<A-v>", "切换垂直终端")
zh("n", "<A-h>", "切换水平终端")
zh("t", "<A-h>", "切换水平终端")
zh("n", "<A-i>", "切换悬浮终端")
zh("t", "<A-i>", "切换悬浮终端")

-- 【普通模式】which-key
zh("n", "<leader>wK", "显示全部快捷键")
zh("n", "<leader>wk", "查询某个前缀的快捷键")

-- ------------------------------------------------------------
-- 三、新增:LSP / Mason 相关
-- ------------------------------------------------------------
-- NvChad 没给这两条默认键位,补上最常用的两个入口:
map("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "查看 LSP 连接状态" })
map("n", "<leader>mm", "<cmd>Mason<CR>", { desc = "打开 Mason 包管理面板" })

-- 说明:LSP 相关快捷键(gd 跳转、<leader>ra 重命名等)是「缓冲区本地」
-- 映射,服务器连上文件才存在,所以它们的汉化放在 configs/lspconfig.lua
-- 的 LspAttach 自动命令里,时机和 NvChad 一致,才能成功覆盖。
