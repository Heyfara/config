-- Statusline : lualine (remplace feline).
require('gitsigns').setup()
require('lualine').setup({
    options = {
        -- 'auto' : suit le colorscheme actif (catppuccin). Le thème nommé
        -- 'catppuccin' n'existe plus, seulement catppuccin-mocha/frappe/etc.
        theme = 'auto',
        globalstatus = true,
        section_separators = '',
        component_separators = '',
    },
})
