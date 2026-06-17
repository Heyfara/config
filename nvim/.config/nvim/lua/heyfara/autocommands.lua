-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Gros fichiers : couper les features coûteuses (remplace bigfile.nvim).
-- treesitter.lua saute le highlight si vim.b.bigfile est vrai.
local bigfile = vim.api.nvim_create_augroup('bigfile', { clear = true })
local BIGFILE_BYTES = 2 * 1024 * 1024 -- 2 MiB

vim.api.nvim_create_autocmd('BufReadPre', {
  desc = 'Marquer et alléger les gros fichiers',
  group = bigfile,
  callback = function(ev)
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if stat and stat.size > BIGFILE_BYTES then
      vim.b[ev.buf].bigfile = true
      vim.opt_local.swapfile = false
      vim.opt_local.undofile = false
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.list = false
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Couper la coloration regex sur les gros fichiers (après détection ft)',
  group = bigfile,
  callback = function(ev)
    if vim.b[ev.buf].bigfile then
      -- différé pour passer après le mécanisme natif `syntax on`
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          vim.bo[ev.buf].syntax = 'OFF'
        end
      end)
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Ne pas attacher de serveur LSP aux gros fichiers',
  group = bigfile,
  callback = function(ev)
    if vim.b[ev.buf].bigfile then
      vim.schedule(function()
        vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
      end)
    end
  end,
})
