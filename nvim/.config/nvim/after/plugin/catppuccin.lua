U = require "catppuccin.utils.colors"

require("catppuccin").setup {
    highlight_overrides = {
        all = function(colors)
            return {
                CursorLineNr = { fg = colors.lavender, bg = U.darken(colors.overlay2, 0.2, colors.base) },
            }
        end,
    },
}

vim.cmd.colorscheme "catppuccin"
