# Fish Shell Configuration Repository

This is a personal Fish shell configuration directory. It contains shell functions, completions, environment variables, and key bindings.

## Project Structure

```
/home/peter/dotfiles/fish/
├── config.fish                 # Main configuration file
├── fish_variables              # Universal variables (colors, paths, etc.)
├── completions/                # Shell completions
│   ├── bun.fish
│   ├── fisher.fish
│   └── ...
├── functions/                  # Custom fish functions
│   ├── fish_prompt.fish        # Left prompt
│   ├── fish_right_prompt.fish  # Right prompt (with git status)
│   ├── bass.fish               # Bash compatibility
│   ├── fisher.fish             # Plugin manager
│   └── ...
└── conf.d/                     # Modular configuration files (auto-sourced)
    ├── asdf.fish               # ASDF version manager
    ├── fzf.fish                # fzf key bindings
    ├── keybinds.fish           # Vim-style key bindings
    └── ...
```

## Working with this Configuration

### Reloading Configuration

After making changes to fish configuration files:

```bash
# Reload config.fish
source ~/.config/fish/config.fish

# Or simply start a new fish shell
fish
```

### Plugin Management (Fisher)

This configuration uses **Fisher** as the plugin manager.

```bash
# List installed plugins
fisher list

# Install a new plugin
fisher install jorgebucaran/fisher

# Remove a plugin
fisher remove patrickf1/fzf.fish

# Update all plugins
fisher update

# Update specific plugins
fisher update patrickf1/fzf.fish
```

The currently installed plugins are tracked in `fish_variables` (universal variable `_fisher_plugins`).

### Adding New Functions

Custom functions should be placed in `functions/` directory:

1. Create a new file `functions/your_function.fish`
2. Define the function using fish syntax:
   ```fish
   function your_function --description "Function description"
       # your code here
   end
   ```
3. The function will be automatically available in new fish shells

### Adding Configuration Snippets

Place modular configuration in `conf.d/` directory:

1. Create a new file `conf.d/your_config.fish`
2. Add configuration code
3. All `.fish` files in `conf.d/` are automatically sourced at startup

### Adding Completions

Shell completions go in `completions/` directory:

1. Create a file matching the command name: `completions/yourcommand.fish`
2. Use the `complete` command to define completions:
   ```fish
   complete --command yourcommand --short-option o --long-option option --description "Option description"
   ```

## Code Conventions

### Function Definitions

- Use `function name` syntax (not `function name; ...; end` on one line)
- Add `--description` for documentation:
  ```fish
  function my_function --description "Does something useful"
      # code
  end
  ```
- Private/internal functions start with double underscore (`__`)
- Event handlers use `--on-event`:
  ```fish
  function __my_handler --on-event my_event
      # code
  end
  ```

### Variables

- Local variables: `set -l var value`
- Exported (environment) variables: `set -x var value`
- Global exported: `set -gx var value`
- Universal (persistent across shells): `set -U var value`

**Preferred pattern for PATH manipulation:**

```fish
# Using fish_add_path (Fish 3.2+)
fish_add_path -a "$HOME/.local/bin"

# Or manual prepend (for compatibility)
set -gx --prepend PATH "$HOME/.local/bin"
```

### Conditionals

```fish
if condition
    # code
else if other_condition
    # code
else
    # code
end

# Command existence check
if command -q some_command
    # command exists
end

# Silent version (no output)
if command -sq some_command
    # command exists
end
```

### Strings

Use the `string` command for string manipulation:

```fish
# Match regex
string match -qr 'pattern' $var

# Split
string split -- / $path

# Replace
string replace -- 'old' 'new' $var

# Substring
string sub -l 10 $var  # first 10 characters
```

### Colors

```fish
# Set color
set_color red

# Output with color
echo (set_color green)"Success!"(set_color normal)

# Reset to normal
set_color normal
```

Available colors: black, red, green, yellow, blue, magenta, cyan, white
Modifiers: br (bright), -o (bold), -u (underline), -d (dim)

## Key Bindings

This configuration uses **Vim-style key bindings** (defined in `conf.d/keybinds.fish`):

- `Ctrl+F`/`Ctrl+B`: Forward/backward character
- `Alt+F`/`Alt+B`: Forward/backward word
- `Ctrl+A`/`Ctrl+E`: Beginning/end of line
- `Ctrl+P`/`Ctrl+N`: Previous/next command in history
- `Ctrl+R`: Search history (fzf)
- `Alt+D`: Delete word after cursor
- `Ctrl+W`: Delete word before cursor
- `Ctrl+K`/`Ctrl+U`: Kill to end/beginning of line

**Important**: `Ctrl+D` is bound to `delete-or-exit-safe`, which deletes a character if the command line is not empty, but does nothing if the line is empty (preventing accidental shell exit).

### FZF Key Bindings

Fuzzy finder bindings are configured in `conf.d/fzf.fish`:

