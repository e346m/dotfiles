local vim = vim
local api = vim.api
vim.o.number = true --行番号表示
vim.o.showmode = true --モード表示
vim.o.title = true --編集中のファイル名を表示
vim.o.ruler = true --ルーラーの表示
vim.o.smartindent = true --オートインデント
vim.o.showcmd = true --入力中のコマンドをステータスに表示する
vim.o.showmatch = true --括弧入力時の対応する括弧を表示
vim.o.laststatus = 3 --ステータスラインを常に表示
vim.o.cursorline = true
vim.o.colorcolumn = "100"
vim.o.wrap = true
vim.o.smoothscroll = true
vim.o.mousescroll = "ver:1,hor:6"
vim.o.backspace = "indent,eol,start"

-- tab
vim.o.expandtab = true --タブの代わりに空白文字挿入

-- search
vim.o.ignorecase = true --検索文字列が小文字の場合は大文字小文字を区別なく検索する
vim.o.smartcase = true --検索文字列に大文字が含まれている場合は区別して検索する
vim.o.wrapscan = true --検索時に最後まで行ったら最初に戻る
vim.o.incsearch = true --検索文字列入力時に順次対象文字列にヒットさる
vim.o.spell = true
vim.o.spelllang = "en_us,cjk"

-- clipboard
vim.o.clipboard = "unnamedplus"

-- colorscheme
vim.o.termguicolors = true
vim.cmd("colorscheme gruvbox-material")
vim.o.background = "dark"
vim.g.gruvbox_material_background = "soft"
vim.g.gruvbox_material_vetter_performance = 1

-- tabs
vim.cmd([[set sw=2 sts=2 ts=2]])
vim.cmd([[autocmd FileType go set sw=4 sts=4 ts=4]])

