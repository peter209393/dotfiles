# AGENTS.md - Neovim Configuration

This repository contains a Neovim configuration managed by lazy.nvim. This document helps agents understand the codebase structure, patterns, and conventions.

## Project Overview

- **Type**: Neovim configuration (dotfiles/nvim)
- **Plugin Manager**: lazy.nvim
- **Entry Point**: `init.lua` (requires `lua/config/lazy.lua`)
- **Lock File**: `lazy-lock.json` (commits plugin versions)

## Directory Structure

```
.
├── init.lua              # Main entry point (requires config.lazy)
├── lazy-lock.json        # Plugin version lockfile
├── readme.md             # Keymap documentation
└── lua/
    ├── config/           # Core configuration
    │   ├── lazy.lua      # Plugin manager setup and loading
    │   ├── options.lua   # Neovim options and settings
    │   └── keymaps.lua   # Global keybindings
    └── plugins/          # Plugin-specific configurations (15 files)
```

## Essential Commands

### Plugin Management (lazy.nvim)

- `:Lazy` - Open plugin manager UI (install, update, sync, clean)
- `:Lazy sync` - Sync plugins (install missing, update, clean unused)
- `:Lazy update` - Update all plugins
- `:Lazy clean` - Clean unused plugins

### LSP & Formatting

- `:Mason` - Open Mason UI to manage LSP servers, formatters, and tools
- `:TSUpdate` - Update Tree-sitter parsers (used by tree-sitter plugin)
- `:ConformInfo` - View formatting status for current buffer

### Formatting

Lua files are automatically formatted with `stylua` on save (via conform.nvim).

## Code Organization & Patterns

### Plugin Configuration Structure

All plugin files in `lua/plugins/` follow the lazy.nvim spec format:

```lua
return {
  "author/repo-name",
  dependencies = { ... },  -- Optional plugin dependencies
  opts = { ... },         -- Plugin options (passed directly to setup())
  config = function()      -- Custom setup function
    require("plugin-name").setup({ ... })
  end,
  keys = { ... },          -- Keybindings defined in plugin spec (see fff.lua)
  build = ":Command",      -- Build commands (see tree-sitter.lua)
  lazy = false,           -- Load immediately if needed (see tree-sitter.lua)
}
```

**Pattern**: Use `opts = {}` for simple configurations, `config = function()` for complex setups.

### Global Settings

- **Leader key**: Space (`<leader>`)
- **Localleader**: Backslash (`<localleader>`)
- Defined in `lua/config/lazy.lua` before loading plugins

### Keybinding Patterns

Keybindings are defined in two ways:

1. **Global keybindings** (`lua/config/keymaps.lua`):
   ```lua
   vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
   vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>")
   ```

2. **Plugin-specific keybindings** (using `keys` field):
   ```lua
   keys = {
     { "<leader>ff", function() require("fff").find_files() end, desc = "..." },
   }
   ```

### LSP Configuration

Located in `lua/plugins/lsp.lua`:

- LSP servers are managed by mason.nvim
- Servers listed in the `servers` table: `zls`, `bashls`, `marksman`, `phpactor`, `clangd`, `gopls`, `rust_analyzer`, `ts_ls`, `lua_ls`
- Custom mappings defined in `LspAttach` autocmd (use built-in `vim.lsp.buf` navigation, not a picker plugin)
- Additional tools installed via mason-tool-installer: `stylua`

### Completion

- **Engine**: blink.cmp (not nvim-cmp)
- **Sources**: lsp, path, snippets, buffer, emoji, sql
- **Keymap preset**: "super-tab" (tab to accept)
- Emoji completion enabled for: `gitcommit`, `markdown`
- SQL completion enabled for: `sql` files

### Fuzzy Finding

- **Plugin**: dmtrKovalenko/fff (Rust-based fuzzy finder, NOT fzf-lua or Telescope)
- The binary is downloaded/built automatically via the plugin's `build` hook
- Common bindings:
  - `<leader>ff` - Find files
  - `<leader>fg` - Live grep
  - `<leader>fw` - Grep word/selection under cursor
  - `<leader>fc` - Find in config directory
  - `<leader><leader>` - Find buffers (simple `vim.ui.select` picker, fff has no buffer picker)

## Code Style & Conventions

### Indentation

From `lua/config/options.lua`:
- `expandtab = true` - Convert tabs to spaces
- `shiftwidth = 4` - Indent with 4 spaces
- `tabstop = 4`
- `softtabstop = 4`

### File Formatting

- Lua: `stylua` (auto-format on save)
- Python: `isort`, `black`
- Rust: `rustfmt`
- JavaScript/TypeScript: `prettierd`, `prettier` (fallback)

