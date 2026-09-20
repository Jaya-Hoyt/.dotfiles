# .dotfiles

This repository contains my personal dotfiles and machine configuration, built for macOS.

## One-Line Installation

To set up a fresh macOS machine with all my dotfiles, homebrew packages, and tool configurations, open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jaya-Hoyt/.dotfiles/refs/heads/master/setup_dotfiles)"
```

## What It Sets Up

The [setup_dotfiles](setup_dotfiles) script automates the entire installation and configuration process:

1. **Submodules:** Clones and updates all git submodules.
2. **Local Environment Files:** Creates standard shell and editor local config stubs (`~/.zshrc_local`, `~/.bashrc_local`, etc.) so they are ready for machine-specific values.
3. **Homebrew:** Installs Homebrew if missing, and installs all GUI apps (Rectangle, Kitty, Keyboard Maestro, Karabiner Elements), Nerd Fonts, and command-line tools via the [Brewfile](Brewfile).
4. **Mise:** Installs `mise` if missing, and installs all CLI runtime tools (Neovim, Jujutsu, Fish shell, Node, Deno, Rust, etc.) declared in [mise/config.toml](mise/config.toml) non-interactively.
5. **Dotbot:** Symlinks configurations from this directory into their standard system locations (e.g. `~/.config/jj`, `~/.config/fish`, `~/.config/nvim`).
6. **Tmux Plugin Manager (TPM):** Installs and initializes TPM and its plugins.
7. **Keyboard Maestro:** Restores my personal macro configurations (`KeyboardMaestroMacros.kmsync`) directly to the application support directory.
8. **Karabiner Elements:** Registers keyboard mapping configuration.

## SSH Configuration

**This repository is public, so no hostname or internal address belongs in a
tracked file.** SSH config is therefore split in three:

| File | Tracked? | Contents |
| --- | --- | --- |
| [ssh_config.template](ssh_config.template) | yes | Cloudtop host blocks, with the hostname as a `{{SCLOUD_HOST}}` placeholder |
| `~/.ssh/scloud_config` | no (generated) | The above, with the placeholder substituted |
| `~/.ssh/config` | no | `Include ~/.ssh/scloud_config`, plus machine-specific hosts |

`setup_dotfiles` renders the template into `~/.ssh/scloud_config` and prepends
the `Include` line to `~/.ssh/config` if it is missing. It never overwrites
`~/.ssh/config`, so hosts you keep there survive re-running setup.

Set the hostname once, and it is remembered as a fish universal variable:

```bash
./setup_dotfiles --scloud-host your-host.example.com
# or, to be prompted:
./setup_dotfiles --set-scloud-host
```

Without it, setup falls back to a placeholder and leaves any existing
`~/.ssh/scloud_config` untouched, so the script stays non-interactive.

### Keep port forwards in the template, not in `~/.ssh/config`

Every host that talks to the Cloudtop belongs in the template. Two host blocks
declaring the same forward is a genuinely nasty failure: only one connection
can bind the port, and the loser prints a warning that is easy to miss while
the tunnel silently never works. `setup_dotfiles` warns if `~/.ssh/config`
redeclares a port the generated file already owns.

Because forwards belong to the SSH *master* connection, a master whose TCP
connection has died keeps its control socket for a while, and reconnecting your
terminal just reattaches to the same broken master. [cdp-repair](local/bin/cdp-repair)
rebinds the Chrome DevTools forward on the live master without dropping your
shpool/tmux session:

```bash
cdp-repair           # check, and repair only if actually broken
cdp-repair --check   # report health, change nothing
cdp-repair --force   # kill the master (last resort)
```

## Tests

Fish scripts are tested with [fishtape](https://github.com/jorgebucaran/fishtape):

```bash
fishtape local/bin/cdp-repair_test.fish
fishtape local/bin/jj_watch_test.fish
```
