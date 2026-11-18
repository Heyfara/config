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

-- Workspaces dans l'ordre de l'arborescence : chaque repo suivi de ses
-- workspaces d'inspection « repo › tâche » ; inspections orphelines à la racine.
local function ordered_workspaces()
    local names = wezterm.mux.get_workspace_names()
    table.sort(names)
    local exists = {}
    for _, name in ipairs(names) do exists[name] = true end

    local ordered = {}
    for _, name in ipairs(names) do
        local i = name:find(M.SUB_SEP, 1, true)
        if not i then
            table.insert(ordered, { name = name, short = name, child = false })
            for _, sub in ipairs(names) do
                if sub:sub(1, #name + #M.SUB_SEP) == name .. M.SUB_SEP then
                    table.insert(ordered, { name = sub, short = sub:sub(#name + #M.SUB_SEP + 1), child = true })
                end
            end
        elseif not exists[name:sub(1, i - 1)] then
            table.insert(ordered, { name = name, short = name, child = false })
        end
    end
    return ordered
end

-- Fenêtres d'un workspace, chacune avec ses onglets dans l'ordre :
-- { mux_window, tabs = { { index, tab, agent (le plus urgent) } } }
local function workspace_windows(workspace, agents_by_pane)
    local windows = {}
    for _, mux_window in ipairs(wezterm.mux.all_windows()) do
        if mux_window:get_workspace() == workspace then
            local result = {}
            for _, info in ipairs(mux_window:tabs_with_info()) do
                local best
                for _, p in ipairs(info.tab:panes()) do
                    local a = agents_by_pane[p:pane_id()]
                    if a and (not best or (state.priority[a.state] or 9) < (state.priority[best.state] or 9)) then
                        best = a
                    end
                end
                table.insert(result, { index = info.index + 1, tab = info.tab, agent = best })
            end
            table.insert(windows, { mux_window = mux_window, tabs = result })
        end
    end
    return windows
end

-- LEADER+f : arborescence workspaces → onglets, avec l'état des agents.
-- Entrée sur un workspace : bascule ; sur un onglet : y va directement.
function M.workspaces()
    return wezterm.action_callback(function(window, pane)
        local agents_by_pane = {}
        for _, a in ipairs(state.scan()) do agents_by_pane[a.pane_id] = a end

        local current = window:active_workspace()
        local choices = {}
        for _, ws in ipairs(ordered_workspaces()) do
            local indent = ws.child and '    ' or ''
            local is_current = ws.name == current
            table.insert(choices, {
                id = 'ws:' .. ws.name,
                label = wezterm.format({
                    { Foreground = { Color = is_current and c.lavender or c.overlay0 } },
                    { Text = (is_current and '▶ ' or '  ') .. indent },
                    { Foreground = { Color = ws.child and c.peach or c.lavender } },
                    { Attribute = { Intensity = 'Bold' } },
                    { Text = (ws.child and '└ ' or (icons.workspace .. ' ')) .. ws.short },
                }),
            })

            local windows = workspace_windows(ws.name, agents_by_pane)
            local my_window_id = window:mux_window():window_id()
            for wi, win in ipairs(windows) do
                local sub = ''
                if #windows > 1 then
                    sub = '  '
                    local mine = win.mux_window:window_id() == my_window_id
                    table.insert(choices, {
                        id = 'pane:' .. win.mux_window:active_pane():pane_id(),
                        label = wezterm.format({
                            { Foreground = { Color = c.overlay1 } },
                            { Text = '  ' .. indent .. '   ' .. icons.window .. ' fenêtre ' .. wi .. (mine and ' (celle-ci)' or '') },
                        }),
                    })
                end
                for _, t in ipairs(win.tabs) do
                    local a = t.agent
                    local pane_for_tab = a and a.pane or t.tab:active_pane()
                    local title = t.tab:get_title()
                    if title == '' then
                        title = (a and a.worktree) or state.clean_title(pane_for_tab:get_title())
                    end

                    local items = {
                        { Foreground = { Color = c.overlay0 } },
                        { Text = '  ' .. indent .. sub .. '   ' .. string.format('%2d', t.index) .. ' ' },
                    }
                    if a then
                        local icon, color = state_icon(a)
                        table.insert(items, { Foreground = { Color = color } })
                        table.insert(items, { Text = icon .. ' ' })
                        table.insert(items, { Foreground = { Color = c.text } })
                        table.insert(items, { Text = pad(title, 24) .. ' ' })
                        table.insert(items, { Foreground = { Color = c.subtext0 } })
                        table.insert(items, { Attribute = { Italic = true } })
                        table.insert(items, { Text = pad(agent_message(a), 50) })
                        table.insert(items, 'ResetAttributes')
                        table.insert(items, { Foreground = { Color = c.overlay0 } })
                        table.insert(items, { Text = ' ' .. elapsed(a.ts) })
                    else
                        table.insert(items, { Foreground = { Color = c.subtext1 } })
                        table.insert(items, { Text = '  ' .. title })
                    end
                    table.insert(choices, {
                        id = 'pane:' .. pane_for_tab:pane_id(),
                        label = wezterm.format(items),
                    })
                end
            end
        end

        window:perform_action(act.InputSelector {
            title = 'Workspaces',
            fuzzy = true,
            fuzzy_description = 'Workspace / onglet : ',
            choices = choices,
            action = wezterm.action_callback(function(w, p, id)
                if not id then return end
                local kind, value = id:match('^(%a+):(.*)$')
                if kind == 'ws' then
                    w:perform_action(act.SwitchToWorkspace { name = value }, p)
                elseif kind == 'pane' then
                    nav.focus_pane(w, tonumber(value))
                end
            end),
        }, pane)
    end)
end

return M
