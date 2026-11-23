return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- 尽早加载，避免启动闪白
		lazy = false,
		opts = {
			flavour = "mocha", -- 与 NvChad 一致：base46 内置的 catppuccin 就是 Mocha（深色变体）
			transparent_background = true, -- 与 NvChad 一致：不画编辑区底色，透出终端背景，消除终端 padding 的「缝隙」
			-- 对齐 NvChad base46 的配色细节（base46 是定制版 Mocha，注释比官方更暗）
			custom_highlights = function()
				return {
					ColorColumn = { bg = "#45405e" }, -- 低饱和深紫色列参考线，呼应 Mocha 的 mauve
					NeoTreeDirectoryIcon = { fg = "#cba6f7" },
					NeoTreeDirectoryName = { fg = "#cdd6f4" },
					NeoTreeRootName = { fg = "#cba6f7", bold = true },
					NeoTreeExpander = { fg = "#cba6f7" },
					NeoTreeIndentMarker = { fg = "#585b70" },
					NeoTreeCursorLine = { bg = "#45405e" },
					NeoTreeEndOfBuffer = { fg = "#313244", bg = "NONE" },
					WhichKeyNormal = { bg = "#242334" },
					WhichKeyBorder = { fg = "#cba6f7", bg = "#242334" },
					WhichKeyTitle = { fg = "#cba6f7", bg = "#242334", bold = true },
					WhichKey = { fg = "#cba6f7", bold = true },
					WhichKeyGroup = { fg = "#b4befe" },
					WhichKeyDesc = { fg = "#cdd6f4" },
					WhichKeySeparator = { fg = "#6c7086" },
					Comment = { fg = "#605f6f" }, -- 注释：base46 的 light_grey，比官方 overlay0 更暗
					["@comment"] = { fg = "#605f6f" }, -- treesitter 语法组，同上
				}
			end,
			integrations = {
				blink_cmp = true,
				fzf = true,
				gitsigns = true,
				mason = true,
				native_lsp = {
					enabled = true,
					underlines = { errors = { "undercurl" }, warnings = { "undercurl" } },
				},
				snacks = true,
				treesitter = true,
				which_key = true,
				noice = true, -- noice 弹窗也跟随主题配色
				lualine = true, -- 状态栏跟随主题配色
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
