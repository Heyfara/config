local dap = require 'dap'

-- Adaptateur PHP/Xdebug fourni par Mason (php-debug-adapter).
-- Installation : :MasonInstall php-debug-adapter
local php_debug = vim.fn.stdpath('data')
    .. '/mason/packages/php-debug-adapter/extension/out/phpDebug.js'

dap.adapters.php = {
    type = 'executable',
    command = 'node',
    args = { php_debug }
}

dap.configurations.php = {
    {
        type = 'php',
        request = 'launch',
        name = 'Listen for Xdebug',
        port = 9003,
        pathMappings = {
            ["/application"] = "${workspaceFolder}"
        }
    }
}
