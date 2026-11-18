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

return module;
