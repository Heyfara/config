local wezterm = require 'wezterm'
local styles = require 'styles'
local keys = require 'keys'
local mux = require 'mux'

local config = {}

config.enable_wayland = false

styles.apply_to_config(config)
keys.apply_to_config(config)
mux.apply_to_config(config)

return config
