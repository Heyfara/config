-- Tâches d'agent : création (claude -w), renommage d'onglet.
-- Étape 6 : inspection et clôture.
local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Racine du dépôt principal pour le panneau courant (remonte d'un worktree
-- `claude -w` vers le repo). nil si le dossier n'est pas dans un dépôt git.
function M.repo_root(pane)
    local cwd = pane:get_current_working_dir()
    local path = cwd and (cwd.file_path or tostring(cwd):gsub('^file://[^/]*', '')) or wezterm.home_dir
    local ok, out = wezterm.run_child_process({ 'git', '-C', path, 'rev-parse', '--show-toplevel' })
    if not ok then return nil end
    local top = out:gsub('%s+$', '')
    return top:match('^(.-)/%.claude/worktrees/[^/]+$') or top
end

-- « Carte météo / API » -> « carte-meteo-api » : sûr pour une branche et le shell
local function slug(name)
    local s = name:lower()
    local accents = { ['à']='a', ['â']='a', ['ä']='a', ['é']='e', ['è']='e', ['ê']='e', ['ë']='e',
        ['î']='i', ['ï']='i', ['ô']='o', ['ö']='o', ['ù']='u', ['û']='u', ['ü']='u', ['ç']='c',
        ['À']='a', ['Â']='a', ['É']='e', ['È']='e', ['Ê']='e', ['Î']='i', ['Ô']='o', ['Û']='u', ['Ç']='c' }
    for from, to in pairs(accents) do s = s:gsub(from, to) end
    s = s:gsub('[^%w%-_]+', '-'):gsub('%-+', '-'):gsub('^%-', ''):gsub('%-$', '')
    return s
end

-- LEADER+n : nom de tâche -> nouvel onglet à droite avec `claude -w <nom>`
function M.new_task()
    return wezterm.action_callback(function(window, pane)
        local root = M.repo_root(pane)
        if not root then
            window:toast_notification('Nouvelle tâche', "Ce dossier n'est pas dans un dépôt git", nil, 4000)
            return
        end
        window:perform_action(act.PromptInputLine {
            description = wezterm.format({
                { Attribute = { Intensity = 'Bold' } },
                { Text = 'Nouvelle tâche dans ' .. root:match('([^/]+)$') .. ' (claude -w) :' },
            }),
            action = wezterm.action_callback(function(w, _, line)
                if not line then return end
                local name = slug(line)
                if name == '' then return end
                local tab, new_pane = w:mux_window():spawn_tab({ cwd = root })
                tab:set_title(name)
                new_pane:send_text('claude -w ' .. name .. '\n')
            end),
        }, pane)
    end)
end

-- LEADER+, : renommer l'onglet ; vide = revenir au titre automatique
function M.rename_tab()
    return wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        window:perform_action(act.PromptInputLine {
            description = 'Nom de l\'onglet (vide = automatique) :',
            initial_value = tab:get_title(),
            action = wezterm.action_callback(function(_, _, line)
                if line then tab:set_title(line) end
            end),
        }, pane)
    end)
end

return M
