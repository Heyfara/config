-- nvim-treesitter, branche `main` : l'API a changé.
-- Plus de `require('nvim-treesitter.configs').setup{}`.
--   - on installe les parsers avec require('nvim-treesitter').install{}
--   - on démarre le highlight nous-mêmes via vim.treesitter.start() sur FileType
--   - l'indentation passe par 'indentexpr' (expérimental)
-- Mise à jour des parsers : :TSUpdate

local parsers = {
    "bash",
    "c",
    "css",
    "dockerfile",
    "html",
    "javascript",
    "json",
    "json5",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "scss",
    "tsx",
    "twig",
    "vim",
    "vimdoc",
    "yaml",
}

-- N'installer que les parsers manquants (sinon install() re-télécharge à
-- chaque démarrage). Requiert le CLI `tree-sitter` (pacman -S tree-sitter-cli).
local ts = require("nvim-treesitter")
local installed = {}
for _, p in ipairs(ts.get_installed()) do
    installed[p] = true
end
local missing = vim.tbl_filter(function(p)
    return not installed[p]
end, parsers)
if #missing > 0 then
    ts.install(missing)
end

-- Pas d'indentation treesitter pour ces filetypes :
--  - html : rendu peu fiable
--  - twig : grammaire plate (indentexpr ts = 0) ; géré par ftplugin/twig.lua
local no_indent = { html = true, twig = true }

vim.api.nvim_create_autocmd("FileType", {
    desc = "Démarrer treesitter (highlight + indent) si un parser existe",
    callback = function(ev)
        -- Pas de treesitter sur les gros fichiers (voir autocommands.lua)
        if vim.b[ev.buf].bigfile then
            return
        end
        -- vim.treesitter.start() lève une erreur s'il n'y a pas de parser
        -- pour ce filetype : on protège avec pcall.
        if not pcall(vim.treesitter.start, ev.buf) then
            return
        end
        if not no_indent[vim.bo[ev.buf].filetype] then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
