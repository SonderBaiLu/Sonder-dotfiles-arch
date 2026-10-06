-- ============================================================
-- 插件配置入口
-- ============================================================
-- 这里的插件声明会和 NvChad 内置的(nvchad/plugins/init.lua)按插件名合并:
-- 同名插件的 opts 做深度合并,本文件的优先级更高(后导入覆盖同名键)。
return {
	{
		"stevearc/conform.nvim",
		-- event = 'BufWritePre', -- uncomment for format on save
		opts = require "configs.conform",
	},

	{
		"neovim/nvim-lspconfig",
		config = function()
			require "configs.lspconfig"
		end,
	},

	-- ------------------------------------------------------------
	-- 语法高亮(treesitter)
	-- ------------------------------------------------------------
	-- treesitter 用「真正的语法树」做高亮,比老式正则高亮准确得多。
	-- 每种语言需要一个 parser(解析器),下面的清单决定装哪些。
	-- 安装时机:打开 nvim 后执行 :TSInstallAll(NvChad 提供的命令),
	-- parser 会联网下载并编译(需要系统装有 gcc/make)。
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			-- ⚠ lazy.nvim 合并 opts 时,列表是「按下标覆盖」而不是拼接!
			-- NvChad 默认装 { "lua", "luadoc", "printf", "vim", "vimdoc" }:
			-- 如果这里只写新增的 8 个,会按下标把默认的前 8 个顶掉
			-- (lua 会被 rust 覆盖、vim 会被 css 覆盖……)。
			-- 所以必须把「默认 + 新增」完整地写在一起:
			ensure_installed = {
				-- NvChad 默认项(删掉会破坏其自带功能:lua 高亮、帮助文档等)
				"lua",
				"luadoc",
				"printf",
				"vim",
				"vimdoc",
				-- 本配置新增的语言
				"rust",
				"vue",
				"typescript",
				"javascript",
				"html",
				"css",
				"yaml",
				"sql",
			},
		},
	},
}
