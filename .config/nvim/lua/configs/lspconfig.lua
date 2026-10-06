-- ============================================================
-- LSP(语言服务器)配置
-- ============================================================
-- LSP = Language Server Protocol。nvim 会在后台为每种语言启动一个
-- 「语言服务器」进程,由它提供补全、跳转定义、重命名、实时报错等智能功能。
-- 让一门语言可用分两步:
--   ① 安装服务器二进制 → mason 负责(见 chadrc.lua 与 :MasonInstallAll)
--   ② 告诉 nvim 启用哪些  → 就是本文件做的事

-- ------------------------------------------------------------
-- 0. 把 mason 的可执行目录加进 PATH
-- ------------------------------------------------------------
-- 为什么需要这行:NvChad 默认把 mason 的 PATH 设为 "skip"(不污染系统 PATH),
-- 且 mason 插件是懒加载的(只在执行 :Mason 时才启动)。这意味着普通启动的
-- nvim 会话里,mason 装的语言服务器/格式化器「找不到」,LSP 会静默失败。
-- 这里在配置加载阶段手动把目录前置到 PATH,与 NvChad 的默认值不冲突,
-- 同时保证 lspconfig 和 conform 在任何时刻都能找到 mason 安装的工具。
local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"
if not vim.env.PATH:find(mason_bin, 1, true) then
	vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

-- ------------------------------------------------------------
-- 1. 加载 NvChad 的 LSP 默认配置
-- ------------------------------------------------------------
-- 它替我们做了三件重要的事(所以不用自己写):
--   a. 给所有服务器挂上 nvim-cmp 补全需要的 capabilities(不挂则补全失效)
--   b. 注册 LspAttach 自动命令:服务器连上文件时自动绑定 gd(跳转)等快捷键
--   c. 启用并配置 lua_ls(Lua 服务器,编辑 nvim 配置本身时用)
require("nvchad.configs.lspconfig").defaults()

-- ------------------------------------------------------------
-- 2. 启用语言服务器
-- ------------------------------------------------------------
-- 注意:这里写的是 lspconfig 的服务器名(下划线),不是 mason 包名(连字符)。
-- rust_analyzer 特殊:用系统 rustup 自带的那份(见 chadrc 的 skip),
-- 其余的都由 mason 安装:mason 装好后才能启动,首次使用请先 :MasonInstallAll
local servers = { "html", "cssls", "rust_analyzer", "vue_ls", "vtsls", "unocss", "yamlls" }
-- SQL 特意没有 LSP:现有选择都不可用(sqlls 已停止维护、sqls 需要 Go 工具链、
-- sqlfluff 本身不提供 LSP)。SQL 已有 treesitter 语法高亮 + sqlfmt 格式化兜底;
-- 将来若装了 Go(pacman -S go),在上方列表加回 "sqls" 并在 chadrc 加 "sqls" 即可。

-- ------------------------------------------------------------
-- 3. Vue + TypeScript 协作配置(Vue 3 官方推荐方案)
-- ------------------------------------------------------------
-- Vue 官方语言服务器 v3.0 起改为「混合模式」(hybrid mode):
--   - vue_ls 只负责 .vue 文件里的 <template> 和 <style> 部分
--   - <script> 里的 TypeScript 交给 vtsls 处理,而 vtsls 必须挂上官方插件
--     @vue/typescript-plugin 才能理解 .vue 文件
--   - 旧教程里的 "takeover mode"(接管模式)已被官方移除,网上老方案别照抄
--
-- 插件本体随 mason 的 vue-language-server 包一起安装,这里拼出它的路径:
local vue_language_server_path = vim.fn.stdpath "data"
	.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

-- ⚠ 顺序很重要:必须先 vim.lsp.config() 写好定制配置,再 vim.lsp.enable()。
-- 因为 enable() 内部会立刻对「已打开的缓冲区」做一次回溯附加
-- (比如启动时命令行传入的那个文件),如果那时配置还没写,
-- 服务器就按默认配置判断要不要启动 —— 默认的 vtsls 不认识 .vue,
-- 结果首屏打开的 .vue 文件会缺 TypeScript 支持。
vim.lsp.config("vtsls", {
	settings = {
		vtsls = {
			tsserver = {
				globalPlugins = {
					{
						name = "@vue/typescript-plugin",
						location = vue_language_server_path, -- 必填:插件所在目录
						languages = { "vue" }, -- 必须包含 vue,即使 filetypes 里也有
						configNamespace = "typescript",
					},
				},
			},
		},
	},
	-- 默认只认 ts/js 文件;加上 "vue" 才会附加到 .vue 缓冲区上
	filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
})

vim.lsp.enable(servers)

-- ------------------------------------------------------------
-- 4. 汉化 LSP 快捷键(缓冲区本地映射)
-- ------------------------------------------------------------
-- gd 这类快捷键是 NvChad 在「LspAttach」(服务器连上文件)时才绑定的,
-- 且绑定的是缓冲区本地映射(每个文件一份)。所以汉化也要用同样的时机:
-- 我们在 defaults() 之后注册自己的 LspAttach,后注册的自动命令后执行,
-- 对同一组键重新设置即可覆盖掉英文描述(功能不变,只换描述)。
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local function opts(desc)
			return { buffer = args.buf, desc = "LSP " .. desc }
		end
		local map = vim.keymap.set

		map("n", "gd", vim.lsp.buf.definition, opts "跳转到定义")
		map("n", "gD", vim.lsp.buf.declaration, opts "跳转到声明")
		map("n", "<leader>D", vim.lsp.buf.type_definition, opts "跳转到类型定义")
		map("n", "<leader>ra", function()
			require "nvchad.lsp.renamer"
		end, opts "重命名符号(带预览)")
		map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "添加工作目录")
		map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "移除工作目录")
		map("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts "列出工作目录")
	end,
})
