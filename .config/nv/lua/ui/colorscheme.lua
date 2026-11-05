return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- 尽早加载，避免启动闪白
		lazy = false,
		opts = {
			flavour = "frappe", -- latte / frappe / macchiato / mocha
			transparent_background = false, -- 关掉透明：避免终端底色透上来，显得发灰发闷（NvChad 就是纯色底）
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
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
