require("nvim-tree").setup({
    sort_by = "case_sensitive",
    git = {
        timeout = 500,
    }
})

local function open_nvim_tree()
    -- open the tree
    require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

local api = require('nvim-tree.api')

local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
end

vim.keymap.set('n', '<C-c>', api.tree.change_root_to_node, opts('CD'))
