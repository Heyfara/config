-- Rendu : barre de statut (workspace, compteurs d'agents) et badges d'onglets.
-- Seul gestionnaire `update-status` / `format-tab-title` de la config.
local wezterm = require 'wezterm'
local state = require 'agents.state'
local theme = require 'agents.theme'

local c = theme.colors
local icons = theme.icons

local M = {}

function M.apply_to_config(config)
    config.status_update_interval = 1000
    config.tab_max_width = 32
    config.colors = config.colors or {}
    config.colors.tab_bar = config.colors.tab_bar or {}
    config.colors.tab_bar.background = c.crust
end

-- Agent le plus urgent parmi les panneaux d'un onglet (depuis le cache)
local function tab_agent(tab_id)
    local ok, mux_tab = pcall(wezterm.mux.get_tab, tab_id)
    if not ok or not mux_tab then return nil end
    local best
    for _, p in ipairs(mux_tab:panes()) do
        local a = state.cached(p:pane_id())
        if a and (not best or (state.priority[a.state] or 9) < (state.priority[best.state] or 9)) then
            best = a
        end
    end
    return best
end

-- Titre de panneau sans le préfixe spinner/symbole que Claude y met
local function clean_title(title)
    title = (title or ''):gsub('^[^%w%-_~/%.]+', '')
    return title
end

wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
    local agent = tab_agent(tab.tab_id)

    local label = tab.tab_title
    if not label or label == '' then
        label = (agent and agent.worktree) or clean_title(tab.active_pane.title)
    end

    local bg, fg = c.mantle, c.overlay1
    if tab.is_active then
        bg, fg = c.surface1, c.text
    elseif hover then
        bg, fg = c.surface0, c.subtext1
    end

    local icon, icon_fg = '', fg
    if agent then
        local st = theme.agent_style(agent)
        icon = st.icon .. ' '
        if st.bg then
            bg, fg, icon_fg = st.bg, c.crust, c.crust
        else
            icon_fg = st.fg
        end
    end

    local index = ' ' .. (tab.tab_index + 1) .. ' '
    local room = max_width - #index - (agent and 2 or 0) - 2
    label = wezterm.truncate_right(label, math.max(room, 1))

    return {
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
        { Attribute = { Underline = (tab.is_active and agent and theme.agent_style(agent).bg) and 'Single' or 'None' } },
        { Text = index },
        { Foreground = { Color = icon_fg } },
        { Text = icon },
        { Foreground = { Color = fg } },
        { Text = label .. ' ' },
        'ResetAttributes',
        { Background = { Color = c.crust } },
        { Text = ' ' },
    }
end)

local function left_status(window)
    return wezterm.format({
        { Background = { Color = c.lavender } },
        { Foreground = { Color = c.crust } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = ' ' .. icons.workspace .. ' ' .. window:active_workspace() .. ' ' },
        'ResetAttributes',
        { Background = { Color = c.crust } },
        { Foreground = { Color = c.lavender } },
        { Text = icons.round_right .. ' ' },
    })
end

local function right_status(agents)
    local counts = { permission = 0, question = 0, done = 0, working = 0 }
    for _, a in ipairs(agents) do
        if a.state == 'waiting' then
            local k = a.kind == 'question' and 'question' or 'permission'
            counts[k] = counts[k] + 1
        elseif counts[a.state] then
            counts[a.state] = counts[a.state] + 1
        end
    end

    local items = { { Background = { Color = c.crust } } }
    local function counter(key, color)
        if counts[key] > 0 then
            table.insert(items, { Foreground = { Color = color } })
            table.insert(items, { Text = icons[key] .. ' ' .. counts[key] .. '  ' })
        end
    end
    counter('permission', c.red)
    counter('question', c.red)
    counter('done', c.yellow)
    counter('working', c.green)

    table.insert(items, { Foreground = { Color = c.surface0 } })
    table.insert(items, { Text = icons.round_left })
    table.insert(items, { Background = { Color = c.surface0 } })
    table.insert(items, { Foreground = { Color = c.subtext0 } })
    table.insert(items, { Text = ' ' .. icons.host .. ' ' .. wezterm.hostname() .. ' ' })
    return wezterm.format(items)
end

wezterm.on('update-status', function(window)
    local agents = state.refresh()
    window:set_left_status(left_status(window))
    window:set_right_status(right_status(agents))
end)

return M
