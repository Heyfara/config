-- Couleurs et icônes des agents. Catppuccin Mocha, comme styles.lua.
local wezterm = require 'wezterm'
local nf = wezterm.nerdfonts

local M = {}

M.colors = {
    crust = '#11111b',
    mantle = '#181825',
    base = '#1e1e2e',
    surface0 = '#313244',
    surface1 = '#45475a',
    overlay0 = '#6c7086',
    overlay1 = '#7f849c',
    subtext0 = '#a6adc8',
    subtext1 = '#bac2de',
    text = '#cdd6f4',
    lavender = '#b4befe',
    blue = '#89b4fa',
    green = '#a6e3a1',
    yellow = '#f9e2af',
    peach = '#fab387',
    red = '#f38ba8',
}

local c = M.colors

M.icons = {
    permission = nf.md_lock_alert,
    question = nf.md_chat_question,
    done = nf.md_check_circle,
    working = nf.md_robot,
    idle = nf.md_robot_outline,
    workspace = nf.md_folder,
    host = nf.md_monitor,
    round_right = nf.ple_right_half_circle_thick,
    round_left = nf.ple_left_half_circle_thick,
}

-- Style d'un agent : icône + soit un fond plein (urgent), soit une couleur d'icône.
function M.agent_style(agent)
    local s = agent.state
    if s == 'waiting' then
        local icon = agent.kind == 'question' and M.icons.question or M.icons.permission
        return { icon = icon, bg = c.red }
    elseif s == 'done' then
        return { icon = M.icons.done, bg = c.yellow }
    elseif s == 'working' then
        return { icon = M.icons.working, fg = c.green }
    end
    return { icon = M.icons.idle, fg = c.overlay0 }
end

return M
