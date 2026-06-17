vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        -- Neovim 0.11+ mappe déjà nativement (à l'attache) : K (hover),
        -- grn (rename), gra (code action), gri (implementation),
        -- grt (type definition), grr (references), gO (symboles),
        -- ]d / [d (diagnostics). On n'ajoute que ce qui manque.
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = event.buf })

        -- Complétion LSP native (popup omnifunc + déclenchement auto sur les
        -- caractères du serveur, ex. -> :: . ). Accepter : <C-y>.
        if vim.lsp.completion then
            vim.lsp.completion.enable(true, event.data.client_id, event.buf, {
                autotrigger = true,
            })
        end
    end
})

-- clangd : interroger le compilateur croisé xtensa (ESP8266/PlatformIO)
-- pour éviter les conflits de typedef (uint64_t) avec les headers de clang
vim.lsp.config('clangd', {
    cmd = {
        'clangd',
        '--query-driver=' .. vim.fn.expand('$HOME')
            .. '/.platformio/packages/toolchain-xtensa/bin/xtensa-lx106-elf-*',
        '--background-index',
    },
})

-- Mason installe les binaires ; mason-lspconfig (v2) appelle automatiquement
-- vim.lsp.enable() pour chaque serveur installé (automatic_enable par défaut).
-- Les configs par défaut viennent de nvim-lspconfig (dossier lsp/).
require('mason').setup()
require('mason-lspconfig').setup({
    ensure_installed = {
        'lua_ls',
        'phpactor',
        'eslint',
        'html',
        'clangd',
    }
})
