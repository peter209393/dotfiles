return {
	{
		"lervag/vimtex",
		lazy = false, -- VimTeX recommends not lazy-loading
		init = function()
			vim.g.vimtex_view_method = "zathura_simple" -- Wayland: xdotool unavailable, use simple variant
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_quickfix_mode = 0
			vim.g.vimtex_fold_enabled = 1
			vim.g.tex_flavor = "latex"
		end,
	},
}
