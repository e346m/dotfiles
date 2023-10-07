local vim         = vim
local api         = vim.api
vim.o.number      = true --行番号表示
vim.o.showmode    = true --モード表示
vim.o.title       = true --編集中のファイル名を表示
vim.o.ruler       = true --ルーラーの表示
vim.o.smartindent = true --オートインデント
vim.o.showcmd     = true --入力中のコマンドをステータスに表示する
vim.o.showmatch   = true --括弧入力時の対応する括弧を表示
vim.o.laststatus  = 2    --ステータスラインを常に表示
vim.o.cursorline  = true
vim.o.colorcolumn = '100'
vim.o.wrap        = true
vim.o.backspace   = 'indent,eol,start'

-- tab
vim.o.expandtab   = true --タブの代わりに空白文字挿入

-- search
vim.o.ignorecase  = true --検索文字列が小文字の場合は大文字小文字を区別なく検索する
vim.o.smartcase   = true --検索文字列に大文字が含まれている場合は区別して検索する
vim.o.wrapscan    = true --検索時に最後まで行ったら最初に戻る
vim.o.incsearch   = true --検索文字列入力時に順次対象文字列にヒットさる
vim.o.hlsearch    = true --Highlight search = true result
vim.o.spell       = true
vim.o.spelllang   = 'en_us,cjk'


-- clipboard
vim.o.clipboard = "unnamedplus"

-- colorscheme
vim.o.termguicolors = true
vim.cmd 'colorscheme gruvbox-material'
vim.o.background = "dark"
vim.g.gruvbox_material_background = "soft"
vim.g.gruvbox_material_vetter_performance = 1

-- tabs
vim.cmd [[set sw=2 sts=2 ts=2]]
vim.cmd [[autocmd FileType go set sw=4 sts=4 ts=4]]

-- remove space
vim.cmd [[ autocmd BufWritePre * :%s/\s\+$//ge ]]

-- Key mappings

--- nnoremap

---- wrapped line move
api.nvim_set_keymap("n", "j", "gj", { noremap = true })
api.nvim_set_keymap("n", "k", "gk", { noremap = true })

---- panel switch
api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { noremap = true })
api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { noremap = true })
api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { noremap = true })
api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { noremap = true })

---- myvimrc
api.nvim_set_keymap("n", "<Space>.", ":<Esc>:edit $MYVIMRC<Enter>", { noremap = true })
api.nvim_set_keymap("n", "<Space>s", ":<Esc>:source $MYVIMRC<Enter>", { noremap = true })

---- split window
api.nvim_set_keymap("n", "<C-g>", ":<C-U>vsplit<Cr>", { noremap = true })
api.nvim_set_keymap("n", "<C-e>", ":<C-U>Fern . -reveal=%<Cr>", { noremap = true })

---- Add leader shortcuts
vim.api.nvim_set_keymap('n', '<leader><space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]],
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]],
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>b', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]],
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>h', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]],
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>g', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]],
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>p', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]],
  { noremap = true, silent = true })


--- inoremap
api.nvim_set_keymap("i", "jj", "<esc>", { noremap = true })
api.nvim_set_keymap("i", "<C-j>", "<Down>", { noremap = true })
api.nvim_set_keymap("i", "<C-k>", "<Up>", { noremap = true })
api.nvim_set_keymap("i", "<C-h>", "<Left>", { noremap = true })
api.nvim_set_keymap("i", "<C-l>", "<Right>", { noremap = true })

api.nvim_set_keymap("i", "()", "()<Left>", { noremap = true })
api.nvim_set_keymap("i", "{}", "{}<Left>", { noremap = true })
api.nvim_set_keymap("i", "[]", "[]<Left>", { noremap = true })
api.nvim_set_keymap("i", "<>", "<><Left>", { noremap = true })
api.nvim_set_keymap("i", "\"\"", "\"\"<Left>", { noremap = true })
api.nvim_set_keymap("i", "''", "''<Left>", { noremap = true })
api.nvim_set_keymap("i", "``", "``<Left>", { noremap = true })
api.nvim_set_keymap("i", ",", ",<Space>", { noremap = true })

local fn = vim.fn

vim.opt.completeopt = "menu,menuone,noselect"

vim.cmd [[ autocmd BufWritePost <buffer> lua vim.lsp.buf.format() ]]

local cmp = require 'cmp'
cmp.setup({
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = 'menu'

      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        look = "[Dict]",
        buffer = "[Buffer]",
      })[entry.source.name]
      return vim_item
    end
  },
  snippet = {},
  window = {
    completion = cmp.config.window.bordered({
      border = 'single'
    }),
    documentation = cmp.config.window.bordered({
      border = 'single'
    }),
  },
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'path' },
  }, {
    { name = 'buffer', keyword_length = 2 },
  })
})

cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})


vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function()
    local bufmap = function(mode, lhs, rhs)
      local opts = { buffer = true }
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')
    bufmap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')
    bufmap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')
    bufmap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')
    bufmap('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
    bufmap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>')
    bufmap('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
    bufmap('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>')
    bufmap('n', '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>')
    bufmap('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>')
    bufmap('x', '<F4>', '<cmd>lua vim.lsp.buf.range_code_action()<cr>')
    bufmap('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
    bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
    bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
  end
})

local lspconfig = require('lspconfig')
local lsp_defaults = lspconfig.util.default_config

lsp_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lsp_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)

lsp_defaults.capabilities.textDocument.completion.completionItem.snippetSupport = false

lspconfig.lua_ls.setup({
  single_file_support = true,
  flags = {
    debounce_text_changes = 150,
  }
})

lspconfig.rnix.setup({})
lspconfig.tsserver.setup({})
lspconfig.gopls.setup({})