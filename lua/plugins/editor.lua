return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "[F]ind [F]iles" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "[F]ind by [G]rep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "[F]ind [B]uffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "[F]ind [H]elp" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "[F]ind [R]ecent files" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "[F]ind document [S]ymbols" },
      { "<leader>fw", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "[F]ind [W]orkspace symbols" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "[F]ind [D]iagnostics" },
    },
    config = function()
      require("telescope").setup({
        extensions = {
          fzf = {},
        },
      })
      pcall(require("telescope").load_extension, "fzf")
    end,
  },

  {
    -- Full rewrite as of nvim-treesitter's `main` branch (requires Nvim
    -- 0.12+, which we have): no more `configs.setup()`/`highlight.enable`.
    -- Parser install/update via `require('nvim-treesitter').install(...)`;
    -- highlighting/indent are enabled per-filetype below.
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "java", "json", "yaml", "xml", "groovy",
        "lua", "vim", "vimdoc", "markdown", "markdown_inline",
        "gitcommit", "bash",
      }
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = parsers,
        callback = function()
          pcall(vim.treesitter.start)
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo[0][0].foldmethod = "expr"
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },

  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },
}
