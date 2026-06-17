-- Indentation pour les fichiers Twig.
-- La grammaire treesitter twig est plate (blocs non imbriqués), donc son
-- indentexpr renvoie 0 partout. On délègue le HTML à l'indent natif de Vim
-- (HtmlIndent, éprouvé) et on ajoute un delta pour les blocs Twig.

-- Mots-clés qui ouvrent un bloc apparié ({% endX %})
local OPEN = {
    ["if"] = true, ["for"] = true, block = true, macro = true, embed = true,
    apply = true, filter = true, autoescape = true, with = true,
    spaceless = true, verbatim = true, sandbox = true, cache = true,
}
-- Branches internes (dédentées comme la fermeture, ré-indentent après)
local BRANCH = { ["else"] = true, ["elseif"] = true }

-- Premier mot-clé d'un tag {% ... %} en début de ligne (ou nil)
local function leading_kw(line)
    return line:match("^%s*{%%[%-~]?%s*([%a_]+)")
end

-- Solde net d'ouvertures/fermetures de blocs Twig sur une ligne
local function block_delta(line)
    local delta = 0
    for kw in line:gmatch("{%%[%-~]?%s*([%a_]+)") do
        if kw:match("^end") then
            delta = delta - 1
        elseif OPEN[kw] then
            delta = delta + 1
        end
    end
    return delta
end

return function()
    local lnum = vim.v.lnum
    local sw = vim.fn.shiftwidth()

    -- Base : indentation HTML native (gère les balises, void elements, inline…)
    local ind = vim.fn.HtmlIndent()
    if ind < 0 then ind = 0 end

    -- La ligne courante ferme un bloc ou est une branche → on la dédente
    local cur_kw = leading_kw(vim.fn.getline(lnum))
    if cur_kw and (cur_kw:match("^end") or BRANCH[cur_kw]) then
        ind = ind - sw
    end

    -- La ligne précédente ouvre un bloc (ou est une branche) → on indente
    local prev = vim.fn.prevnonblank(lnum - 1)
    if prev > 0 then
        local prev_line = vim.fn.getline(prev)
        local prev_kw = leading_kw(prev_line)
        if block_delta(prev_line) > 0 or (prev_kw and BRANCH[prev_kw]) then
            ind = ind + sw
        end
    end

    if ind < 0 then ind = 0 end
    return ind
end
