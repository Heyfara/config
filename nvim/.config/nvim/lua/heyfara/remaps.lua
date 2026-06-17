vim.g.mapleader = " "

-- paste without losing pasted text
vim.keymap.set("x", "<leader>p", "\"_dP")

-- search/replace using the word under the cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
