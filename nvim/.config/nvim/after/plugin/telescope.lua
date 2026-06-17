local actions = require('telescope.actions');
require('telescope').setup{
    defaults = {
        mappings = {
            i = {
                ["<C-h>"] = "which_key",
                ['<c-d>'] = actions.delete_buffer
            }
        }
    },
}

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fs', builtin.grep_string, {})
vim.keymap.set('n', '<leader>fr', builtin.resume, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
