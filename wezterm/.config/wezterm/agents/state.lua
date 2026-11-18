-- État des agents Claude Code, écrit par bin/agent-hook.
-- Un fichier JSON par panneau : <state_dir>/<pane_id>.json
local wezterm = require 'wezterm'

local M = {}

M.dir = (os.getenv('XDG_STATE_HOME') or (wezterm.home_dir .. '/.local/state')) .. '/wezterm-agents'

-- Plus petit = plus urgent
M.priority = { waiting = 1, done = 2, working = 3, idle = 4 }

local function read_file(path)
    local f = io.open(path, 'r')
    if not f then return nil end
    local content = f:read('a')
    f:close()
    return content
end

local function file_exists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

-- Socket de cette instance GUI : seuls les fichiers qui la mentionnent nous concernent.
local my_socket_suffix = 'gui-sock-' .. tostring(wezterm.procinfo.pid())

local function owned_by_me(data)
    local socket = data.socket or ''
    return socket:sub(-#my_socket_suffix) == my_socket_suffix
end

-- Nom court de la tâche : worktree `claude -w` sinon dossier courant
function M.label_from_cwd(cwd)
    if not cwd or cwd == '' then return nil end
    local wt = cwd:match('/%.claude/worktrees/([^/]+)')
    return wt or cwd:match('([^/]+)/?$')
end

-- Dépôt : chemin avant /.claude/worktrees, sinon cwd
function M.repo_from_cwd(cwd)
    if not cwd or cwd == '' then return nil end
    local root = cwd:match('^(.-)/%.claude/worktrees/') or cwd
    return root:match('([^/]+)/?$')
end

-- Titre de panneau sans le préfixe spinner/symbole que Claude y met
function M.clean_title(title)
    title = (title or ''):gsub('^[^%w%-_~/%.]+', '')
    return title
end

-- Lit tous les états, les relie aux panneaux de cette instance et nettoie les orphelins.
function M.scan()
    local agents = {}
    local ok, files = pcall(wezterm.glob, M.dir .. '/*.json')
    if not ok then return agents end

    for _, path in ipairs(files) do
        local pane_id = tonumber(path:match('(%d+)%.json$'))
        local okj, data = pcall(wezterm.serde.json_decode, read_file(path) or '')
        if pane_id and okj and type(data) == 'table' then
            if owned_by_me(data) then
                local okp, pane = pcall(wezterm.mux.get_pane, pane_id)
                if okp and pane then
                    local tab = pane:tab()
                    local mux_window = tab and tab:window()
                    table.insert(agents, {
                        pane_id = pane_id,
                        pane = pane,
                        tab = tab,
                        tab_id = tab and tab:tab_id(),
                        mux_window = mux_window,
                        workspace = mux_window and mux_window:get_workspace(),
                        state = data.state or 'idle',
                        message = data.message or '',
                        kind = data.kind or '',
                        worktree = data.cwd and data.cwd:match('/%.claude/worktrees/([^/]+)'),
                        task = data.task,
                        cwd = data.cwd,
                        label = M.label_from_cwd(data.cwd),
                        repo = M.repo_from_cwd(data.cwd),
                        ts = data.ts or 0,
                    })
                else
                    os.remove(path) -- panneau fermé sans SessionEnd
                end
            elseif data.socket and data.socket ~= '' and not file_exists(data.socket) then
                os.remove(path) -- instance WezTerm disparue
            end
            -- sinon : autre instance vivante (ex. domaine unix), on ne touche à rien
        end
    end

    table.sort(agents, function(a, b)
        local pa, pb = M.priority[a.state] or 9, M.priority[b.state] or 9
        if pa ~= pb then return pa < pb end
        return a.ts < b.ts
    end)
    return agents
end

-- Rafraîchit le cache partagé (appelé par update-status) et renvoie la liste.
-- wezterm.GLOBAL ne stocke que des données simples : pas d'objets Pane.
function M.refresh()
    local agents = M.scan()
    local by_pane = {}
    for _, a in ipairs(agents) do
        by_pane[tostring(a.pane_id)] = {
            state = a.state,
            message = a.message,
            kind = a.kind,
            worktree = a.worktree,
            label = a.label,
            repo = a.repo,
            workspace = a.workspace,
            ts = a.ts,
        }
    end
    wezterm.GLOBAL.agents = by_pane
    return agents
end

-- Lecture du cache (format-tab-title, etc.)
function M.cached(pane_id)
    local all = wezterm.GLOBAL.agents
    return all and all[tostring(pane_id)]
end

return M
