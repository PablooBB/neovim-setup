local function find_up(filename)
  local dir = vim.fn.getcwd()
  local found = vim.fs.find(filename, { path = dir, upward = true })[1]
  return found
end

local function run_in_term(cmd)
  local Terminal = require("toggleterm.terminal").Terminal
  local term = Terminal:new({
    cmd = cmd,
    direction = "float",
    close_on_exit = false,
    float_opts = { border = "curved" },
  })
  term:toggle()
end

local function maven_runner()
  local wrapper = find_up("mvnw")
  local mvn = wrapper or "mvn"
  local goals = { "compile", "test", "package", "clean install", "spring-boot:run", "clean" }
  vim.ui.select(goals, { prompt = "Maven goal (" .. mvn .. ")" }, function(goal)
    if goal then
      run_in_term(("%s %s"):format(mvn, goal))
    end
  end)
end

local function gradle_runner()
  local wrapper = find_up("gradlew")
  if not wrapper then
    vim.notify("No ./gradlew wrapper found in this project", vim.log.levels.WARN)
    return
  end
  local tasks = { "build", "test", "bootRun", "clean", "assemble" }
  vim.ui.select(tasks, { prompt = "Gradle task (./gradlew)" }, function(task)
    if task then
      run_in_term(("./gradlew %s"):format(task))
    end
  end)
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm",
    keys = {
      { "<leader>rm", maven_runner, desc = "[R]un [M]aven goal" },
      { "<leader>rg", gradle_runner, desc = "[R]un [G]radle task" },
      { "<C-\\>", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal", mode = { "n", "t" } },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
    },
  },
}
