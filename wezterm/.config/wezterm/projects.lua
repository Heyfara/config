local wezterm = require 'wezterm'
local module = {}

local dirs = {
    wezterm.home_dir .. "/Sites",
    wezterm.home_dir .. "/Documents/Dev",
}

local function project_dirs()
    -- Add the home directory
    local projects = { wezterm.home_dir }

    for _, project_dir in ipairs(dirs) do
        -- Récupère tous les sous-dossiers dans chaque racine
        for _, dir in ipairs(wezterm.glob(project_dir .. '/*')) do
            table.insert(projects, dir)
        end
    end

    return projects
end

function module.choose_project()
    local choices = {}
    for _, value in ipairs(project_dirs()) do
        table.insert(choices, { label = value })
    end

    return wezterm.action.InputSelector {
        title = "Projects",
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(child_window, child_pane, id, label)
            -- "label" may be empty if nothing was selected. Don't bother doing anything
            -- when that happens.
            if not label then return end

            -- Switch to the workspace
            child_window:perform_action(wezterm.action.SwitchToWorkspace {
                name = label:match("([^/]+)$"),
                spawn = { cwd = label },
            }, child_pane)

            wezterm.sleep_ms(100)

            local first_pane = child_window:active_pane()
            child_window:perform_action(wezterm.action.SendString("nvim\n"), first_pane)

            child_window:perform_action(wezterm.action.SpawnTab("CurrentPaneDomain"), first_pane)

            wezterm.sleep_ms(100)

            child_window:perform_action(wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" }, first_pane)

            wezterm.sleep_ms(100)

            local right_pane = child_window:active_pane()
            child_window:perform_action(wezterm.action.ActivatePaneDirection("Left"), right_pane)
            local left_pane = child_window:active_pane()

            child_window:perform_action(wezterm.action.ActivatePaneDirection("Right"), left_pane)

            child_window:perform_action(wezterm.action.SpawnTab("CurrentPaneDomain"), first_pane)

            wezterm.sleep_ms(100)

            local new_pane = child_window:active_pane()
            child_window:perform_action(wezterm.action.SendString("lazygit\n"), new_pane)

            first_pane:activate()
        end),
    }
end

return module
