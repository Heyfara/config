-- Navigation vers un panneau, où qu'il soit (autre onglet, autre workspace).
local wezterm = require 'wezterm'

local M = {}

function M.focus_pane(window, pane_id)
    local ok, pane = pcall(wezterm.mux.get_pane, pane_id)
    if not ok or not pane then return false end
    local tab = pane:tab()
    local mux_window = tab and tab:window()
    if not mux_window then return false end

    local workspace = mux_window:get_workspace()
    if workspace ~= window:active_workspace() then
        window:perform_action(wezterm.action.SwitchToWorkspace { name = workspace }, window:active_pane())
    end
    tab:activate()
    pane:activate()
    window:focus()
    return true
end

return M
