-- Indentation Twig : indent HTML natif (base) + delta blocs Twig.
-- Placé dans after/indent/ (et non ftplugin/) pour passer APRÈS le loader
-- d'indentation natif, qui sinon réinitialise indentexpr via b:undo_indent.
-- Le highlight reste géré par treesitter (parser twig + injections).
vim.cmd("runtime! indent/html.vim") -- définit HtmlIndent() et les b:html_indent_*

vim.bo.indentexpr = "v:lua.require'heyfara.twig_indent'()"
vim.bo.indentkeys = "o,O,<Return>,*<Return>,{,},%,<>>,<bs>,end,else"
vim.b.undo_indent = "setlocal indentexpr< indentkeys<"
