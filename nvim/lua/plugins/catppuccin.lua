return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- 确保主题在其他插件之前加载
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- 可选: latte, frappe, macchiato, mocha
				transparent_background = true,
				term_colors = true,
				integrations = {
					telescope = true,
					treesitter = true,
					cmp = true,
					gitsigns = true,
					indent_blankline = {
						enabled = true,
					},
					native_lsp = {
						enabled = true,
					},
				},
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
