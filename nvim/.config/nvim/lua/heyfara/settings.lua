vim.opt.number = true
vim.opt.mouse = ''

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
-- sync buffers automatically
vim.opt.autoread = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.wo.cursorline = true
vim.opt.scrolloff = 8
vim.opt.colorcolumn = "80"

vim.opt.termguicolors = true

-- Complétion native (vim.lsp.completion) : menu même pour 1 candidat, pas de
-- présélection, matching flou (fuzzy) et aperçu dans un popup (0.11+).
vim.opt.completeopt = { "menu", "menuone", "noselect", "fuzzy", "popup" }

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.diagnostic.config({
    virtual_text = true,
})

-- Filetype `twig` simple pour *.twig et *.html.twig (remplace twig.vim, qui
-- imposait un filetype composé `html.twig.js.css` incompatible avec treesitter).
-- Le parser treesitter `twig` colore le Twig et injecte HTML/CSS/JS.
vim.filetype.add({
    extension = { twig = "twig" },
})
