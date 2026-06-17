local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
    config.unix_domains = {
        {
            name = 'unix',
        }
    }
end

return module;
