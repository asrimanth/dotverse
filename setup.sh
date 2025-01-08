#!/bin/bash

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME=$(basename "$0")

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# URLs
readonly STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
readonly STARSHIP_PRESET_URLS=(
    "https://starship.rs/presets/toml/gruvbox-rainbow.toml"
    "https://starship.rs/presets/toml/tokyo-night.toml"
)
readonly STARSHIP_PRESET_NAMES=(
    "gruvbox-rainbow.toml"
    "tokyo-night.toml"
)

# Repository URLs
readonly ZSH_AUTOSUGGESTIONS_URL="https://github.com/zsh-users/zsh-autosuggestions"
readonly ZSH_SYNTAX_HIGHLIGHTING_URL="https://github.com/zsh-users/zsh-syntax-highlighting.git"
readonly YAZI_RELEASE_URL="https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.tar.gz"

# Directory constants
readonly ZSH_DIR="${HOME}/.zsh"
readonly STARSHIP_DIR="${HOME}/.starship"
readonly CONFIG_DIR="${HOME}/.config"
readonly YAZI_CONFIG_DIR="${CONFIG_DIR}/yazi"

# Log levels
# declare -A LOG_LEVELS=( 
#     ["ERROR"]=0
#     ["WARNING"]=1
#     ["INFO"]=2
#     ["SUCCESS"]=3
# )

# Logging functions
log() {
    local level=$1
    local message=$2
    local color

    case $level in
        "ERROR")   color=$RED ;;
        "WARNING") color=$YELLOW ;;
        "INFO")    color=$YELLOW ;;
        "SUCCESS") color=$GREEN ;;
        *)         color=$NC ;;
    esac

    echo -e "${color}[${level}] ${message}${NC}"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if directory exists and is not empty
directory_exists_and_populated() {
    [ -d "$1" ] && [ "$(ls -A "$1" 2>/dev/null)" ]
}

# URL availability check
check_url() {
    if ! curl --output /dev/null --silent --head --fail "$1"; then
        return 1
    fi
    return 0
}

# Package manager detection
detect_package_manager() {
    if command_exists apt; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists brew; then
        echo "brew"
    else
        error_exit "No supported package manager found (apt, dnf, or brew)"
    fi
}

# Package installation
install_package() {
    local package=$1
    local package_manager=$(detect_package_manager)
    
    if command_exists "$package"; then
        log "INFO" "$package is already installed"
        return 0
    fi

    log "INFO" "Installing $package..."
    case $package_manager in
        "apt")
            sudo apt update && sudo apt install -y "$package" || error_exit "Failed to install $package"
            ;;
        "dnf")
            sudo dnf install -y "$package" || error_exit "Failed to install $package"
            ;;
        "brew")
            brew install "$package" || error_exit "Failed to install $package"
            ;;
    esac
    
    log "SUCCESS" "$package installed successfully"
}

# Backup file if it exists
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        log "INFO" "Backing up existing $file..."
        mv "$file" "${file}.backup" || error_exit "Failed to backup $file"
        log "SUCCESS" "Backup created: ${file}.backup"
    fi
}

setup_zsh() {
    if command_exists zsh; then
        log "INFO" "ZSH is already installed"
    else
        install_package "zsh"
    fi

    if [[ $SHELL != *"zsh"* ]]; then
        log "SUCCESS" "Setting ZSH as default shell..."
        chsh -s "$(which zsh)" || error_exit "Failed to set ZSH as default shell"
        log "SUCCESS" "ZSH set as default shell"
    else
        log "INFO" "ZSH is already the default shell"
    fi
}

setup_starship() {
    if command_exists starship; then
        log "INFO" "Starship is already installed"
        return 0
    fi

    log "INFO" "Installing Starship..."
    curl -sS "$STARSHIP_INSTALL_URL" | sh || error_exit "Failed to install Starship"
    log "SUCCESS" "Starship installed successfully"
}

setup_zsh_extensions() {
    log "SUCCESS" "Setting up ZSH extensions..."
    
    mkdir -p "$ZSH_DIR"

    # Install/update zsh-autosuggestions
    if directory_exists_and_populated "${ZSH_DIR}/zsh-autosuggestions"; then
        log "INFO" "zsh-autosuggestions is already installed"
    else
        git clone "$ZSH_AUTOSUGGESTIONS_URL" "${ZSH_DIR}/zsh-autosuggestions" || \
            error_exit "Failed to clone zsh-autosuggestions"
        log "SUCCESS" "zsh-autosuggestions installed successfully"
    fi

    # Install/update zsh-syntax-highlighting
    if directory_exists_and_populated "${ZSH_DIR}/zsh-syntax-highlighting"; then
        log "INFO" "zsh-syntax-highlighting is already installed"
    else
        git clone "$ZSH_SYNTAX_HIGHLIGHTING_URL" "${ZSH_DIR}/zsh-syntax-highlighting" || \
            error_exit "Failed to clone zsh-syntax-highlighting"
        log "SUCCESS" "zsh-syntax-highlighting installed successfully"
    fi
}

