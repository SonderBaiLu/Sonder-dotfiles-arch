-- ============================================================
-- AI 补全(minuet-ai.nvim + DeepSeek FIM)
-- ============================================================
-- 为什么选这个组合:
--   minuet 把「大语言模型」变成 nvim 的补全引擎,以幽灵文本
--   (ghost text,灰色半透明建议)的形式展示,按快捷键接受 ——
--   体验和 Copilot / IDEA 的整行补全一致。
--   DeepSeek 的 FIM(Fill-In-the-Middle,中间补全)接口专为代码
--   补全设计:模型只看光标前后的代码,补出光标处缺失的部分,
--   比 chat 接口快得多、便宜得多,质量也更好。
--
-- 与 LSP 的分工(重要概念):LSP(rust_analyzer / vtsls 等)给的是
-- 「语义正确」的补全 —— 当前项目里真实存在的符号;AI 给的是
-- 「联想」—— 整行、整块地生成代码。两者并存,互不干扰:
-- nvim-cmp 弹出菜单时幽灵文本会自动隐藏,语义补全优先。
--
-- 使用方式:
--   在支持的语言里打字停顿约半秒 → 出现灰色建议
--   <A-A>(Alt+Shift+A)接受整段,<A-a>(Alt+A)只接受一行
--   <A-]> / <A-[> 换候选,<A-e> 关掉当前建议
--   手动开关本缓冲区的自动建议 → :Minuet virtualtext toggle
--
-- 前置条件:环境变量 DEEPSEEK_API_KEY 里放好你的密钥
-- (fish:在 ~/.config/fish/config.fish 里加
--   set -gx DEEPSEEK_API_KEY "sk-你的密钥" )
-- 注册地址:https://platform.deepseek.com(充几块钱能用很久)
return {
	"milanglacier/minuet-ai.nvim",
	event = "InsertEnter", -- 进入插入模式才加载,平时不占启动时间
	config = function()
		require("minuet").setup({
			-- FIM 模式:不经过 chat,直接走 DeepSeek 的中间补全接口,
			-- 延迟低,是最适合「打字时联想」的形态
			provider = "openai_fim_compatible",
			provider_options = {
				openai_fim_compatible = {
					-- DeepSeek 的中间补全目前是 beta 接口,端点和普通
					-- chat 接口不同,必须显式指向 /beta/completions
					end_point = "https://api.deepseek.com/beta/completions",
					-- 注意:这里写环境变量的「名字」而不是密钥本身,
					-- minuet 会运行时读取 —— 配置文件里不落任何密钥
					api_key = "DEEPSEEK_API_KEY",
					model = "deepseek-chat",
					name = "deepseek",
					optional = {
						max_tokens = 256, -- 建议长度上限:太长会更慢,256 平衡点
						top_p = 0.9,
					},
				},
			},
			-- FIM 一次只生成一个延续,多候选纯浪费时间和 token
			n_completions = 1,
			virtualtext = {
				-- 只在这些语言里「打字自动触发」AI 建议;
				-- 想临时开关某个缓冲区::Minuet virtualtext toggle
				-- 想彻底关掉自动触发:把这个列表清空 {},改用 <A-y>? 手动触发
				auto_trigger_ft = {
					"rust",
					"vue",
					"typescript",
					"typescriptreact",
					"javascript",
					"javascriptreact",
					"html",
					"css",
					"yaml",
					"lua",
				},
				keymap = {
					-- 默认所有键为空(nil),官方示例给的就是下面这套 Alt 系,
					-- 与 NvChad 已占用的 <A-v>/<A-h>/<A-i> 不冲突
					accept = "<A-A>", -- Alt+Shift+A:接受整段建议
					accept_line = "<A-a>", -- Alt+A:只接受一行
					accept_n_lines = "<A-z>", -- 接受 n 行(会弹询问)
					next = "<A-]>", -- 下一个候选
					prev = "<A-[>", -- 上一个候选
					dismiss = "<A-e>", -- 关掉当前建议
				},
			},
		})
	end,
}
