return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- 尽早加载，避免启动闪白
		lazy = false,
		opts = {
			flavour = "frappe", -- latte / frappe / macchiato / mocha
			transparent_background = true,
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
