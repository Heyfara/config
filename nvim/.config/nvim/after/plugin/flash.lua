require('flash').setup({})

vim.keymap.set('n', 's', require('flash').jump, {})
vim.keymap.set({'n', 'x', 'o'}, 'S', require('flash').treesitter, {})
vim.keymap.set('o', 'r', require('flash').remote, {})
vim.keymap.set({'x', 'o'}, 'R', require('flash').treesitter_search, {})
vim.keymap.set('c', '<c-s>', require('flash').toggle, {})
