return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "[D]ebug toggle [B]reakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "[D]ebug conditional [B]reakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "[D]ebug [C]ontinue / start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "[D]ebug step [I]nto" },
      { "<leader>do", function() require("dap").step_over() end, desc = "[D]ebug step [O]ver" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "[D]ebug step [O]ut" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "[D]ebug toggle [R]epl" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "[D]ebug run [L]ast" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "[D]ebug [T]erminate" },
      {
        "<leader>dh",
        function() require("dap.ui.widgets").hover() end,
        mode = { "n", "v" },
        desc = "[D]ebug [H]over eval",
      },
    },
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "[D]ebug toggle [U]I" },
    },
    opts = {},
    config = function(_, opts)
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
    opts = {
      -- java is handled entirely by nvim-jdtls's setup_dap(), not here.
      ensure_installed = {},
      automatic_installation = true,
      handlers = {},
    },
  },
}
