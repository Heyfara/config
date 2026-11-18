local wezterm = require 'wezterm'
local projects = require 'projects'
local pickers = require 'agents.pickers'
local tasks = require 'agents.tasks'

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
            -- Workspaces en arborescence avec badges d'agents
            action = pickers.workspaces(),
        },
        {
            key = 's',
            mods = 'LEADER',
            -- Tous les agents, triés par urgence
            action = pickers.agents(),
        },
        {
            key = 'n',
            mods = 'LEADER',
            -- Nouvelle tâche : onglet + claude -w <nom>
            action = tasks.new_task(),
        },
        {
            key = ',',
            mods = 'LEADER',
            action = tasks.rename_tab(),
        },
        {
            key = 'j',
            mods = 'LEADER',
            -- Agent qui attend depuis le plus longtemps
            action = pickers.jump_next(),
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
