local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
    config.color_scheme = 'Catppuccin Mocha'
    --config.native_macos_fullscreen_mode = true

    -- With ligatures 
    --config.font = wezterm.font('JetBrainsMono Nerd Font')
    -- Without ligatures
    config.font = wezterm.font('JetBrainsMonoNL Nerd Font')

    --config.font = wezterm.font('JetBrains Mono')
    --config.font_size = 14
    --config.freetype_load_target = 'Light'
    --config.freetype_render_target = 'Light'

    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = true

    -- Connect to the unix domain on startup
    --config.default_gui_startup_args = { 'connect', 'unix' }

    config.window_frame = {
        --font = wezterm.font('MesloLG Nerd Font', { weight = 'Regular' }),
        --font_size = 12,
    }
end

return module;
