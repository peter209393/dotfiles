return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	branch = "main",
	build = ":TSUpdate",
	config = function()
		local ensure_installed = {
			"c3",
			"zig",
			"php",
			"rust",
			"vimdoc",
			"javascript",
			"typescript",
			"c",
			"go",
			"lua",
			"jsdoc",
			"bash",
			"css",
			"kotlin",
		}

		local patterns = {
			"c3",
			"zig",
			"php",
			"rust",
			"vimdoc",
			"javascript",
			"typescript",
			"c",
			"go",
			"lua",
			"jsdoc",
			"bash",
			"css",
			"kotlin",
		}

		-- nvim-treesitter main branch requires the tree-sitter CLI to build parsers.
		-- Only attempt installation when the CLI is available to avoid startup errors.
		if vim.fn.executable("tree-sitter") == 1 then
			require("nvim-treesitter").install(ensure_installed)
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = patterns,
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})
	end,
}
