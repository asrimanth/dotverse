#!/bin/sh

check_tmux_status() {
    if command_exists tmux; then
        echo "${CHECK_MARK} Tmux (Terminal Multiplexer)"
    else
        echo "Tmux (Terminal Multiplexer)"
    fi
}

setup_tmux_catppuccin_theme() {
    log "INFO" "Setting up Catppuccin theme for tmux..."

    local tmux_catppuccin_dir="$HOME/.config/tmux/plugins/catppuccin/tmux"

    mkdir -p "$HOME/.config/tmux/plugins/catppuccin"
    if [ -d "$tmux_catppuccin_dir" ]; then
        log "WARNING" "Catppuccin theme directory already exists. Overwriting..."
        rm -rf "$tmux_catppuccin_dir"
    fi

    git clone -b v2.1.2 https://github.com/catppuccin/tmux.git "$tmux_catppuccin_dir" || \
        error_exit "Failed to clone Catppuccin tmux theme"

    # Add the run line to tmux.conf if not already present
    if ! grep -q "run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux" "$HOME/.tmux.conf" 2>/dev/null; then
        echo "run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux" >> "$HOME/.tmux.conf"
        log "SUCCESS" "Added Catppuccin theme run line to tmux.conf"
    else
        log "INFO" "Catppuccin theme run line already in tmux.conf"
    fi

    log "SUCCESS" "Catppuccin theme for tmux setup successfully. Reload tmux with 'tmux source ~/.tmux.conf'."
}

setup_tmux() {
    local force_reinstall="${1:-false}"
    
    log "INFO" "Setting up tmux..."
    
    install_package "tmux" "$force_reinstall"

    if [ "$force_reinstall" = true ]; then
        setup_tmux_catppuccin_theme
    else
        if [ -f "$HOME/.tmux.conf" ]; then
            backup_file "$HOME/.tmux.conf"
            if [ -f ".tmux.conf" ]; then
                cp ".tmux.conf" "$HOME/.tmux.conf"
                log "SUCCESS" "tmux configuration updated"
            else
                log "WARNING" "No .tmux.conf found in current directory"
            fi
        else
            if [ -f ".tmux.conf" ]; then
                cp ".tmux.conf" "$HOME/.tmux.conf"
                log "SUCCESS" "tmux configuration copied"
            else
                log "WARNING" "No .tmux.conf found in current directory"
            fi
        fi
        setup_tmux_catppuccin_theme
    fi
}
