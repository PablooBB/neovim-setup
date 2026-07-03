# neovim-setup

A [lazy.nvim](https://github.com/folke/lazy.nvim)-based Neovim configuration built as a
full IDE replacement for Java development: LSP, refactoring, debugging, test running,
build-tool integration, and JVM profiling — the things IDEs like IntelliJ/Eclipse give
you out of the box.

## Requirements

- [Homebrew](https://docs.brew.sh/Homebrew-on-Linux) (used to install Neovim itself and
  a few CLI tools without touching system packages)
- `curl`, a C compiler (`cc`/`gcc`), `make` — used to build native plugin bits and
  Treesitter parsers
- A JDK on `PATH` for your projects (SDKMAN, installed by `install.sh`, manages this)

## Install

```sh
git clone https://github.com/PablooBB/neovim-setup.git ~/.config/nvim
~/.config/nvim/install.sh
```

`install.sh` is idempotent (safe to re-run) and bootstraps everything from zero:

- Neovim, `fd`, `tree-sitter-cli`, and a clipboard tool (`xclip`/`wl-clipboard`
  depending on your session type) via Homebrew
- [async-profiler](https://github.com/async-profiler/async-profiler) under
  `~/.local/share/async-profiler`, symlinked to `~/.local/bin/asprof`
- [SDKMAN](https://sdkman.io/) for managing multiple JDKs per project
- The JUnit Platform Console Standalone jar `neotest-java` needs to run tests
- A headless `Lazy! sync` to install all plugins
- Mason installs of `jdtls`, `java-debug-adapter`, `java-test`, `lua_ls`, `jsonls`,
  `yamlls`, `marksman`
- Compiles all configured Treesitter parsers

After it finishes, open a new shell (or `source ~/.sdkman/bin/sdkman-init.sh`) and run
`nvim` — `:checkhealth` should come back clean.

## Structure

```
init.lua                    bootstraps config.options/keymaps/autocmds/lazy/profile
lua/config/
  options.lua                vim.opt, leader key, have_nerd_font flag
  keymaps.lua                editor-wide keymaps not tied to a plugin
  autocmds.lua                yank highlight, cursor restore, trim trailing whitespace
  lazy.lua                    lazy.nvim bootstrap + plugin spec loader
  profile.lua                 :JavaProfile / :JavaProfileAlloc / :JavaThreadDump
lua/plugins/
  ui.lua                      colorscheme, lualine, bufferline, neo-tree, which-key, trouble, indent guides
  editor.lua                  telescope, treesitter, gitsigns, comment, autopairs, flash
  completion.lua              blink.cmp, friendly-snippets
  lsp.lua                     mason, mason-lspconfig, generic LSP servers (not Java)
  java.lua                    nvim-jdtls plugin spec + mason ensure_installed for jdtls/java-debug-adapter/java-test
  dap.lua                     nvim-dap, nvim-dap-ui, nvim-dap-virtual-text, mason-nvim-dap
  testing.lua                 neotest + neotest-java
  terminal.lua                toggleterm.nvim + Maven/Gradle task runner
lua/jdtls_setup.lua          the actual jdtls config: root detection, DAP bundles,
                             multi-JDK runtime discovery, on_attach keymaps
ftplugin/java.lua            calls jdtls_setup on every `java` buffer
install.sh                  bootstraps the whole toolchain from zero
```

Java gets special treatment: it's excluded from the generic `mason-lspconfig` /
`vim.lsp.enable()` path in `lsp.lua` because jdtls needs project-aware setup
(per-project workspace dirs, debug/test bundle wiring, multi-JDK runtimes) that plain
LSP config can't give it. `ftplugin/java.lua` is Neovim's own auto-sourced hook for the
`java` filetype, so no manual autocmd wiring is needed.

## Java-specific features

- **LSP**: `nvim-jdtls`, auto-detecting the project root (`.git`/`pom.xml`/
  `build.gradle*`/`mvnw`/`gradlew`), with organize-imports-on-save, parameter-name
  inlay hints, and code-lens-driven refactors.
- **Multi-JDK support**: `jdtls_setup.lua` scans `~/.sdkman/candidates/java/*` and
  `/usr/lib/jvm/*`, and feeds every JDK it finds into jdtls's
  `configuration.runtimes` — install a JDK with `sdk install java <version>` and it's
  picked up automatically next time you open Neovim, no config edits needed.
- **Debugging**: `nvim-dap` + `nvim-dap-ui`, with the `java` adapter auto-registered by
  jdtls itself (via the `java-debug-adapter` Mason bundle) — no manual adapter config.
- **Testing**: `neotest` + `neotest-java`, giving a tree-style test explorer (pass/fail
  icons, inline output, jump-to-failure) with JUnit 5/Jupiter, Maven & Gradle, and
  multi-module project support, plus "debug this test" via nvim-dap.
- **Build tool runner**: `toggleterm.nvim`-backed pickers for Maven/Gradle goals, which
  prefer `./mvnw`/`./gradlew` wrappers over global installs when present.
- **Profiling**: `:JavaProfile [seconds]` drives `async-profiler` against a running JVM
  (auto-detected via `jps`, or a picker if more than one is running) and opens the
  resulting flamegraph in your browser. `cpu` automatically falls back to `wall`
  (signal-based, no special kernel permissions) if `perf_events` access is restricted.
  `:JavaProfileAlloc` profiles allocations; `:JavaThreadDump` dumps a `jstack` snapshot
  into a scratch buffer.

## Keymaps

Leader is `<Space>`.

| Prefix / key | Area |
|---|---|
| `<leader>f` | Telescope: find files/grep/buffers/help/recent/symbols/diagnostics |
| `<leader>d` | DAP: breakpoints, continue, step in/over/out, REPL, UI, hover eval |
| `<leader>t` | Neotest: run/debug nearest, run file/suite, stop, output, summary |
| `<leader>j` | jdtls refactors: organize imports, extract var/const/method, test class/method |
| `<leader>r` | Run: `<leader>rm` Maven goal picker, `<leader>rg` Gradle task picker |
| `<leader>p` | Profile: `<leader>pc` CPU, `<leader>pa` alloc, `<leader>pt` thread dump |
| `<leader>e` | Neo-tree: toggle / reveal current file |
| `<leader>x` | Trouble: diagnostics / quickfix / loclist |
| `gd`/`gD`/`gr`/`gI`/`K` | LSP: definition, declaration, references, implementation, hover |
| `<leader>rn` / `<leader>ca` | LSP: rename / code action |
| `s` / `S` | Flash jump / Flash treesitter |

Run `<leader>` and wait — which-key.nvim shows the full menu for any prefix.

## Verifying a fresh setup

1. `nvim --headless "+Lazy! sync" +qa` — plugins install cleanly.
2. `:checkhealth` inside Neovim — no missing runtime deps.
3. Open a `.java` file in a Maven/Gradle project: `:LspInfo` should show `jdtls`
   attached with no startup diagnostics.
4. Set a breakpoint (`<leader>db`), `<leader>dc` to launch the main class — should stop
   at the breakpoint with `nvim-dap-ui` open.
5. `<leader>tr` on a JUnit test file — neotest should discover and run it.
6. `<leader>rm` → `compile` — should run in a floating terminal and finish with
   `BUILD SUCCESS`.
