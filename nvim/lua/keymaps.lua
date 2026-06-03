-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("t", "<C-=>", "<C-\\><C-N><C-W><C-=>", { noremap = true })

-- [[ Personal keymaps ]]

-- Open init.lua
vim.keymap.set("n", "<leader>v", ":e ~/.config/nvim/init.lua<CR>", { noremap = true, silent = true })

-- Reverse highlighted lines
vim.keymap.set("v", "<leader>rv", [[:g/^/m <C-r>=line('.') - 1<CR><CR>]], { noremap = true, silent = true })

-- Shortcut for uncommenting a commented code block
vim.keymap.set("n", "gcu", "gcgc", { noremap = true, silent = true })

-- Open a file running watcher by executing the current file as a script
vim.api.nvim_set_keymap(
  "n",
  "<leader>te",
  ":bot 15sp | terminal chmod +x "
  .. vim.fn.expand("%")
  .. " && echo "
  .. vim.fn.expand("%")
  .. " | entr -c -r "
  .. vim.fn.expand("%")
  .. "<CR><C-w><C-k>",
  { noremap = true, silent = true, desc = "[T]erminal [E]xecute file" }
)

-- Open a file running watcher by executing the current file as a fish script
vim.api.nvim_set_keymap(
  "n",
  "<leader>tf",
  ":bot 15sp | terminal echo "
  .. vim.fn.expand("%")
  .. " | entr -c -r fish "
  .. vim.fn.expand("%")
  .. "<CR><C-w><C-k>",
  { noremap = true, silent = true, desc = "[T]erminal execute [F]ish file" }
)

-- Ex command shortcuts
vim.keymap.set("n", "<leader>j", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>k", ":q<CR>", { noremap = true, silent = true })

-- Regex substitute with very magic mode shortcut
vim.keymap.set("n", "(s", [[:%s#\v#&#g<left><left><left><left>]], { noremap = true, desc = "[Y]ou [G]o [s]ubstitue" })
vim.keymap.set("v", "(s", [[:s#\v#&#g<left><left><left><left>]], { noremap = true, desc = "[Y]ou [G]o [s]ubstitue" })
vim.keymap.set("n", "(v", ":%S///g<left><left><left>", { noremap = true, desc = "[Y]ou [G]o [S]ubvert" })
vim.keymap.set("v", "(v", ":S///g<left><left><left>", { noremap = true, desc = "[Y]ou [G]o [S]ubvert" })
vim.keymap.set("n", "(/", [[/\v]], { noremap = true, desc = "[Y]ou [G]o [/]" })
vim.keymap.set(
  "n",
  "(g",
  ":%g//norm <LEFT><LEFT><LEFT><LEFT><LEFT><LEFT>",
  { noremap = true, desc = "[Y]ou [G]o [G]lobal" }
)

vim.cmd([[
function! ReplaceAndMoveCursor()
  let cmdline = getcmdline()
  let pos = getcmdpos()

  if cmdline[pos-3:pos-2] == '*?'
    let newcmdline = cmdline[:pos-4] . '{-}' . cmdline[pos-1:]
    call setcmdpos(pos+1)
		return newcmdline
	endif
	return cmdline
endfunction
]])

-- Insert date in format: Monday, January 12 2026
vim.keymap.set("i", "<C-d>", function()
  -- %A = Full weekday name
  -- %B = Full month name
  -- %d = Day of the month (01-31)
  -- %Y = Four-digit year
  local date = os.date("%A, %B %d %Y")
  vim.api.nvim_put({ date }, "c", true, true)
end, { desc = "Insert human-readable date" })

-- Ex mapping to make very magic mode regex act like perl's regex by replacing perl's `*?` with `{-}` automatically
vim.api.nvim_set_keymap("c", "?", [[?<C-\>eReplaceAndMoveCursor()<CR>]], { noremap = true })

-- Paste all regex line matches to the current line
vim.keymap.set(
  "n",
  "<leader>gp",
  [[:mark z | g//t 'z<left><left><left><left><left>]],
  { noremap = true, desc = "[G]lobal [P]ut" }
)

-- Rerun the last terminal command and come back to the editor
vim.keymap.set("n", "<leader>rp", "<ESC><C-w>ji<UP><CR><C-\\><C-N><C-w>k", { noremap = true, desc = "[R]e[p]eat" })

-- Search from current file's directory
vim.keymap.set("n", "<leader>f", ":e %:h/**/*", { noremap = true })

-- Map the function to a key combination
vim.keymap.set("n", "<leader>`", ":lua toggle_background()<CR>", { noremap = true })

vim.keymap.set("n", "<leader>o", "O<ESC>j", { noremap = true })

-- d/D delete instead of cut
vim.keymap.set({ "n", "v" }, "d", '"_d', { noremap = true })
vim.keymap.set("n", "dd", '"_dd', { noremap = true })
vim.keymap.set("n", "D", '"_D', { noremap = true })
-- delete linewise over %
vim.keymap.set("n", "(d", [[V%"_d]], { noremap = true })

-- c/C delete instead of cut
vim.keymap.set({ "n", "v" }, "c", '"_c', { noremap = true })
vim.keymap.set("n", "cc", '"_cc', { noremap = true })
vim.keymap.set("n", "C", '"_C', { noremap = true })
-- delete linewise over %
vim.keymap.set("n", "(c", [[V%"_c]], { noremap = true })

-- x/X as cut motion
vim.keymap.set({ "n", "v" }, "x", "d", { noremap = true })
vim.keymap.set("n", "xx", "dd", { noremap = true })
vim.keymap.set("n", "X", "D", { noremap = true })
vim.keymap.set("n", "xp", '"zdl"zp', { noremap = true })
-- cut linewise over %
vim.keymap.set("n", "(x", [[V%d]], { noremap = true })

-- yank linewise over %
vim.keymap.set("n", "(y", [[V%y]], { noremap = true })

-- p deletes in visual mode
vim.keymap.set("v", "p", '"_dP', { noremap = true })

-- r replaces in normal mode
vim.keymap.set("n", "R", "r$", { noremap = true })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Macros ]]

-- Convert github URL to a string of the user/project
vim.cmd([[let @p="^yss'$a,\<Esc>F/;ldT'=="]])

-- vim: ts=2 sts=2 sw=2 et

-- Move up and down visual lines (wrapped text) by default, but use logical lines with a count
vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
