# Dotverse

## Summary

Dotverse is a repository that provides a script to set up a powerful and customizable terminal environment. It automates the installation and configuration of essential tools, extensions, and themes to enhance your terminal experience on macOS, Ubuntu, and Fedora. The script uses `fzf` to provide an interactive menu to select which components to install.

## Features

-   **ZSH Shell:** Installs and sets ZSH as the default shell.
-   **Starship Prompt:** Installs and configures Starship, a modern and customizable shell prompt.
-   **ZSH Extensions:** Installs ZSH autosuggestions and syntax highlighting for improved usability.
-   **Tmux:** Installs and configures Tmux, a terminal multiplexer.
-   **Yazi:** Installs and configures Yazi, a modern terminal file manager with a Catppuccin theme.
-   **Interactive Installation:** Uses `fzf` to provide an interactive menu to select which components to install.
-   **Package Manager Detection:** Automatically detects and uses `apt`, `dnf`, or `brew` package managers.
-   **Automatic Updates:** Updates package lists before installing packages.
-   **Backup:** Backs up existing configuration files before making changes.
-   **Starship Presets:** Downloads and configures Starship presets.

## Prerequisites

-   `brew` package manager for macOS
-   `apt` for Ubuntu and `dnf` for Fedora

## Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/asrimanth/dotverse.git
    cd dotverse
    ```

2.  **Run the setup script:**
    ```bash
    sh setup.sh
    ```
    The script will present an interactive menu using `fzf` to select which components to install. Use the spacebar to select/deselect components and press Enter to confirm. Components with a checkmark (✓) will be reinstalled.

3.  **Restart your shell:**
    After running the setup script, restart your terminal or run `source ~/.zshrc` to apply the changes.

## Dependencies

The following tools and packages are installed and configured by the script:

### Core

-   `zsh`: The Z shell.
-   `starship`: A modern and customizable shell prompt.
-   `tmux`: A terminal multiplexer.
-   `fzf`: A command-line fuzzy finder.

### ZSH Extensions

-   `zsh-autosuggestions`: Provides suggestions as you type commands.
-   `zsh-syntax-highlighting`: Highlights commands as you type.

### Yazi File Manager

-   `yazi`: A modern terminal file manager.
-   `ffmpeg`: Used by Yazi for media previews.
-   `p7zip-full`: Used by Yazi for archive handling.
-   `jq`: Used by Yazi for JSON processing.
-   `poppler-utils`: Used by Yazi for PDF previews.
-   `fd-find`: Used by Yazi for file searching.
-   `ripgrep`: Used by Yazi for file searching.
-   `zoxide`: Used by Yazi for directory navigation.
-   `imagemagick`: Used by Yazi for image previews.
-   `font-symbols-only-nerd-font`: Used by Yazi for icons.

### Package Managers

-   `apt` (Ubuntu)
-   `brew` (macOS)

### Starship Presets

The script downloads the following Starship presets:

-   `gruvbox-rainbow.toml`
-   `tokyo-night.toml`
