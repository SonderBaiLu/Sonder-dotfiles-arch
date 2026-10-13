-- ============================================================
-- Markdown 增强:实时渲染预览(render-markdown.nvim)
-- ============================================================
-- 这个插件把「实时预览」直接做在 nvim 缓冲区里(不开浏览器):
-- 边写边渲染 —— 标题变粗变大、**加粗** 直接显示成粗体、
-- - [ ] 变可勾选的复选框、代码块加边框、链接变色高亮,所见即所得。
--
-- 为什么不选 markdown-preview.nvim(浏览器预览)?
--   1. 纯 Lua + treesitter 实现,不联网、不依赖浏览器/Node;
--      正好绕开这台机器 npmjs.org 被墙的环境
--   2. 在当前缓冲区渲染,和透明背景、Hyprland 工作流都不冲突
--   3. 写和看是同一份文本,不用在两个窗口间来回切
--
-- 依赖 treesitter 的 markdown / markdown_inline 解析器
-- (已在 plugins/init.lua 的 ensure_installed 声明,装完记得 :TSInstallAll)。
return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		-- 只在打开 .md 文件时加载,不拖慢其他语言的启动
		ft = { "markdown" },
		-- 快捷键:写看分离的预览窗口。
		-- render-markdown 默认是「内联渲染」—— 把渲染效果直接叠在正在编辑的
		-- 文本上,写的时候(插入模式)回到源码、切回普通模式又突然渲染,来回跳,
		-- 阅读时虚拟文字一多还容易对不齐。所以更舒服的用法是:
		--   <leader>mp 开一个只读预览窗(右分屏),左边源码写、右边实时渲染,
		--   光标和滚动双向同步;再按一次关闭。
		-- ft = "markdown" 让这个映射只在 .md 缓冲区生效,其他文件里不占按键。
		keys = {
			{ "<leader>mp", "<cmd>RenderMarkdown preview<CR>", ft = "markdown", desc = "Markdown 预览(写看分离)" },
		},
		-- 声明依赖,保证 treesitter 先加载(解析器由它的 ensure_installed 装)
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		-- opts 留空 = 用插件默认配置,默认已开启:标题样式、粗/斜体、内联代码、
		-- 代码块边框、复选框、链接高亮。不写重复的默认值,想微调时再加。
		opts = {},
	},
}
