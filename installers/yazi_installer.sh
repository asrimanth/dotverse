#!/bin/sh

readonly YAZI_RELEASE_URL="https://github.com/sxyazi/yazi/releases/download/v0.4.2/yazi-x86_64-unknown-linux-gnu.zip"

check_yazi_status() {
    if command_exists yazi; then
        echo "${CHECK_MARK} Yazi (Modern File Manager)"
    else
        echo "Yazi (Modern File Manager)"
    fi
}

setup_yazi() {
    local force_reinstall="${1:-false}"
    log "SUCCESS" "Setting up Yazi file manager..."
    
    if command_exists yazi && [ "$force_reinstall" = false ]; then
        log "INFO" "Yazi is already installed"
    else
        if command_exists brew; then
            if [ "$force_reinstall" = true ]; then
                brew reinstall ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide imagemagick font-symbols-only-nerd-font
                install_package "yazi" true
            else
                brew install ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide imagemagick font-symbols-only-nerd-font
                install_package "yazi"
            fi
        else
            install_yazi_dependencies "$force_reinstall"
            install_yazi_binary
        fi
    fi

    setup_yazi_theme
}

install_yazi_dependencies() {
    local force_reinstall="${1:-false}"
    log "INFO" "Installing Yazi dependencies..."
    local dependencies="ffmpeg p7zip-full jq poppler-utils fd-find ripgrep fzf zoxide imagemagick"

    for dep in $dependencies; do
        install_package "$dep" "$force_reinstall"
    done
}

install_yazi_binary() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    log "INFO" "Downloading Yazi..."
    curl -L "$YAZI_RELEASE_URL" -o "$tmp_dir/yazi.zip" || \
        error_exit "Failed to download Yazi"
    
    unzip "$tmp_dir/yazi.zip" -d "$tmp_dir" || \
        error_exit "Failed to extract Yazi"

    if is_root_user; then
        mv "$tmp_dir/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/ || \
            error_exit "Failed to install Yazi binary"
        mv "$tmp_dir/yazi-x86_64-unknown-linux-gnu/ya" /usr/local/bin/ || \
            error_exit "Failed to install Ya binary"
    else
        sudo mv "$tmp_dir/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/ || \
            error_exit "Failed to install Yazi binary"
        sudo mv "$tmp_dir/yazi-x86_64-unknown-linux-gnu/ya" /usr/local/bin/ || \
            error_exit "Failed to install Ya binary"
    fi

    rm -rf "$tmp_dir"
    log "SUCCESS" "Yazi installed successfully"
}

setup_yazi_theme() {
    log "SUCCESS" "Setting up Catppuccin theme for Yazi..."
    
    mkdir -p "$YAZI_CONFIG_DIR"
    
    if [ -f "${YAZI_CONFIG_DIR}/theme.toml" ]; then
        log "INFO" "Yazi theme configuration already exists"
        return 0
    fi

    cat > "${YAZI_CONFIG_DIR}/theme.toml" << 'EOL'
[flavor]
dark = "catppuccin-mocha"
light = "catppuccin-mocha"
EOL

    if command_exists ya; then
        ya pack -a yazi-rs/flavors:catppuccin-mocha || \
            log "WARNING" "Failed to install Catppuccin theme"
    fi
    
    log "SUCCESS" "Yazi theme configured successfully"
}
