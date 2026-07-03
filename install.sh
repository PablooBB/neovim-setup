#!/usr/bin/env bash
# Bootstraps this Neovim config from zero on a fresh machine.
#
# Usage:
#   git clone <this-repo> ~/.config/nvim
#   ~/.config/nvim/install.sh
#
# Safe to re-run: every step checks whether it already did its job.
set -euo pipefail

ASYNC_PROFILER_VERSION="3.0"
JUNIT_CONSOLE_VERSION="6.0.3"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

log "Checking prerequisites"
if ! have brew; then
  echo "Homebrew (linuxbrew) is required and wasn't found on PATH." >&2
  echo "Install it first: https://brew.sh  (Linux install docs: https://docs.brew.sh/Homebrew-on-Linux)" >&2
  exit 1
fi
if ! have curl; then
  echo "curl is required." >&2
  exit 1
fi

log "Installing Neovim + CLI tools via Homebrew"
brew install neovim fd tree-sitter-cli
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
  brew install wl-clipboard
else
  brew install xclip
fi

log "Installing async-profiler ${ASYNC_PROFILER_VERSION} (JVM CPU/alloc profiler used by :JavaProfile)"
mkdir -p "$HOME/.local/share/async-profiler" "$HOME/.local/bin"
if [ ! -x "$HOME/.local/share/async-profiler/bin/asprof" ]; then
  curl -fsSL -o /tmp/async-profiler.tar.gz \
    "https://github.com/async-profiler/async-profiler/releases/download/v${ASYNC_PROFILER_VERSION}/async-profiler-${ASYNC_PROFILER_VERSION}-linux-x64.tar.gz"
  tar -xzf /tmp/async-profiler.tar.gz -C "$HOME/.local/share/async-profiler" --strip-components=1
  rm -f /tmp/async-profiler.tar.gz
fi
ln -sf "$HOME/.local/share/async-profiler/bin/asprof" "$HOME/.local/bin/asprof"

log "Installing SDKMAN (manages multiple JDKs alongside your system JDK)"
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
else
  echo "Already installed, skipping."
fi

log "Downloading JUnit Platform Console Standalone (needed by neotest-java)"
mkdir -p "$HOME/.local/share/nvim/neotest-java"
JUNIT_JAR="$HOME/.local/share/nvim/neotest-java/junit-platform-console-standalone-${JUNIT_CONSOLE_VERSION}.jar"
if [ ! -f "$JUNIT_JAR" ]; then
  curl -fsSL -o "$JUNIT_JAR" \
    "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/${JUNIT_CONSOLE_VERSION}/junit-platform-console-standalone-${JUNIT_CONSOLE_VERSION}.jar"
fi

NVIM_BIN="$(brew --prefix)/bin/nvim"

log "Syncing plugins (lazy.nvim)"
"$NVIM_BIN" --headless "+Lazy! sync" +qa

log "Installing LSP/DAP/test tools via Mason (jdtls, java-debug-adapter, java-test, lua_ls, jsonls, yamlls, marksman)"
cat >/tmp/nvim-bootstrap-mason.lua <<'EOF'
local pkgs = { "jdtls", "java-debug-adapter", "java-test", "lua-language-server", "json-lsp", "yaml-language-server", "marksman" }
local registry = require("mason-registry")
registry.refresh(function()
  local remaining = {}
  for _, name in ipairs(pkgs) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() then
      table.insert(remaining, pkg)
    end
  end
  if #remaining == 0 then
    vim.g.mason_install_done = true
    return
  end
  local left = #remaining
  for _, pkg in ipairs(remaining) do
    pkg:install():once("closed", function()
      left = left - 1
      if left == 0 then
        vim.g.mason_install_done = true
      end
    end)
  end
end)
vim.wait(600000, function() return vim.g.mason_install_done end, 500)
EOF
"$NVIM_BIN" --headless -c "lua require('lazy').load({plugins={'mason.nvim'}})" -c "luafile /tmp/nvim-bootstrap-mason.lua" -c "qa"
rm -f /tmp/nvim-bootstrap-mason.lua

log "Compiling Treesitter parsers"
cat >/tmp/nvim-bootstrap-ts.lua <<'EOF'
require("nvim-treesitter").install({
  "java", "json", "yaml", "xml", "groovy",
  "lua", "vim", "vimdoc", "markdown", "markdown_inline",
  "gitcommit", "bash",
}):wait(300000)
EOF
"$NVIM_BIN" --headless -c "lua require('lazy').load({plugins={'nvim-treesitter'}})" -c "luafile /tmp/nvim-bootstrap-ts.lua" -c "qa"
rm -f /tmp/nvim-bootstrap-ts.lua

log "Done"
cat <<'EOF'

Next steps:
  - Open a new shell (or `source ~/.sdkman/bin/sdkman-init.sh`) to pick up SDKMAN.
  - Install any extra JDKs you need per project: `sdk install java <version>`
    (jdtls auto-detects everything under ~/.sdkman/candidates/java).
  - Run `nvim` and `:checkhealth` to confirm everything is green.
  - Open a .java file in a Maven/Gradle project to verify jdtls, debugging
    (<leader>dc), testing (<leader>tr) and the Maven/Gradle runner (<leader>rm/rg).
EOF