-- remove space
vim.cmd([[ autocmd BufWritePre * :%s/\s\+$//ge ]])

-- fold
vim.opt.fillchars = { fold = " " }
vim.opt.foldmethod = "indent"
vim.opt.foldenable = false
vim.opt.foldlevel = 99

-- blame
vim.g.blamer_enabled = true
vim.g.blamer_show_in_insert_modes = 0
vim.g.blamer_prefix = " > "

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

-- neo-tree as a persistent left drawer (Agentic occupies the right)
require("neo-tree").setup({
	close_if_last_window = false,
	popup_border_style = "single",
	sources = { "filesystem", "git_status", "buffers" },
	source_selector = {
		winbar = true,
		sources = {
			{ source = "filesystem", display_name = " Files " },
			{ source = "git_status", display_name = " Git " },
		},
	},
	window = {
		position = "left",
		width = 28,
		mappings = {
			["<C-h>"] = "none",
			["<C-l>"] = "none",
			["<C-j>"] = "none",
			["<C-k>"] = "none",
			["<"] = "prev_source",
			[">"] = "next_source",
		},
	},
	filesystem = {
		follow_current_file = { enabled = true, leave_dirs_open = true },
		hijack_netrw_behavior = "disabled",
		use_libuv_file_watcher = true,
		filtered_items = {
			hide_dotfiles = false,
			hide_gitignored = true,
		},
	},
})

vim.keymap.set("n", "<C-e>", function()
	require("neo-tree.command").execute({
		source = "filesystem",
		toggle = true,
		reveal = true,
		position = "left",
	})
end, { noremap = true, silent = true, desc = "Toggle file tree" })

vim.keymap.set("n", "<leader>E", function()
	require("neo-tree.command").execute({
		source = "git_status",
		toggle = true,
		position = "left",
	})
end, { noremap = true, silent = true, desc = "Toggle git changes tree" })

---- Add leader shortcuts
vim.api.nvim_set_keymap(
	"n",
	"<leader><space>",
	[[<cmd>lua require('telescope.builtin').buffers()<CR>]],
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>f",
	[[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]],
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>b",
	[[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]],
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>h",
	[[<cmd>lua require('telescope.builtin').help_tags()<CR>]],
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>g",
	[[<cmd>lua require('telescope.builtin').grep_string()<CR>]],
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>p",
	[[<cmd>lua require('telescope.builtin').live_grep()<CR>]],
	{ noremap = true, silent = true }
)

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
api.nvim_set_keymap("i", '""', '""<Left>', { noremap = true })
api.nvim_set_keymap("i", "''", "''<Left>", { noremap = true })
api.nvim_set_keymap("i", "``", "``<Left>", { noremap = true })
api.nvim_set_keymap("i", ",", ",<Space>", { noremap = true })

-- Native insert-mode completion (replaces nvim-cmp).
vim.o.completeopt = "menu,menuone,noselect,popup"
vim.o.autocomplete = true
vim.o.pumborder = "single"
vim.o.winborder = "single"

require("snippy").setup({
	mappings = {
		nx = {
			["<leader>x"] = "cut_text",
		},
	},
})

local function pum_visible()
	return vim.fn.pumvisible() == 1
end

vim.keymap.set({ "i", "s" }, "<Tab>", function()
	if pum_visible() then
		return "<C-n>"
	end
	if require("snippy").can_expand_or_advance() then
		return "<Cmd>lua require('snippy').expand_or_advance()<CR>"
	end
	return "<Tab>"
end, { expr = true })

vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
	if pum_visible() then
		return "<C-p>"
	end
	if require("snippy").can_jump(-1) then
		return "<Cmd>lua require('snippy').previous()<CR>"
	end
	return "<S-Tab>"
end, { expr = true })

vim.keymap.set("i", "<CR>", function()
	if not pum_visible() then
		return "<CR>"
	end
	if vim.fn.complete_info({ "selected" }).selected == -1 then
		return "<C-n><C-y>"
	end
	return "<C-y>"
end, { expr = true })

vim.keymap.set("i", "<C-Space>", function()
	vim.lsp.completion.get()
end)

vim.api.nvim_create_autocmd("FileType", {
	pattern = "AgenticInput",
	callback = function()
		vim.bo.autocomplete = false
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			-- Trigger on every keypress so it behaves closer to nvim-cmp.
			local chars = {}
			for i = 32, 126 do
				table.insert(chars, string.char(i))
			end
			client.server_capabilities.completionProvider.triggerCharacters = chars
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end

		local bufmap = function(mode, lhs, rhs)
			vim.keymap.set(mode, lhs, rhs, { buffer = true })
		end

		bufmap("n", "K", vim.lsp.buf.hover)
		bufmap("n", "gd", vim.lsp.buf.definition)
		bufmap("n", "gD", vim.lsp.buf.declaration)
		bufmap("n", "gi", vim.lsp.buf.implementation)
		bufmap("n", "go", vim.lsp.buf.type_definition)
		bufmap("n", "gr", vim.lsp.buf.references)
		bufmap("n", "gs", vim.lsp.buf.signature_help)
		bufmap("n", "<F2>", vim.lsp.buf.rename)
		bufmap("n", "<F3>", function()
			vim.lsp.buf.format({ async = true })
		end)
		bufmap("n", "<F4>", vim.lsp.buf.code_action)
		bufmap("x", "<F4>", vim.lsp.buf.code_action)
		bufmap("n", "gl", vim.diagnostic.open_float)
		bufmap("n", "[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end)
		bufmap("n", "]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end)
	end,
})

-- nvim-lspconfig still supplies lsp/*.lua server defs; enable them natively.
vim.lsp.config("gopls", {
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
			gofumpt = true,
		},
	},
})
vim.lsp.config("hls", {
	filetypes = { "haskell", "lhaskell", "cabal" },
})
-- Default filetypes include TS/JS/MD and steal hover / flood lsp.log.
vim.lsp.config("htmx", {
	filetypes = { "html" },
})
-- cmd comes from nvim-lspconfig (sets cwd to root). The ruby-lsp on PATH is a
-- wrapper that isolates GEM_* and skips composed-bundle install.
vim.lsp.config("ruby_lsp", {
	filetypes = { "ruby", "eruby" },
	root_markers = { "Gemfile", ".git" },
	init_options = {
		formatter = "auto",
		addonSettings = {
			["Ruby LSP Rails"] = {
				enablePendingMigrationsPrompt = false,
			},
		},
	},
})
-- ftplugin/ruby.vim sets keywordprg=ri; nvim's Ruby 3.3.8 then loads
-- ~/.local/share/gem native exts built for 3.3.10 and crashes.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "ruby", "eruby" },
	callback = function(ev)
		vim.bo[ev.buf].keywordprg = ""
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "LSP hover" })
	end,
})

vim.lsp.enable({
	"lua_ls",
	"ts_ls",
	"jsonls",
	"graphql",
	"gopls",
	"hls",
	"terraformls",
	"htmx",
	"roc_ls",
	"pyright",
	"ruby_lsp",
})

-- https://github.com/stevearc/conform.nvim/tree/master
-- null-lsの代替みたいなを使って、formatしたほうがよいか? go以外の言語をサポートする必要もあるし...
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	pattern = { "*.tf", "*.tfvars" },
	callback = function()
		vim.lsp.buf.format()
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.go",
	callback = function(args)
		local params = vim.lsp.util.make_range_params(0, "utf-16")
		params.context = { only = { "source.organizeImports" } }
		local result = vim.lsp.buf_request_sync(args.buf, "textDocument/codeAction", params)
		for cid, res in pairs(result or {}) do
			for _, r in pairs(res.result or {}) do
				if r.edit then
					local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
					vim.lsp.util.apply_workspace_edit(r.edit, enc)
				end
			end
		end
		vim.lsp.buf.format({ async = false })
	end,
})

require("lint").linters_by_ft = {
	javascript = { "biomejs" },
	typescript = { "biomejs" },
	javascriptreact = { "biomejs" },
	typescriptreact = { "biomejs" },
	json = { "biomejs" },
	jsx = { "biomejs" },
	tsx = { "biomejs" },
}

local function has_biome_config()
	return vim.fs.find({ "biome.json", "biome.jsonc" }, {
		upward = true,
		path = vim.fn.expand("%:p:h"),
		stop = vim.fn.expand("~"),
	})[1] ~= nil
end

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		if has_biome_config() then
			require("lint").try_lint()
		end
	end,
})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettierd", "prettier", "biome", stop_after_first = true },
		typescript = { "prettierd", "prettier", "biome", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", "biome", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", "biome", stop_after_first = true },
		json = { "prettierd", "prettier", "biome", stop_after_first = true },
		graphql = { "prettierd", "prettier", "biome", stop_after_first = true },
	},
})

-- LSPのフォーマッターも動いてるし、goに限ってはカスタムのフォーマットも作成しているし、どこかで整理する
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})

vim.api.nvim_command("au BufRead,BufNewFile *.tf,*.tfvars set filetype=terraform")
vim.treesitter.language.register("hcl", "terraform")
-- nvim-treesitter main no longer has configs.setup; highlighting is native.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		pcall(vim.treesitter.start, ev.buf)
	end,
})
-- vim.treesitter.language.register("glimmer", "hbs")
vim.cmd("autocmd BufRead,BufNewFile *.hbs set filetype=html")

-- Breadcrumbs: path + LSP/treesitter symbols in the winbar
vim.o.mousemoveevent = true
require("dropbar").setup()
vim.keymap.set("n", "<leader>;", function()
	require("dropbar.api").pick()
end, { desc = "Pick dropbar crumb" })

require("render-markdown").setup({
	file_types = { "markdown", "md", "AgenticChat" },
	-- Streaming + virt_lines で CursorMoved のたびに描画し直すとカクつく。
	overrides = {
		filetype = {
			AgenticChat = {
				anti_conceal = { enabled = false },
				debounce = 200,
			},
		},
	},
})

require("agentic").setup({
	provider = "cursor-acp",
	windows = {
		position = "right",
		width = "30%",
		chat = {
			win_opts = {
				smoothscroll = true,
			},
		},
	},
})

vim.keymap.set({ "n", "v" }, "<leader>ac", function()
	require("agentic").toggle()
end, { desc = "Toggle Agentic" })
vim.keymap.set("n", "<leader>af", function()
	require("agentic").open({ focus_prompt = true })
end, { desc = "Focus Agentic" })
vim.keymap.set("n", "<leader>ar", function()
	require("agentic").restore_session()
end, { desc = "Restore Agentic session" })
vim.keymap.set({ "n", "v" }, "<leader>an", function()
	require("agentic").new_session()
end, { desc = "New Agentic session" })
vim.keymap.set({ "n", "v" }, "<leader>ab", function()
	require("agentic").add_selection_or_file_to_context()
end, { desc = "Add file or selection to Agentic" })
vim.keymap.set("v", "<leader>as", function()
	require("agentic").add_selection()
end, { desc = "Send selection to Agentic" })

-- Hunk stays in a bottom split so Agentic remains visible.
-- Hide the window instead of quitting the TUI, or the daemon session dies.
local hunk = { bufnr = nil, winid = nil }

local function hunk_job_alive()
	if not hunk.bufnr or not vim.api.nvim_buf_is_valid(hunk.bufnr) then
		return false
	end
	local job = vim.b[hunk.bufnr].terminal_job_id
	return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function hunk_hide()
	if hunk.winid and vim.api.nvim_win_is_valid(hunk.winid) then
		vim.api.nvim_win_hide(hunk.winid)
	end
	hunk.winid = nil
end

local function hunk_editor_win()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.bo[buf].filetype
		if
			ft ~= "neo-tree"
			and not vim.startswith(ft, "Agentic")
			and vim.bo[buf].buftype ~= "terminal"
		then
			return win
		end
	end
	return vim.api.nvim_get_current_win()
end

vim.keymap.set("n", "<leader>D", function()
	if hunk.winid and vim.api.nvim_win_is_valid(hunk.winid) then
		hunk_hide()
		return
	end

	if hunk_job_alive() then
		vim.api.nvim_set_current_win(hunk_editor_win())
		vim.cmd("botright split")
		hunk.winid = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(hunk.winid, hunk.bufnr)
		vim.api.nvim_win_set_height(hunk.winid, math.max(12, math.floor(vim.o.lines * 0.4)))
		vim.cmd("startinsert")
		return
	end

	local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
	vim.api.nvim_set_current_win(hunk_editor_win())
	vim.cmd("botright split")
	hunk.winid = vim.api.nvim_get_current_win()
	vim.cmd("lcd " .. vim.fn.fnameescape(root))
	vim.cmd("terminal hunk diff")
	hunk.bufnr = vim.api.nvim_get_current_buf()
	vim.bo[hunk.bufnr].bufhidden = "hide"
	vim.api.nvim_win_set_height(hunk.winid, math.max(12, math.floor(vim.o.lines * 0.4)))
	vim.keymap.set("t", "q", function()
		vim.cmd("stopinsert")
		hunk_hide()
	end, { buffer = hunk.bufnr, desc = "Hide Hunk (keep session)" })
	vim.keymap.set("t", "<C-q>", function()
		vim.cmd("stopinsert")
		hunk_hide()
	end, { buffer = hunk.bufnr, desc = "Hide Hunk (keep session)" })
	vim.api.nvim_create_autocmd("TermClose", {
		buffer = hunk.bufnr,
		once = true,
		callback = function()
			hunk.bufnr = nil
			hunk.winid = nil
		end,
	})
	vim.cmd("startinsert")
end, { desc = "Toggle Hunk review split" })
