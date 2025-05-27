#!/bin/sh

# Repository URLs
readonly ZSH_AUTOSUGGESTIONS_URL="https://github.com/zsh-users/zsh-autosuggestions"
readonly ZSH_SYNTAX_HIGHLIGHTING_URL="https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Component status checking functions
check_zsh_status() {
    if command_exists zsh; then
        if [ "$SHELL" = "$(command -v zsh)" ]; then
            echo "${CHECK_MARK} ZSH Shell (Installed & Default)"
        else
            echo "${CHECK_MARK} ZSH Shell (Installed but not Default)"
        fi
    else
        echo "ZSH Shell"
    fi
}

check_zsh_extensions_status() {
    local installed=true
    
    if ! directory_exists_and_populated "${ZSH_DIR}/zsh-autosuggestions" || \
       ! directory_exists_and_populated "${ZSH_DIR}/zsh-syntax-highlighting"; then
        installed=false
    fi
    
    if [ "$installed" = true ]; then
        echo "${CHECK_MARK} ZSH Extensions (Autosuggestions & Syntax Highlighting)"
    else
        echo "ZSH Extensions (Autosuggestions & Syntax Highlighting)"
    fi
}

setup_zsh() {
    local force_reinstall="${1:-false}"
    if command_exists zsh && [ "$force_reinstall" = false ]; then
        log "INFO" "ZSH is already installed"
    else
        install_package "zsh" "$force_reinstall"
    fi

    if [ "$SHELL" != "$(command -v zsh)" ]; then
        log "SUCCESS" "Setting ZSH as default shell..."
        chsh -s "$(command -v zsh)" || error_exit "Failed to set ZSH as default shell"
        log "SUCCESS" "ZSH set as default shell"
    else
        log "INFO" "ZSH is already the default shell"
    fi
}

setup_zsh_extensions() {
    local force_reinstall="${1:-false}"
    log "SUCCESS" "Setting up ZSH extensions..."
    
    mkdir -p "$ZSH_DIR"

    # Handle reinstallation by removing existing directories if force_reinstall is true
    if [ "$force_reinstall" = true ]; then
        rm -rf "${ZSH_DIR}/zsh-autosuggestions"
        rm -rf "${ZSH_DIR}/zsh-syntax-highlighting"
    fi

    # Install/update zsh-autosuggestions
    if directory_exists_and_populated "${ZSH_DIR}/zsh-autosuggestions" && [ "$force_reinstall" = false ]; then
        log "INFO" "zsh-autosuggestions is already installed"
    else
        git clone "$ZSH_AUTOSUGGESTIONS_URL" "${ZSH_DIR}/zsh-autosuggestions" || \
            error_exit "Failed to clone zsh-autosuggestions"
        log "SUCCESS" "zsh-autosuggestions installed successfully"
    fi

    # Install/update zsh-syntax-highlighting
    if directory_exists_and_populated "${ZSH_DIR}/zsh-syntax-highlighting" && [ "$force_reinstall" = false ]; then
        log "INFO" "zsh-syntax-highlighting is already installed"
    else
        git clone "$ZSH_SYNTAX_HIGHLIGHTING_URL" "${ZSH_DIR}/zsh-syntax-highlighting" || \
            error_exit "Failed to clone zsh-syntax-highlighting"
        log "SUCCESS" "zsh-syntax-highlighting installed successfully"
    fi
}

setup_zshrc() {
    log "SUCCESS" "Setting up zshrc configuration..."
    
    mkdir -p "${STARSHIP_DIR}"
    if [ -f "gruvbox-custom.toml" ]; then
        cp gruvbox-custom.toml "$STARSHIP_DIR"
    fi

    backup_file "${HOME}/.zshrc"

    cat > "${HOME}/.zshrc" << 'EOL'
# Enable Starship
eval "$(starship init zsh)"

# Starship preset
export STARSHIP_CONFIG=~/.config/starship/gruvbox-custom.toml

# Source ZSH extensions
if [ -f ~/.config/zsh/extensions/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.config/zsh/extensions/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -f ~/.config/zsh/extensions/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.config/zsh/extensions/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Basic ZSH configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Basic aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# tmux configuration
if [ -f ~/.tmux.conf ]; then
    tmux source-file ~/.tmux.conf 2>/dev/null
fi
EOL
    log "SUCCESS" "zshrc configuration created successfully"
}
