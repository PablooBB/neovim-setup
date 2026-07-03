-- Practical JVM profiling workflow driven from Neovim.
-- Neovim can't embed a GUI profiler (VisualVM/JProfiler), but it can drive
-- async-profiler against a running JVM and pop open the resulting flamegraph,
-- and pull quick thread dumps -- covering the everyday profiling loop.

local M = {}

local function running_java_pids()
  local ok, out = pcall(vim.fn.system, "jps -l")
  if not ok or vim.v.shell_error ~= 0 then
    return {}
  end
  local pids = {}
  for line in out:gmatch("[^\r\n]+") do
    local pid, name = line:match("^(%d+)%s+(.*)$")
    if pid and not name:match("sun%.tools%.jps") then
      table.insert(pids, { pid = pid, name = name })
    end
  end
  return pids
end

local function pick_pid(callback)
  local pids = running_java_pids()
  if #pids == 0 then
    vim.notify("No running JVMs found (jps found nothing)", vim.log.levels.WARN)
    return
  end
  if #pids == 1 then
    callback(pids[1].pid)
    return
  end
  local items = {}
  for _, p in ipairs(pids) do
    table.insert(items, ("%s  %s"):format(p.pid, p.name))
  end
  vim.ui.select(items, { prompt = "Select JVM process" }, function(choice, idx)
    if choice then
      callback(pids[idx].pid)
    end
  end)
end

local function asprof(pid, event, seconds, outfile, on_done)
  local cmd = { "asprof", "-d", tostring(seconds), "-e", event, "-f", outfile, pid }
  vim.notify(("Profiling PID %s for %ds (%s)..."):format(pid, seconds, event), vim.log.levels.INFO)
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function() on_done(res) end)
  end)
end

local function run_profile(event, seconds)
  seconds = seconds or 10
  pick_pid(function(pid)
    local outfile = ("/tmp/nvim-java-profile-%s-%s.html"):format(pid, os.time())
    asprof(pid, event, seconds, outfile, function(res)
      -- `cpu` needs perf_events access (kernel.perf_event_paranoid <= 1,
      -- typically root-only). Fall back to `wall`, a signal-based sampler
      -- that needs no special privileges, rather than failing outright.
      if res.code ~= 0 and event == "cpu" and (res.stderr or ""):match("perf") then
        vim.notify("cpu event needs perf_events access, falling back to wall-clock sampling", vim.log.levels.WARN)
        asprof(pid, "wall", seconds, outfile, function(res2)
          if res2.code ~= 0 then
            vim.notify("asprof failed: " .. (res2.stderr or ""), vim.log.levels.ERROR)
            return
          end
          vim.notify("Flamegraph written to " .. outfile, vim.log.levels.INFO)
          vim.system({ "xdg-open", outfile })
        end)
        return
      end
      if res.code ~= 0 then
        vim.notify("asprof failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
        return
      end
      vim.notify("Flamegraph written to " .. outfile, vim.log.levels.INFO)
      vim.system({ "xdg-open", outfile })
    end)
  end)
end

function M.cpu_profile(seconds)
  run_profile("cpu", seconds)
end

function M.alloc_profile(seconds)
  run_profile("alloc", seconds)
end

function M.thread_dump()
  pick_pid(function(pid)
    vim.system({ "jstack", pid }, { text = true }, function(res)
      vim.schedule(function()
        local lines = vim.split(res.stdout ~= "" and res.stdout or res.stderr, "\n")
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].filetype = "log"
        vim.cmd.split()
        vim.api.nvim_win_set_buf(0, buf)
      end)
    end)
  end)
end

vim.api.nvim_create_user_command("JavaProfile", function(opts)
  M.cpu_profile(tonumber(opts.args) or 10)
end, { nargs = "?", desc = "CPU-profile a running JVM with async-profiler" })

vim.api.nvim_create_user_command("JavaProfileAlloc", function(opts)
  M.alloc_profile(tonumber(opts.args) or 10)
end, { nargs = "?", desc = "Allocation-profile a running JVM with async-profiler" })

vim.api.nvim_create_user_command("JavaThreadDump", function()
  M.thread_dump()
end, { desc = "Thread dump a running JVM via jstack" })

local map = vim.keymap.set
map("n", "<leader>pc", "<cmd>JavaProfile<CR>", { desc = "[P]rofile: [C]PU (10s)" })
map("n", "<leader>pa", "<cmd>JavaProfileAlloc<CR>", { desc = "[P]rofile: [A]lloc (10s)" })
map("n", "<leader>pt", "<cmd>JavaThreadDump<CR>", { desc = "[P]rofile: [T]hread dump" })

return M
