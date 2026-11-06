-- ============================================================
--  lualine 状态栏：布局照抄 NvChad（mode file git │ diag lsp cwd cursor）
--  配色手写 Catppuccin Mocha，因为官方 lualine 主题只定义了 a/b/c 三段，
--  右侧 x/y/z 没有底色，会导致右半边一片纯黑、看起来「像默认状态栏」。
-- ============================================================

-- Catppuccin Mocha 调色板（显式写出，不依赖主题内部 API）
local M = {
	base = "#1e1e2e", -- 最深的底色
	surface0 = "#313244", -- 浅一层的块底色
	surface1 = "#45475a", -- 再浅一层
	text = "#cdd6f4", -- 主文字色
	subtext0 = "#a6adc8", -- 次要文字色
	blue = "#89b4fa", -- 常规模式强调色
	green = "#a6e3a1", -- 插入模式强调色
	mauve = "#cba6f7", -- 可视模式强调色
	red = "#f38ba8", -- 替换模式强调色
	yellow = "#f9e2af", -- 命令模式强调色
	teal = "#94e2d5", -- 终端模式强调色
}

-- 按模式生成六段配色：a=模式块 b=分支段 c=文件名段 x/y=右侧信息段 z=位置段
local function mode_theme(accent)
	return {
		a = { bg = accent, fg = M.base, gui = "bold" }, -- 模式：强调色底 + 深色字
		b = { bg = M.surface0, fg = accent }, -- 分支/改动：浅块底 + 强调色字
		c = { bg = M.surface1, fg = M.text }, -- 文件名：更浅的块底 + 主文字色
		x = { bg = M.surface0, fg = M.subtext0 }, -- 右侧信息段（诊断/LSP/项目名）
		y = { bg = M.surface0, fg = M.subtext0 }, -- 右侧过渡段
		z = { bg = accent, fg = M.base, gui = "bold" }, -- 行:列：强调色块收尾
	}
end

local theme = {
	normal = mode_theme(M.blue), -- 常规模式
	insert = mode_theme(M.green), -- 插入模式
	visual = mode_theme(M.mauve), -- 可视模式
	replace = mode_theme(M.red), -- 替换模式
	command = mode_theme(M.yellow), -- 命令模式
	terminal = mode_theme(M.teal), -- 终端模式
	inactive = { -- 非活动窗口：全部用低对比的灰块
		a = { bg = M.surface0, fg = M.subtext0 },
		b = { bg = M.surface0, fg = M.subtext0 },
		c = { bg = M.surface1, fg = M.subtext0 },
		x = { bg = M.surface0, fg = M.subtext0 },
		y = { bg = M.surface0, fg = M.subtext0 },
		z = { bg = M.surface0, fg = M.subtext0 },
	},
}

return {
	{
		"nvim-lualine/lualine.nvim", -- 底部状态栏插件
		event = "VeryLazy", -- 启动后空闲时加载，不拖慢启动速度
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- 文件类型图标库（filename 组件显示图标用）
		},
		opts = {
			options = {
				theme = theme, -- 用上面手写的 Mocha 配色（六段都有底色）
				globalstatus = true, -- 全局状态栏：整个屏幕只保留一条
				component_separators = { left = "", right = "" }, -- 组件之间的分隔符（细竖线）
				section_separators = { left = "", right = "" }, -- 区块之间的分隔符（实心三角）
				disabled_filetypes = { -- 这些文件类型不显示状态栏
					statusline = { "dashboard", "alpha", "snacks_dashboard" }, -- 启动仪表盘不显示
					winbar = {}, -- 顶部窗口栏（没启用，留空）
				},
			},
			-- 布局照抄 NvChad：mode file git │ lsp_msg diagnostics lsp cwd cursor
			sections = {
				lualine_a = { "mode" }, -- 最左：当前模式
				lualine_b = { "branch", "diff" }, -- 左二：git 分支 + 增删改统计
				lualine_c = { -- 左三：文件名
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
				lualine_x = { -- 右侧第一组：诊断 + LSP + 项目名
					{
						"diagnostics", -- 诊断数量
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
						show_name = true, -- 显示客户端名（如 vue_ls / vtsls）
						symbols = {
							spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- 加载动画
							done = "", -- 加载完成标记
						},
					},
					{
						function() return vim.fn.fnamemodify(vim.fn.getcwd(), ":t") end, -- 取当前目录最后一段作为项目名
						icon = "", -- 文件夹图标
					},
				},
				lualine_y = {}, -- 右二：留空（NvChad 没有百分比段）
				lualine_z = { "location" }, -- 最右：行:列
			},
			extensions = {
				"quickfix", "mason", "lazy",
				{
					filetypes = { "neo-tree" },
					sections = {
						lualine_a = { { function() return "文件树" end, color = { fg = M.base, bg = M.mauve } } },
						lualine_b = {},
						lualine_c = { function() return vim.fn.fnamemodify(vim.fn.getcwd(), ":t") end },
						lualine_x = {}, lualine_y = {}, lualine_z = {},
					},
				},
			},
		},
	},
}
