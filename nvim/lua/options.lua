-- [[ Setting options ]]
-- See `:help vim.o`
-- For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

vim.opt.expandtab = true -- use spaces instead of tab characters
vim.opt.tabstop = 2 -- a <Tab> looks like 2 spaces
vim.opt.shiftwidth = 2 -- indentation uses 2 spaces
vim.opt.softtabstop = 2 -- <Tab>/<BS> behave like 2 spaces

-- Blocklist of Language Server (LS) errors/warnings
local codes_to_hide = {
	-- Marksman LS (markdown)
	"MD030", -- Spaces after list markers
	"MD007", -- Unordered list indentatio
	"MD013", -- Line length
	"MD034", -- Bare URL used
	"MD012", -- No multiple blank lines
	-- Cider LS
	"Cannot find module",
}

-- Check if a diagnostic code should be filtered out
local function is_blocked(diagnostic, blocklist)
	for _, block_code in ipairs(blocklist) do
		local diag_code = tostring(diagnostic.code or "")
		local diag_msg = diagnostic.message or ""
		if diag_code == block_code or string.find(diag_msg, block_code) then
			return true
		end
	end
	return false
end

-- Diagnostic filter wrapper
local function filter_handler(orig_handler)
	return {
		show = function(namespace, bufnr, diagnostics, opts)
			local filtered = {}
			for _, diag in ipairs(diagnostics) do
				if not is_blocked(diag, codes_to_hide) then
					table.insert(filtered, diag)
				end
			end
			orig_handler.show(namespace, bufnr, filtered, opts)
		end,
		hide = orig_handler.hide,
	}
end

vim.diagnostic.handlers.virtual_text = filter_handler(vim.diagnostic.handlers.virtual_text)
vim.diagnostic.handlers.signs = filter_handler(vim.diagnostic.handlers.signs)
