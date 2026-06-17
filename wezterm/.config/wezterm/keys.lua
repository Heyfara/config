local wezterm = require 'wezterm'
local projects = require 'projects'

local module = {}

function module.apply_to_config(config)
    config.leader = {
        key = 'Space',
        mods = 'CTRL',
        timeout_milliseconds = 2000,
    }

    config.keys = {
        {
            key = 'a',
            mods = 'LEADER',
            action = wezterm.action.AttachDomain 'unix',
        },
        {
            key = 'd',
            mods = 'LEADER',
            action = wezterm.action.DetachDomain { DomainName = 'unix' },
        },
        {
            key = 'p',
            mods = 'LEADER',
            -- Present in to our project picker
            action = projects.choose_project(),
        },
        {
            key = 'f',
            mods = 'LEADER',
            -- Present a list of existing workspaces
            action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },
        },
        {
            key = 'c',
            mods = 'LEADER',
            action = wezterm.action.SpawnTab 'CurrentPaneDomain',
        },
        {
            key = 'x',
            mods = 'LEADER',
            action = wezterm.action.CloseCurrentPane { confirm = false },
        },
        {
            key = '%',
            mods = 'LEADER',
            action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
        },
        {
            key = 'q',
            mods = 'CTRL',
            action = wezterm.action.QuitApplication
        },
    }
end

wezterm.on('update-status', function(window)
    -- Grab the utf8 character for the "powerline" left facing
    -- solid arrow.
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

    -- Grab the current window's configuration, and from it the
    -- palette (this is the combination of your chosen colour scheme
    -- including any overrides).
    local color_scheme = window:effective_config().resolved_palette
    local bg = color_scheme.background
    local fg = color_scheme.foreground

    window:set_right_status(wezterm.format({
        -- First, we draw the arrow...
        { Background = { Color = 'none' } },
        { Foreground = { Color = bg } },
        { Text = SOLID_LEFT_ARROW },
        -- Then we draw our text
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        { Text = ' ' .. wezterm.hostname() .. ' ' },
    }))
end)

return module;
