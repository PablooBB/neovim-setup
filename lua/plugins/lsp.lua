return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- jdtls is intentionally excluded: it's driven by nvim-jdtls via
      -- ftplugin/java.lua, which needs project-aware setup vim.lsp.enable
      -- can't give it, so we don't want mason-lspconfig auto-enabling a
      -- second, plain jdtls client on top of it.
      ensure_installed = { "lua_ls", "jsonls", "yamlls", "marksman" },
      automatic_enable = { exclude = { "jdtls" } },
    },
  },

  {
    -- Ships the default per-server configs under lsp/*.lua, consumed by
    -- vim.lsp.config/vim.lsp.enable (the legacy require('lspconfig')
    -- "framework" used with .setup() is deprecated as of Neovim 0.11+).
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Goto Definition")
          map("gD", vim.lsp.buf.declaration, "Goto Declaration")
          map("gr", vim.lsp.buf.references, "Goto References")
          map("gI", vim.lsp.buf.implementation, "Goto Implementation")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("<leader>ds", vim.lsp.buf.document_symbol, "Document Symbols")
        end,
      })

      vim.diagnostic.config({
        virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })
    end,
  },
}