- `Ctrl+R`: Search command history
- `Ctrl+F`: Search directories
- `Alt+C`: Search git status
- `Alt+L`: Search git log
- `Alt+P`: Search processes
- `Alt+V`: Search variables

These can be customized via `fzf_configure_bindings`.

## Important Gotchas

### Login vs Interactive Sessions

The `config.fish` file differentiates between login and interactive sessions:

```fish
if status is-login
    # Only runs on login (first shell)
    set -gx EDITOR nvim
end

if status is-interactive
    # Only runs on interactive shells (has terminal)
    abbr -a g git
end
```

### Lazy Loading

FZF is lazily loaded in `config.fish` to improve shell startup time:

```fish
function __lazy_fzf --on-event fish_prompt
  fzf --fish | source
  functions -e __lazy_fzf  # Remove self after first run
end
```

This pattern is useful for slow-loading tools.

### Universal Variables

The `fish_variables` file contains universal variables that persist across shells. **Do not edit this file directly**. Use fish commands:

```fish
# Set universal variable
set -U my_var value

# Erase universal variable
set -e --universal my_var

# List all universal variables
set -U
```

### Plugin Files in fish_variables

Plugin files are tracked in the universal variable `_fisher_PLUGINNAME_files`. When removing plugins, Fisher automatically cleans these up. Don't manually edit these variables.

### Aliases vs Abbreviations

- **Aliases**: Defined with `alias ll="exa -la"` (always expanded)
- **Abbreviations**: Defined with `abbr -a g git` (expanded only when followed by space or enter)

This configuration prefers abbreviations for common git aliases.

### Event Handlers

Plugins use event handlers for cleanup:

```fish
function _myplugin_uninstall --on-event myplugin_uninstall
    # Cleanup code
end
```

Never manually invoke these functions; they are triggered by Fisher.

## Custom Functions of Note

### `fish_prompt` / `fish_right_prompt`

The prompt is split into two functions:
- `fish_prompt`: Left side (user@host, path, prompt symbol)
- `fish_right_prompt`: Right side (exit status, git branch, git status indicators)

Git status indicators:
- `⬆`/`⬇`: Ahead/behind remote
- `✭`: Stashed changes
- `✚`: Added files
- `✖`: Deleted files
- `✱`: Modified files
- `➜`: Renamed files
- `═`: Unmerged files
- `◼`: Untracked files

### `bass`

Runs Bash commands and exports their environment to Fish:

```fish
bass 'export MY_VAR=value; echo $MY_VAR'
```

### `z`

Directory jumping tool (zoxide/jethrokuan/z). Jump to frequently used directories:

```bash
z ~/projects/myproject
z myproject  # Partial match
```

## Testing Changes

There is no automated test suite. Test manually:

1. Open a new fish shell to load all changes
2. Test specific functions by calling them
3. Check key bindings work as expected
4. Verify plugins are loaded: `fisher list`
5. Test prompt rendering by changing directories and git status

## Configuration Files

### config.fish

Main configuration file. Contains:
- Login session setup (editor, PATH)
- Interactive session setup (abbreviations, aliases, thefuck)
- Lazy loading for fzf
- Environment variables (pnpm, bun)

### conf.d/ Files

Each file is auto-sourced. Key files:
- `asdf.fish`: ASDF version manager initialization
- `fzf.fish`: FZF fuzzy finder configuration
- `keybinds.fish`: Custom key bindings
- `local.fish`: **Contains secrets!** Private keys and secrets (DO NOT commit to public repos)
- `foundry.fish`: Foundry Ethereum tools
- `rustup.fish`: Rust toolchain
- `sway.fish`: Sway window manager
- `z.fish`: z directory jumper

## Security Notes

### conf.d/local.fish

This file contains sensitive information:
- Private keys
- Deployment secrets

**WARNING**: This file should not be committed to version control if this repository is public. Use a `.gitignore` rule or environment-specific configuration.

### Fish Variables

The `fish_variables` file contains:
- All universal variables
- Color scheme preferences
- Plugin file lists
- PATH modifications

This file is safe to share as it contains configuration, not secrets.

## External Dependencies

This configuration relies on several external tools:
- **exa**: Modern replacement for `ls` (aliased as `ls` and `ll`)
- **nvim**: Neovim (set as EDITOR)
- **thefuck**: Command correction tool
- **fzf**: Fuzzy finder (managed by Fisher)
- **asdf**: Version manager
- **pnpm**: Node.js package manager
- **bun**: JavaScript runtime
- **fisher**: Plugin manager (built-in function)
- **z**: Directory jumper (managed by Fisher)

Ensure these tools are installed for full functionality.

## Color Scheme

The color scheme is defined in `fish_variables` (fish_color_*). It uses a dark theme with:
- Purple/violet commands (`c397d8`)
- Yellow comments (`e7c547`)
- Red errors (`d54e53`)
- Cyan escapes (`00a6b2`)
- Green quotes (`b9ca4a`)

To modify colors, use `set -U fish_color_command value` or edit `fish_variables` and restart fish.
