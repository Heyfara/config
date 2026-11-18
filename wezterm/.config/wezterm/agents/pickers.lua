-- Navigation rapide : agent suivant, sélecteur d'agents, sélecteur de workspaces.
local wezterm = require 'wezterm'
local act = wezterm.action
local state = require 'agents.state'
local theme = require 'agents.theme'
local nav = require 'agents.nav'

local c = theme.colors
local icons = theme.icons

local M = {}

-- Séparateur des workspaces d'inspection : « repo › tâche » (étape 6)
M.SUB_SEP = ' › '

local function elapsed(ts)
    local d = os.time() - (ts or 0)
    if d < 60 then return d .. 's' end
    if d < 3600 then return math.floor(d / 60) .. 'm' end
    if d < 86400 then return math.floor(d / 3600) .. 'h' end
    return math.floor(d / 86400) .. 'j'
end

local function pad(s, n)
    s = wezterm.truncate_right(s or '', n)
    return s .. string.rep(' ', n - wezterm.column_width(s))
end

local function state_icon(agent)
    local st = theme.agent_style(agent)
    return st.icon, st.bg or st.fg
end

local function agent_message(a)
    if a.message ~= '' then return a.message end
    if a.state == 'working' then return 'travaille…' end
    return a.task or ''
end

-- LEADER+j : agent qui attend depuis le plus longtemps (permission/question
-- d'abord, puis « terminé »), en sautant le panneau courant.
function M.jump_next()
    return wezterm.action_callback(function(window, pane)
        for _, a in ipairs(state.scan()) do
            if (a.state == 'waiting' or a.state == 'done') and a.pane_id ~= pane:pane_id() then
                nav.focus_pane(window, a.pane_id)
                return
            end
        end
        window:toast_notification('Agents', 'Aucun agent en attente', nil, 3000)
    end)
end

-- LEADER+s : tous les agents, tous workspaces, triés par urgence
function M.agents()
    return wezterm.action_callback(function(window, pane)
        local choices = {}
        for _, a in ipairs(state.scan()) do
            local icon, color = state_icon(a)
            table.insert(choices, {
                id = tostring(a.pane_id),
                label = wezterm.format({
                    { Foreground = { Color = color } },
                    { Text = icon .. '  ' },
                    { Foreground = { Color = c.overlay1 } },
                    { Text = pad(a.repo or a.workspace, 20) .. ' ' },
                    { Foreground = { Color = c.lavender } },
                    { Text = pad(a.worktree or a.label, 24) .. ' ' },
                    { Foreground = { Color = c.text } },
                    { Attribute = { Italic = true } },
                    { Text = pad(agent_message(a), 60) },
                    'ResetAttributes',
                    { Foreground = { Color = c.overlay0 } },
                    { Text = ' ' .. elapsed(a.ts) },
                }),
            })
        end
        if #choices == 0 then
            window:toast_notification('Agents', 'Aucun agent actif', nil, 3000)
            return
        end
        window:perform_action(act.InputSelector {
            title = 'Agents',
            fuzzy = true,
            fuzzy_description = 'Agent : ',
            choices = choices,
            action = wezterm.action_callback(function(w, _, id)
                if id then nav.focus_pane(w, tonumber(id)) end
            end),
        }, pane)
    end)
end

-- LEADER+f : workspaces en arborescence (inspections sous leur repo) + badges
function M.workspaces()
    return wezterm.action_callback(function(window, pane)
        local by_ws = {}
        for _, a in ipairs(state.scan()) do
            local ws = a.workspace or ''
            by_ws[ws] = by_ws[ws] or { waiting = 0, done = 0, working = 0 }
            if by_ws[ws][a.state] then by_ws[ws][a.state] = by_ws[ws][a.state] + 1 end
        end

        -- Ordre : chaque repo suivi de ses workspaces d'inspection
        local names = wezterm.mux.get_workspace_names()
        table.sort(names)
        local ordered = {}
        for _, name in ipairs(names) do
            if not name:find(M.SUB_SEP, 1, true) then
                table.insert(ordered, { name = name, child = false })
                for _, sub in ipairs(names) do
                    if sub:sub(1, #name + #M.SUB_SEP) == name .. M.SUB_SEP then
                        table.insert(ordered, { name = sub, child = true })
                    end
                end
            end
        end
        -- Inspections dont le repo n'a plus de workspace : à la racine
        local exists = {}
        for _, name in ipairs(names) do exists[name] = true end
        for _, name in ipairs(names) do
            local i = name:find(M.SUB_SEP, 1, true)
            if i and not exists[name:sub(1, i - 1)] then
                table.insert(ordered, { name = name, child = false })
            end
        end

        local current = window:active_workspace()
        local choices = {}
        for _, ws in ipairs(ordered) do
            local counts = by_ws[ws.name] or {}
            local items = {
                { Foreground = { Color = ws.name == current and c.lavender or c.overlay0 } },
                { Text = (ws.name == current and '▶ ' or '  ') },
                { Foreground = { Color = c.text } },
            }
            if ws.child then
                table.insert(items, { Text = '  └ ' .. ws.name:sub(ws.name:find(M.SUB_SEP, 1, true) + #M.SUB_SEP) })
            else
                table.insert(items, { Text = icons.workspace .. ' ' .. ws.name })
            end
            local function badge(key, icon, color)
                if (counts[key] or 0) > 0 then
                    table.insert(items, { Foreground = { Color = color } })
                    table.insert(items, { Text = '  ' .. icon .. ' ' .. counts[key] })
                end
            end
            badge('waiting', icons.permission, c.red)
            badge('done', icons.done, c.yellow)
            badge('working', icons.working, c.green)
            table.insert(choices, { id = ws.name, label = wezterm.format(items) })
        end

        window:perform_action(act.InputSelector {
            title = 'Workspaces',
            fuzzy = true,
            fuzzy_description = 'Workspace : ',
            choices = choices,
            action = wezterm.action_callback(function(w, p, id)
                if id then w:perform_action(act.SwitchToWorkspace { name = id }, p) end
            end),
        }, pane)
    end)
end

return M
