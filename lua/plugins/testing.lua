return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "nvim-treesitter/nvim-treesitter",
      "rcasia/neotest-java",
    },
    keys = {
      { "<leader>tr", function() require("neotest").run.run() end, desc = "[T]est [R]un nearest" },
      {
        "<leader>tf",
        function() require("neotest").run.run(vim.fn.expand("%")) end,
        desc = "[T]est run [F]ile",
      },
      {
        "<leader>ts",
        function() require("neotest").run.run(vim.uv.cwd()) end,
        desc = "[T]est run [S]uite",
      },
      {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "[T]est [D]ebug nearest",
      },
      { "<leader>tx", function() require("neotest").run.stop() end, desc = "[T]est stop" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "[T]est [O]utput" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "[T]est [O]utput panel" },
      { "<leader>tt", function() require("neotest").summary.toggle() end, desc = "[T]est [T]oggle summary" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-java")({
            ignore_wrapper = false,
          }),
        },
      })
    end,
  },
}
