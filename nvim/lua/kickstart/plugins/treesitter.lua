return {
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
		init = function()
			-- Workaround for Neovim 0.12 treesitter race condition where line deletions (e.g. `dd`)
			-- cause decoration providers to evaluate query predicates on stale node ranges,
			-- throwing "Index out of bounds" errors in `nvim_buf_get_text`.
			local orig_get_node_text = vim.treesitter.get_node_text
			vim.treesitter.get_node_text = function(node, source, opts)
				local ok, text = pcall(orig_get_node_text, node, source, opts)
				if ok and text then
					return text
				end
				return ""
			end

			local orig_get_range = vim.treesitter.get_range
			vim.treesitter.get_range = function(node, source, metadata)
				local ok, range = pcall(orig_get_range, node, source, metadata)
				if ok and range then
					return range
				end
				local ok_raw, raw_range = pcall(function()
					return { node:range(true) }
				end)
				if ok_raw and raw_range then
					return raw_range
				end
				return { 0, 0, 0, 0, 0, 0 }
			end

			if vim.treesitter._range and vim.treesitter._range.add_bytes then
				local orig_add_bytes = vim.treesitter._range.add_bytes
				vim.treesitter._range.add_bytes = function(source, range)
					local ok, res = pcall(orig_add_bytes, source, range)
					if ok and res then
						return res
					end
					local srow, scol, erow, ecol = 0, 0, 0, 0
					if type(range) == "table" then
						local ok_unpack, r1, r2, r3, r4 = pcall(vim.treesitter._range.unpack4, range)
						if ok_unpack then
							srow, scol, erow, ecol = r1 or 0, r2 or 0, r3 or 0, r4 or 0
						end
					end
					return { srow, scol, 0, erow, ecol, 0 }
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(args.match) or args.match
					if vim.treesitter.language.add(lang) and vim.treesitter.query.get(lang, "highlights") ~= nil then
						vim.treesitter.start(args.buf, lang)
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
		config = function()
			require("nvim-treesitter").setup()
			require("nvim-treesitter").install({
				"bash",
				"c",
				"cpp",
				"diff",
				"fish",
				"go",
				"graphql",
				"html",
				"java",
				"javascript",
				"jq",
				"json",
				"json5",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"perl",
				"php",
				"proto",
				"python",
				"query",
				"regex",
				"rust",
				"scss",
				"starlark",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			})
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
