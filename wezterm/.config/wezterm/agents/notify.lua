-- Notifications système quand un agent attend (permission, question) ou a fini.
-- Linux : notify-send (bouton « Afficher ») ; macOS : terminal-notifier (clic).
-- Le clic écrit <state_dir>/focus-request, consommé par M.consume_focus_request().
local wezterm = require 'wezterm'
local state = require 'agents.state'
local nav = require 'agents.nav'

local M = {}

-- Notifier aussi quand un agent a terminé son tour (souvent : il attend ta réponse)
M.notify_on_done = true

local FOCUS_FILE = state.dir .. '/focus-request'
local is_mac = wezterm.target_triple:find('apple%-darwin') ~= nil

local function first_existing(paths)
    for _, p in ipairs(paths) do
        local f = io.open(p, 'r')
        if f then f:close() return p end
    end
end

-- La session graphique macOS n'a pas le PATH Homebrew : chemins absolus.
local notifier = is_mac
    and first_existing({ '/opt/homebrew/bin/terminal-notifier', '/usr/local/bin/terminal-notifier' })
    or first_existing({ '/usr/bin/notify-send', '/usr/local/bin/notify-send' })

local function texts(agent)
    local name = agent.worktree or agent.label or ('panneau ' .. agent.pane_id)
    local what
    if agent.state == 'waiting' then
        what = agent.kind == 'question' and 'question' or 'permission requise'
    else
        what = 'terminé'
    end
    local title = name .. ' — ' .. what
    local where = agent.repo or agent.workspace or ''
    local body = agent.message ~= '' and (where .. '\n' .. agent.message) or where
    return title, body
end

local function send(window, agent)
    local title, body = texts(agent)

    if not notifier then
        window:toast_notification('Agent : ' .. title, body, nil, 8000)
        return
    end

    if is_mac then
        local args = {
            notifier,
            '-title', 'Agent Claude',
            '-subtitle', title,
            '-message', body ~= '' and body or title,
            '-group', 'wezterm-agent-' .. agent.pane_id,
            '-activate', 'com.github.wez.wezterm',
            '-execute', string.format("printf %%s %d > '%s'", agent.pane_id, FOCUS_FILE),
        }
        if agent.state == 'waiting' then
            table.insert(args, '-sound')
            table.insert(args, 'default')
        end
        wezterm.background_child_process(args)
    else
        -- notify-send -A bloque jusqu'au clic/fermeture : on attend dans un sh détaché.
        wezterm.background_child_process({
            'sh', '-c',
            'r=$("$1" -a WezTerm -i org.wezfurlong.wezterm -A default=Afficher -A focus=Afficher -- "$2" "$3"); '
                .. 'case "$r" in default|focus) printf %s "$4" > "$5";; esac',
            'sh', notifier, title, body, tostring(agent.pane_id), FOCUS_FILE,
        })
    end
end

-- Appelé à chaque update-status : notifie les transitions vers waiting/done.
-- Signature = état + type + message : pas de doublon entre fenêtres ni sur
-- des événements répétés, mais une nouvelle attente après un « working » renotifie.
function M.check(window, agents)
    local seen = wezterm.GLOBAL.agent_notified
    local first_run = seen == nil
    seen = seen or {}

    local focused = window:is_focused()
    local active_pane_id = window:active_pane():pane_id()

    local next_seen = {}
    for _, a in ipairs(agents) do
        local key = tostring(a.pane_id)
        local notifiable = a.state == 'waiting' or (a.state == 'done' and M.notify_on_done)
        if notifiable then
            local sig = a.state .. '|' .. a.kind .. '|' .. a.message
            next_seen[key] = sig
            local visible = focused and a.pane_id == active_pane_id
            if seen[key] ~= sig and not first_run and not visible then
                send(window, a)
            end
        end
        -- working/idle : pas d'entrée, la prochaine attente sera notifiée
    end
    wezterm.GLOBAL.agent_notified = next_seen
end

-- Clic sur une notification : sauter vers le panneau demandé.
function M.consume_focus_request(window)
    local f = io.open(FOCUS_FILE, 'r')
    if not f then return end
    local pane_id = tonumber(f:read('a'))
    f:close()
    os.remove(FOCUS_FILE)
    if pane_id then nav.focus_pane(window, pane_id) end
end

return M
