-- Vue latérale à la demande (LEADER+b) : bin/agent-panel dans un split à gauche.
-- Le panneau envoie ses actions par la user var `agent_panel` (JSON base64,
-- décodé par WezTerm) : go / inspect / close sur un panneau ou un workspace.
local wezterm = require 'wezterm'
local act = wezterm.action
local nav = require 'agents.nav'
local tasks = require 'agents.tasks'

local M = {}

M.WIDTH = 46
M.TITLE = 'agent-panel'

local WEZTERM_BIN = wezterm.executable_dir .. '/wezterm'

-- Panneaux ouverts par LEADER+b : seuls autorisés à envoyer des actions
-- (sinon n'importe quelle sortie de terminal, ex. un cat ou un ssh, le pourrait).
local function registry()
    return wezterm.GLOBAL.agent_panels or {}
end

local function set_registered(pane_id, value)
    local r = registry()
    r[tostring(pane_id)] = value
    wezterm.GLOBAL.agent_panels = r
end

local function kill(pane_id)
    set_registered(pane_id, nil)
    wezterm.run_child_process({ WEZTERM_BIN, 'cli', 'kill-pane', '--pane-id', tostring(pane_id) })
end

-- LEADER+b : ouvre le panneau dans l'onglet courant, ou le ferme s'il y est
function M.toggle()
    return wezterm.action_callback(function(_, pane)
        for _, p in ipairs(pane:tab():panes()) do
            if registry()[tostring(p:pane_id())] then
                kill(p:pane_id())
                return
            end
        end
        local panel = pane:split({
            direction = 'Left',
            size = M.WIDTH,
            top_level = true,
            args = { wezterm.config_dir .. '/bin/agent-panel' },
            set_environment_variables = { AGENT_PANEL_WEZTERM = WEZTERM_BIN },
        })
        set_registered(panel:pane_id(), true)
        panel:activate()
    end)
end

wezterm.on('user-var-changed', function(window, pane, name, value)
    if name ~= 'agent_panel' then return end
    if not registry()[tostring(pane:pane_id())] then
        wezterm.log_warn('agent_panel ignoré : panneau ' .. pane:pane_id() .. ' non ouvert par LEADER+b')
        return
    end
    set_registered(pane:pane_id(), nil) -- une action par panneau : il se ferme ensuite
    local ok, msg = pcall(wezterm.serde.json_decode, value)
    if not ok or type(msg) ~= 'table' then return end

    if msg.kind == 'ws' then
        window:perform_action(act.SwitchToWorkspace { name = msg.value }, pane)
        return
    end

    local target_id = tonumber(msg.value)
    local okp, target = pcall(wezterm.mux.get_pane, target_id)
    if not okp or not target then return end

    if msg.cmd == 'go' then
        nav.focus_pane(window, target_id)
    elseif msg.cmd == 'inspect' then
        tasks.inspect_pane(window, target)
    elseif msg.cmd == 'close' then
        -- La boîte de dialogue s'affiche sur l'onglet de la tâche, une fois qu'on y est
        nav.focus_pane(window, target_id)
        wezterm.time.call_after(0.3, function()
            tasks.close_pane(window, target)
        end)
    end
end)

return M
