-- Tâches d'agent : création (claude -w), renommage d'onglet,
-- inspection (workspace « repo › tâche » sur le worktree) et clôture.
local wezterm = require 'wezterm'
local act = wezterm.action
local state = require 'agents.state'
local nav = require 'agents.nav'
local projects = require 'projects'

local M = {}

M.SUB_SEP = state.SUB_SEP

-- Dossier courant d'un panneau (chemin local)
function M.pane_path(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then return nil end
    return cwd.file_path or (tostring(cwd):gsub('^file://[^/]*', ''))
end

-- Racine du dépôt principal pour le panneau courant (remonte d'un worktree
-- `claude -w` vers le repo). nil si le dossier n'est pas dans un dépôt git.
function M.repo_root(pane)
    local path = M.pane_path(pane) or wezterm.home_dir
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

-- ── Inspection et clôture ──────────────────────────────────────────────

local function worktree_of(path)
    return path and path:match('^(.-/%.claude/worktrees/[^/]+)')
end

local function git(dir, ...)
    local ok, out = wezterm.run_child_process({ 'git', '-C', dir, ... })
    return ok, (out or ''):gsub('%s+$', '')
end

-- Contexte de la tâche liée au panneau courant, qu'on soit dans l'onglet de
-- l'agent ou dans le workspace d'inspection :
-- { repo, task, worktree, root, agent_pane_id, inspect_ws }
function M.context(window, pane)
    local ws = window:active_workspace()
    local agents = state.scan()
    local ctx

    local i = ws:find(M.SUB_SEP, 1, true)
    if i then
        -- Workspace d'inspection : la tâche est dans son nom
        local repo, task = ws:sub(1, i - 1), ws:sub(i + #M.SUB_SEP)
        ctx = { repo = repo, task = task }
        for _, a in ipairs(agents) do
            if a.worktree == task and a.repo == repo then
                ctx.agent_pane_id, ctx.worktree = a.pane_id, worktree_of(a.cwd)
            end
        end
        ctx.worktree = ctx.worktree or worktree_of(M.pane_path(pane))
    else
        -- Onglet de l'agent : un panneau de l'onglet a un état d'agent en worktree
        local in_tab = {}
        for _, p in ipairs(pane:tab():panes()) do in_tab[p:pane_id()] = true end
        for _, a in ipairs(agents) do
            if in_tab[a.pane_id] and a.worktree then
                ctx = { repo = a.repo, task = a.worktree, agent_pane_id = a.pane_id, worktree = worktree_of(a.cwd) }
                break
            end
        end
        if not ctx then
            local wt = worktree_of(M.pane_path(pane))
            if not wt then return nil end
            ctx = { task = wt:match('([^/]+)$'), worktree = wt }
            ctx.repo = state.repo_from_cwd(wt)
        end
    end

    if not ctx.worktree then return nil end
    ctx.root = ctx.worktree:match('^(.-)/%.claude/worktrees/')
    ctx.inspect_ws = ctx.repo .. M.SUB_SEP .. ctx.task
    return ctx
end

local function workspace_exists(name)
    for _, n in ipairs(wezterm.mux.get_workspace_names()) do
        if n == name then return true end
    end
    return false
end

-- LEADER+i : ouvre (ou rejoint) le workspace « repo › tâche » sur le worktree
function M.inspect()
    return wezterm.action_callback(function(window, pane)
        local ctx = M.context(window, pane)
        if not ctx then
            window:toast_notification('Inspecter', 'Aucune tâche claude -w dans cet onglet', nil, 4000)
            return
        end
        if workspace_exists(ctx.inspect_ws) then
            window:perform_action(act.SwitchToWorkspace { name = ctx.inspect_ws }, pane)
        else
            projects.open_layout(window, pane, ctx.inspect_ws, ctx.worktree)
        end
    end)
end

-- État git du worktree : existe ? propre ? poussé ? (+ texte pour l'humain)
local function worktree_status(ctx)
    local st = { exists = false, clean = false, pushed = false }
    local f = io.open(ctx.worktree .. '/.git', 'r')
    if not f then
        st.summary = 'worktree déjà supprimé'
        return st
    end
    f:close()
    st.exists = true

    local _, branch = git(ctx.worktree, 'rev-parse', '--abbrev-ref', 'HEAD')
    st.branch = branch
    local _, porcelain = git(ctx.worktree, 'status', '--porcelain')
    st.clean = porcelain == ''
    local has_upstream, ahead = git(ctx.worktree, 'rev-list', '--count', '@{u}..HEAD')
    st.pushed = has_upstream and ahead == '0'

    local parts = { 'branche ' .. branch }
    table.insert(parts, st.clean and 'propre' or 'modifications non commitées')
    if not has_upstream then
        table.insert(parts, 'jamais poussée')
    elseif ahead ~= '0' then
        table.insert(parts, ahead .. ' commit(s) non poussé(s)')
    else
        table.insert(parts, 'poussée')
    end
    st.summary = table.concat(parts, ', ')
    return st
end

-- Tue tous les panneaux d'un workspace et l'onglet de l'agent
local function kill_panes(ctx)
    local ids = {}
    for _, mux_window in ipairs(wezterm.mux.all_windows()) do
        if mux_window:get_workspace() == ctx.inspect_ws then
            for _, tab in ipairs(mux_window:tabs()) do
                for _, p in ipairs(tab:panes()) do table.insert(ids, p:pane_id()) end
            end
        end
    end
    if ctx.agent_pane_id then
        local ok, agent_pane = pcall(wezterm.mux.get_pane, ctx.agent_pane_id)
        if ok and agent_pane then
            for _, p in ipairs(agent_pane:tab():panes()) do table.insert(ids, p:pane_id()) end
        end
    end
    for _, id in ipairs(ids) do
        wezterm.run_child_process({ wezterm.executable_dir .. '/wezterm', 'cli', 'kill-pane', '--pane-id', tostring(id) })
    end
end

-- LEADER+w : ferme l'inspection et l'onglet de l'agent ; supprime le worktree
-- seulement s'il est propre et poussé.
function M.close_task()
    return wezterm.action_callback(function(window, pane)
        local ctx = M.context(window, pane)
        if not ctx then
            window:toast_notification('Clôturer', 'Aucune tâche claude -w dans cet onglet', nil, 4000)
            return
        end
        local st = worktree_status(ctx)

        local agent_busy = false
        if ctx.agent_pane_id then
            local a = state.cached(ctx.agent_pane_id)
            agent_busy = a and a.state == 'working'
        end

        local choices = {}
        if st.exists and st.clean and st.pushed then
            table.insert(choices, { id = 'remove', label = 'Fermer les onglets et supprimer le worktree' })
        end
        table.insert(choices, { id = 'keep', label = st.exists and 'Fermer les onglets, garder le worktree' or 'Fermer les onglets' })
        table.insert(choices, { id = 'cancel', label = 'Annuler' })

        local warning = agent_busy and '  ⚠ l\'agent travaille encore' or ''
        window:perform_action(act.InputSelector {
            title = 'Clôturer ' .. ctx.task,
            description = ctx.task .. ' : ' .. st.summary .. warning,
            choices = choices,
            action = wezterm.action_callback(function(w, p, id)
                if not id or id == 'cancel' then return end

                -- Quitter le workspace d'inspection avant de le vider, sinon la
                -- fenêtre se fermerait avec son dernier onglet.
                if w:active_workspace() == ctx.inspect_ws then
                    w:perform_action(act.SwitchToWorkspace { name = ctx.repo }, p)
                end
                kill_panes(ctx)

                local msg = 'Onglets fermés'
                if id == 'remove' then
                    local ok, err = git(ctx.root, 'worktree', 'remove', ctx.worktree)
                    if ok then
                        git(ctx.root, 'branch', '-d', st.branch)
                        msg = 'Worktree ' .. ctx.task .. ' supprimé'
                    else
                        msg = 'Échec de git worktree remove : ' .. err
                    end
                end
                w:toast_notification('Clôturer', msg, nil, 5000)
            end),
        }, pane)
    end)
end

return M
