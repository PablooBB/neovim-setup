return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
      "williamboman/mason.nvim",
    },
  },

  -- Make sure mason has jdtls + the debug/test bundles that jdtls_setup.lua
  -- reads back out to build nvim-dap support and test discovery.
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "jdtls", "java-debug-adapter", "java-test" })
    end,
  },
}
