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
4. **Mise:** Installs `mise` if missing, and installs all CLI runtime tools (Neovim, Fish shell, Node, Deno, Rust, etc.) declared in [mise/config.toml](mise/config.toml) non-interactively.
5. **Dotbot:** Symlinks configurations from this directory into their standard system locations (e.g. `~/.config/fish`, `~/.config/nvim`).
6. **Tmux Plugin Manager (TPM):** Installs and initializes TPM and its plugins.
7. **Keyboard Maestro:** Restores my personal macro configurations (`KeyboardMaestroMacros.kmsync`) directly to the application support directory.
8. **Karabiner Elements:** Registers keyboard mapping configuration.
