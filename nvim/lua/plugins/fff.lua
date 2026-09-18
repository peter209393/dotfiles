return {
	"dmtrKovalenko/fff",
	build = function()
		-- downloads a prebuilt binary or falls back to cargo build
		require("fff.download").download_or_build_binary()
	end,
	opts = {},
	lazy = false, -- the plugin lazy-initialises itself
	keys = {
		{
			"<leader>ff",
			function()
				require("fff").find_files()
			end,
			desc = "Open fff to find file in current dir",
		},
		{
			"<leader>fg",
			function()
				require("fff").live_grep()
			end,
			desc = "Open fff to live grep in current dir",
		},
		{
			"<leader>fw",
			function()
				require("fff").live_grep_under_cursor()
			end,
			mode = { "n", "x" },
			desc = "Grep current word / selection",
		},
		{
			"<leader>fc",
			function()
				require("fff").find_files_in_dir(vim.fn.stdpath("config"))
			end,
			desc = "Open fff to find file in nvim config dir",
		},
		{
			"<leader><leader>",
			-- fff has no buffer picker, use a simple vim.ui.select based one
			function()
				local current = vim.api.nvim_get_current_buf()
				local buffers = {}
				for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
						local name = vim.api.nvim_buf_get_name(bufnr)
						local label = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or ("[No Name]")
						table.insert(buffers, { bufnr = bufnr, label = label })
					end
				end
				vim.ui.select(buffers, {
					prompt = "Buffers",
					format_item = function(item)
						local flag = item.bufnr == current and "%" or " "
						return string.format("%s %d  %s", flag, item.bufnr, item.label)
					end,
				}, function(choice)
					if choice then
						vim.api.nvim_set_current_buf(choice.bufnr)
					end
				end)
			end,
			desc = "[,] Find existing buffers",
		},
	},
}
