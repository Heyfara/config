local wezterm = require 'wezterm'
local styles = require 'styles'
local keys = require 'keys'
local mux = require 'mux'
local agents_ui = require 'agents.ui'

local config = {}

config.enable_wayland = false

styles.apply_to_config(config)
keys.apply_to_config(config)
mux.apply_to_config(config)
agents_ui.apply_to_config(config)

return config
