# Dotverse

## Summary of the Repo

Dotverse is a repository designed to set up a development environment for terminal usage across different operating systems, including Mac, Ubuntu, and Fedora. It automates the installation and configuration of essential tools and extensions to enhance your terminal experience.

## Prerequisites

- `brew` package manager for Mac
- `apt` for Ubuntu and `dnf` for Fedora

## Setup

1. **Clone the repo:**
   ```bash
   git clone https://github.com/asrimanth/dotverse.git
   cd dotverse
   ```

2. **Run the setup file:**
   ```bash
   sh setup.sh
   ```

3. **Restart your shell:**
   After running the setup script, restart your terminal or run `source ~/.zshrc` to apply the changes.

## Dependencies

### Mac

- `zsh`
- `starship`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `tmux`
- `yazi`
- `fzf`
- `ffmpeg`
- `p7zip-full`
- `jq`
- `poppler-utils`
- `fd-find`
- `ripgrep`
- `zoxide`
- `imagemagick`

### Linux

- `zsh`
- `starship`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `tmux`
- `yazi`
- `fzf`
- `ffmpeg`
- `p7zip-full`
- `jq`
- `poppler-utils`
- `fd-find`
- `ripgrep`
- `zoxide`
- `imagemagick`
- `apt` or `dnf` (package manager)
