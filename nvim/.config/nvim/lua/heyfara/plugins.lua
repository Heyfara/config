-- Gestion des plugins via vim.pack (natif depuis Neovim 0.12)
-- Mises à jour : :lua vim.pack.update()
-- Lockfile     : ~/.config/nvim/nvim-pack-lock.json (à versionner avec git)

vim.pack.add({
    -- Fuzzy finder
    { src = "https://github.com/nvim-telescope/telescope.nvim", version = "0.1.8" },
    "https://github.com/nvim-lua/plenary.nvim",

    -- Thème
    "https://github.com/catppuccin/nvim",

    -- Statusline (remplace feline, peu maintenu)
    "https://github.com/nvim-lualine/lualine.nvim",
    "https://github.com/lewis6991/gitsigns.nvim",

    -- Treesitter (branche main, nouvelle API — requiert Neovim 0.12)
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },

    -- Explorateur de fichiers
    "https://github.com/nvim-tree/nvim-tree.lua",
    "https://github.com/nvim-tree/nvim-web-devicons",

    -- LSP : configs par défaut + installation des serveurs via Mason
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mason-org/mason-lspconfig.nvim",

    -- Debug Adapter Protocol
    "https://github.com/mfussenegger/nvim-dap",
    "https://github.com/nvim-neotest/nvim-nio",
    "https://github.com/rcarriga/nvim-dap-ui",

    -- Divers
    "https://github.com/jiaoshijie/undotree",
    "https://github.com/folke/flash.nvim",
    "https://github.com/catgoose/nvim-colorizer.lua",
})