setup_tmux() {
    log "SUCCESS" "Setting up tmux configuration..."

    if command_exists tmux; then
        log "INFO" "tmux is already installed"
    else
        install_package "tmux"
    fi

    # Backup and update tmux configuration
    backup_file "${HOME}/.tmux.conf"
    
    if [ -f "./.tmux.conf" ]; then
        cp "./.tmux.conf" "${HOME}/.tmux.conf" || error_exit "Failed to copy tmux configuration"
        log "SUCCESS" "tmux configuration updated"
    else
        log "WARNING" ".tmux.conf not found in current directory. Please add ./tmux.conf manually to ${HOME}/.tmux.conf"
    fi
}
setup_yazi() {
    log "SUCCESS" "Setting up Yazi file manager..."
    
    if command_exists yazi; then
        log "INFO" "Yazi is already installed"
    else
        if command_exists brew; then
            brew install ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide imagemagick font-symbols-only-nerd-font
            install_package "yazi"
        else
            install_yazi_dependencies
            install_yazi_binary
        fi
    fi

    setup_yazi_theme
}

install_yazi_dependencies() {
    log "INFO" "Installing Yazi dependencies..."
    local dependencies=(
        "ffmpeg"
        "p7zip-full"
        "jq"
        "poppler-utils"
        "fd-find"
        "ripgrep"
        "fzf"
        "zoxide"
        "imagemagick"
    )

    for dep in "${dependencies[@]}"; do
        install_package "$dep"
    done
}

install_yazi_binary() {
    local tmp_dir=$(mktemp -d)
    
    log "INFO" "Downloading Yazi..."
    curl -L "$YAZI_RELEASE_URL" -o "$tmp_dir/yazi.tar.gz" || \
        error_exit "Failed to download Yazi"
    
    tar xf "$tmp_dir/yazi.tar.gz" -C "$tmp_dir" || \
        error_exit "Failed to extract Yazi"
    
    sudo mv "$tmp_dir/yazi" /usr/local/bin/ || error_exit "Failed to install Yazi binary"
    sudo mv "$tmp_dir/ya" /usr/local/bin/ || error_exit "Failed to install Ya binary"
    
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

download_starship_presets() {
    mkdir -p "${STARSHIP_DIR}/presets"
    
    local index=0
    for url in "${STARSHIP_PRESET_URLS[@]}"; do
        local preset_name="${STARSHIP_PRESET_NAMES[$index]}"
        local preset_path="${STARSHIP_DIR}/presets/${preset_name}"
        
        if [ -f "$preset_path" ]; then
            log "INFO" "Preset $preset_name already exists"
        else
            if check_url "$url"; then
                curl -o "$preset_path" "$url" || \
                    error_exit "Failed to download $preset_name"
                log "SUCCESS" "Downloaded $preset_name"
            else
                error_exit "Unable to download $preset_name (URL not accessible)"
            fi
        fi
        ((index++))
    done
}

setup_zshrc() {
    log "SUCCESS" "Setting up zshrc configuration..."
    
    mkdir -p "${STARSHIP_DIR}/presets"

    backup_file "${HOME}/.zshrc"
    download_starship_presets

    cat > "${HOME}/.zshrc" << 'EOL'
# Enable Starship
eval "$(starship init zsh)"

# Starship preset
export STARSHIP_CONFIG=~/.starship/presets/gruvbox-rainbow.toml

# Source ZSH extensions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

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
    tmux source-file ~/.tmux.conf
fi
EOL
    log "SUCCESS" "zshrc configuration created successfully"
}

install_fzf() {
    if command_exists fzf; then
        log "INFO" "fzf is already installed"
        return 0
    fi
    
    install_package "fzf"
}

main() {
    log "INFO" "Starting development environment setup (v${SCRIPT_VERSION})..."
    
    # Install fzf first as it's needed for the menu
    install_fzf

    # Define options
    local options=("ZSH" "Starship" "ZSH Extensions" "tmux" "Yazi")

    # Use fzf to create a checkbox menu
    local selected_options=$(printf '%s\n' "${options[@]}" | \
        fzf --multi --ansi --layout=reverse --bind "space:toggle" \
        --header 'Use Space to select/deselect. Confirm with ENTER. Press Ctrl+C or ESC to exit.' \
            --prompt "Select components to install: ")

    [[ "$selected_options" =~ "ZSH" ]] && setup_zsh
    [[ "$selected_options" =~ "Starship" ]] && setup_starship
    [[ "$selected_options" =~ "ZSH Extensions" ]] && setup_zsh_extensions
    [[ "$selected_options" =~ "tmux" ]] && setup_tmux
    [[ "$selected_options" =~ "Yazi" ]] && setup_yazi

    # Always set up zshrc after all components are installed
    if [[ "$selected_options" =~ "ZSH" ]] || [[ "$selected_options" =~ "Starship" ]] || \
       [[ "$selected_options" =~ "ZSH Extensions" ]]; then
        setup_zshrc
    fi

    log "SUCCESS" "Setup complete! Please restart your shell for changes to take effect."
}

# Run the script
main