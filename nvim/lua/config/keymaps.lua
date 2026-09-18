vim.keymap.set("n", "-", "<cmd>Oil --float<CR>")
vim.keymap.set("n", "\\", "<cmd>vsplit<CR>")
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>")

-- window movement
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

vim.keymap.set("n", "<C-i>", function()
	vim.lsp.buf.signature_help()
end)
