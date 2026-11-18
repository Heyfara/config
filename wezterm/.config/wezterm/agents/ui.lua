-- Barre de statut (et, à l'étape 2, badges d'onglets).
-- Seul gestionnaire `update-status` de la config.
local wezterm = require 'wezterm'
local state = require 'agents.state'

local M = {}

function M.apply_to_config(config)
    config.status_update_interval = 1000
end

wezterm.on('update-status', function(window)
    state.refresh()

    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
    local palette = window:effective_config().resolved_palette
    local bg = palette.background
    local fg = palette.foreground

    window:set_right_status(wezterm.format({
        { Background = { Color = 'none' } },
        { Foreground = { Color = bg } },
        { Text = SOLID_LEFT_ARROW },
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        { Text = ' ' .. wezterm.hostname() .. ' ' },
    }))
end)

return M
