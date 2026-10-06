-- ============================================================
-- 格式化配置(conform.nvim)
-- ============================================================
-- conform 负责「代码格式化」:按 <leader>fm(NvChad 默认键位)手动触发;
-- 想要保存时自动格式化,打开下方 format_on_save 的注释即可。
--
-- 和 LSP 的分工:LSP 也"会"格式化,但专业格式化器更快、规则更统一。
-- lsp_fallback = true 的含义:某语言没有在本表声明格式化器时,
-- 才退回使用 LSP 自带的格式化能力。
--
-- 这些格式化器怎么安装?不用手动装 —— :MasonInstallAll 会收集本表
-- 出现过的格式化器名并自动安装(stylua/prettier/sqlfmt 都在 mason 里;
-- rustfmt 是唯一例外:mason 已废弃该包,它随 rustup 自带,见 rust 条目注释)。
local options = {
	formatters_by_ft = {
		-- Lua:NvChad 官方选择,nvim 配置文件本身也用它格式化
		lua = { "stylua" },

		-- Rust:官方唯一格式化器;rustup 装工具链时已自带,无需 mason
		rust = { "rustfmt" },

		-- Web 全家桶统一用 prettier:一个工具覆盖 js/ts/vue/css/html/yaml/json,
		-- 规则一致、可用项目里的 .prettierrc 定制,比每语言各装一个更省心
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		vue = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		yaml = { "prettier" },
		json = { "prettier" },

		-- SQL:选 sqlfmt 因为它零配置可用;
		-- 另一个常见选择 sqlfluff 功能更强,但必须配置方言(dialect)才能运行
		sql = { "sqlfmt" },
	},

	-- 想要「保存时自动格式化」就取消下面的注释:
	-- format_on_save = {
	-- 	-- 传给 conform.format() 的参数
	-- 	timeout_ms = 500, -- 单次格式化最多等 500ms,防止大文件卡住保存
	-- 	lsp_fallback = true, -- 没有专用格式化器时退回 LSP
	-- },
}

return options