Note: The config files mix tabs and spaces. Follow the existing pattern in each file rather than enforcing consistency across files.

### Lua Patterns

- Use `return { ... }` for plugin specs
- Use `require()` to load modules
- Define helper functions inside config functions for local scope
- Use `vim.keymap.set()` for keybindings
- Use `vim.api.nvim_create_autocmd()` for event-driven behavior

## Important Gotchas

### LSP Navigation Uses Built-in vim.lsp.buf

This config does NOT use Telescope or a picker plugin for LSP navigation. LSP navigation commands use Neovim built-ins (`gd`, `gr`, `gI`, `<leader>D`, `<leader>ds`, `<leader>ws`):
- `vim.lsp.buf.definition` - jumps directly, `<C-t>` to jump back
- `vim.lsp.buf.references` - results in the quickfix list
- `vim.lsp.buf.implementation`
- `vim.lsp.buf.type_definition`
- `vim.lsp.buf.document_symbol` - `vim.ui.select` based
- `vim.lsp.buf.workspace_symbol` - prompts for query, results in quickfix

### Tree-sitter Manual Installation

The tree-sitter plugin (`lua/plugins/tree-sitter.lua`) has `auto_install = false`. Language parsers are manually installed via:
```lua
require("nvim-treesitter").install(ensure_installed)
```
And started via FileType autocmd.

### Completion Engine is blink.cmp

This config uses `blink.cmp`, NOT `nvim-cmp`. Do not add nvim-cmp configurations.
- For nvim-cmp compatibility: use `blink.compat`
- Configuration goes in `lua/plugins/blink-cmp.lua`

### Plugin Loading Order

The `lazy.lua` file loads config in this order:
1. Sets leader keys
2. Loads `lua/config/options.lua`
3. Sets up lazy.nvim with plugins
4. Loads `lua/config/keymaps.lua`

When adding plugins, ensure `mapleader` is set before lazy loads the plugin specs.

### Colorscheme Priority

Catppuccin plugin has `priority = 1000` to ensure it loads before other plugins. The theme is "mocha" flavor.

## Configuration Details

### Installed Languages (Tree-sitter)

c3, zig, php, rust, vimdoc, javascript, typescript, c, go, lua, jsdoc, bash, css, kotlin

### LSP Servers

zls, bashls, marksman, phpactor, clangd, gopls, rust_analyzer, ts_ls, lua_ls

### GitHub PR Review (octo.nvim)

The configuration includes **octo.nvim** for GitHub PR/Issue review workflows:

**Key commands:**
- `<leader>pr` - List PRs
- `<leader>po` - List and checkout PR
- `<leader>pi` - List Issues
- `<leader>pa` - Approve PR
- `<leader>pf` - List PR files
- `<leader>pc` - List PR commits
- `<leader>ca` - Add comment
- `<leader>sa` - Add suggestion

**Dependencies:**
- `gh` CLI tool must be installed and authenticated
- Repository must be cloned locally

**Workflow:**
1. Use `<leader>po` to select and checkout a PR branch
2. Review changes with `<leader>pf` (files) and `<leader>pd` (diff)
3. Add comments with `<leader>ca` or suggestions with `<leader>sa`
4. Approve or request changes with `<leader>pa` / `<leader>pr`

### Key File Navigation

- `-` - Open Oil file browser (float)
- `\` - Vertical split
- `<leader>bd` - Close buffer
- `<C-h/j/k/l>` - Navigate windows

## Adding New Plugins

1. Create a new file in `lua/plugins/` or edit an existing one
2. Use the lazy.nvim spec format:
   ```lua
   return {
     "author/repo",
     opts = { ... },  -- or config = function() ... end
   }
   ```
3. Run `:Lazy sync` to install
4. Lock version by running `:Lazy update` (updates lazy-lock.json)
5. Commit `lazy-lock.json` along with your changes

## Adding LSP Servers

Add the server name to the `servers` table in `lua/plugins/lsp.lua`:
```lua
local servers = {
  zls = {},
  bashls = {},
  -- Add your server here
  new_server = {},
}
```

The server will be automatically installed by mason-tool-installer.

## Testing Changes

1. Edit configuration files
2. Run `:Lazy` and check for errors
3. Restart Neovim or reload config (`:source %`)
4. Test specific functionality (LSP, completion, keybindings)

## Notes

- The user prefers Neovide for UI (see readme.md:18)
- Window navigation uses standard Vim splits with keybindings for easier movement
- This is a personal dotfiles repository, not a public template
