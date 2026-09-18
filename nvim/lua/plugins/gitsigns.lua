return {
	"lewis6991/gitsigns.nvim",
	event = "VeryLazy",
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "┆" },
		},
		signs_staged = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
	},
	config = function(_, opts)
		require("gitsigns").setup(opts)

		local gs = require("gitsigns")
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { desc = "Git: " .. desc })
		end

		map("]h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gs.nav_hunk("next")
			end
		end, "Next Hunk")

		map("[h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gs.nav_hunk("prev")
			end
		end, "Prev Hunk")

		map("<leader>hs", gs.stage_hunk, "Stage Hunk")
		map("<leader>hr", gs.reset_hunk, "Reset Hunk")
		map("<leader>hS", gs.stage_buffer, "Stage Buffer")
		map("<leader>hR", gs.reset_buffer, "Reset Buffer")
		map("<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
		map("<leader>hp", gs.preview_hunk, "Preview Hunk")
		map("<leader>hb", function()
			gs.blame_line({ full = true })
		end, "Blame Line")
		map("<leader>hd", gs.diffthis, "Diff This")
		map("<leader>hD", function()
			gs.diffthis("~")
		end, "Diff This ~")

		vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Git: Inner Hunk" })
	end,
}
