return {
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
		init = function()
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
