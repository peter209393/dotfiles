# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for fish, Neovim, Alacritty/Ghostty, i3/Sway/Waybar, tmux, plus
helper scripts. macOS and Linux from one tree. No build, no test suite, no linter:
every change is verified by reloading the tool it configures.

`README.md` (+ `readme.zh-CN.md`) covers install; `FEATURES.md` documents every
config feature-by-feature; `fish/AGENTS.md` and `nvim/AGENTS.md` carry the
conventions, keybindings and gotchas for those two packages — read the relevant
one before editing under `fish/` or `nvim/`.

## Commands

```bash
./install.sh --stow-only   # re-link after adding/removing files (the common one)
./install.sh --all         # full unattended install on a fresh machine
exec fish                  # verify fish changes
nvim --headless "+Lazy! sync" +qa   # verify nvim plugin changes
```

## Stow layout

`install.sh:stow_packages` uses a **per-package target**, not the usual single
`~/.config` target:

```
stow --restow --target=$HOME/.config/<pkg> <pkg>     # fish nvim alacritty ghostty i3 sway waybar
stow --restow --target=$HOME                tmux
```

So `fish/config.fish` becomes `~/.config/fish/config.fish` — the package name is
*not* repeated inside the package directory. A new package needs an entry in both
the `targets` map and the `for pkg in ...` list.

Because targets are symlinks, **editing a tracked file takes effect immediately;
creating or deleting one requires `./install.sh --stow-only`.**

## Conventions

- Comments are written in Chinese throughout (`install.sh`, `config.fish`,
  `conf.d/`, `scripts/`). Match the surrounding file.
- Platform branching lives inline: `test (uname -s) = Darwin` / `= Linux` in fish,
  `$PLATFORM` in `install.sh`. One tree serves both; guard platform-only code
  rather than forking files.
- `fish/conf.d/` is numbered for source order (`00_os_detect` → `12_path_linux` →
  unnumbered tools → `_99_dotfiles_env`). Put a new snippet where its
  dependencies are already loaded.
- Slow tools are lazy-loaded to protect shell startup: `fzf` via a
  `--on-event fish_prompt` handler that erases itself, `thefuck` via the `f`
  function that redefines itself on first call. Reuse that pattern for anything
  that spawns a subprocess at load.
- Commit `nvim/lazy-lock.json` alongside any `nvim/lua/plugins/` change.
- Touching a feature means updating `FEATURES.md`, and `README.md` **and**
  `readme.zh-CN.md` if the install flow changed.

## Gotchas

- **`.claude/worktrees/openpencil-local-integration-15aa0a/` is a full committed
  copy of the repo.** Every grep and glob returns each hit twice. Edit the
  top-level path; the worktree copy is stale (it still has `fish/conf.d/20_sway_linux.fish`
  and `nvim/lua/plugins/fzf.lua`, both gone from the real tree).
- The **tty1 → `exec sway` autostart must stay at the very end of
  `fish/config.fish`.** It used to live in `conf.d/20_sway_linux.fish`, where it
  cut off `conf.d` sourcing midway and left sway's children with a truncated
  environment.
- `install.sh` stows a `tmux` package that does not exist in this tree (it warns
  and skips). `FEATURES.md` still references `tmux/.tmux.conf.local`.
- The Linux extras assume the repo is at `~/dotfiles`, not `~/works/dotfiles`:
  `sway/config:272` hardcodes `/home/peter/dotfiles/scripts/agent-float-toggle.sh`
  and `systemd/user/obsidian-sync.service` uses `%h/dotfiles/scripts/...`.
- `fish/conf.d/local.fish` holds machine-local secrets and is gitignored. Change
  the tracked template `local.fish.example`, never `local.fish`.
- `fish/fish_variables` is fish-managed state (universal variables). Change it
  with `set -U` from a shell rather than by editing the file.
