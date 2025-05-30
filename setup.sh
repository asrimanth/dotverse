#!/bin/sh

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME=$(basename "$0")

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color
readonly CHECK_MARK="✓"

# Add these variables near the top of the script with other readonly variables
readonly APT_UPDATED_FLAG="/tmp/apt_updated_${USER}"

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
readonly YAZI_RELEASE_URL="https://github.com/sxyazi/yazi/releases/download/v0.4.2/yazi-x86_64-unknown-linux-gnu.zip"

# Directory constants
readonly ZSH_DIR="${HOME}/.config/zsh/extensions"
readonly STARSHIP_DIR="${HOME}/.config/starship"
readonly CONFIG_DIR="${HOME}/.config"
readonly YAZI_CONFIG_DIR="${CONFIG_DIR}/yazi"

# Check if running as root
is_root_user() {
    [ "$(id -u)" -eq 0 ]
}

# Component status checking functions
check_zsh_status() {
    if command_exists zsh; then
        if [[ $SHELL == *"zsh"* ]]; then
            echo "${CHECK_MARK} ZSH Shell (Installed & Default)"
        else
            echo "${CHECK_MARK} ZSH Shell (Installed but not Default)"
        fi
    else
        echo "ZSH Shell"
    fi
}

check_starship_status() {
    if command_exists starship; then
        echo "${CHECK_MARK} Starship Prompt (Modern shell prompt)"
    else
        echo "Starship Prompt (Modern shell prompt)"
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

check_tmux_status() {
    if command_exists tmux; then
        echo "${CHECK_MARK} Tmux (Terminal Multiplexer)"
    else
        echo "Tmux (Terminal Multiplexer)"
    fi
}

check_yazi_status() {
    if command_exists yazi; then
        echo "${CHECK_MARK} Yazi (Modern File Manager)"
    else
        echo "Yazi (Modern File Manager)"
    fi
}

check_go_status() {
    if command_exists go; then
        echo "${CHECK_MARK} Go (Go programming language)"
    else
        echo "Go (Go programming language)"
    fi
}

check_nvtop_status() {
    if command_exists nvtop; then
        echo "${CHECK_MARK} nvtop (Nvidia GPU monitoring)"
    else
        echo "nvtop (Nvidia GPU monitoring)"
    fi
}

check_uv_status() {
    if command_exists uv; then
        echo "${CHECK_MARK} UV (Python package manager)"
    else
        echo "UV (Python package manager)"
    fi
}

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

    echo "${color}[${level}] ${message}${NC}"
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
    elif command_exists brew; then
        echo "brew"
    else
        error_exit "No supported package manager found (apt, or brew)"
    fi
}

# Function to safely update package manager
update_package_manager() {
    local package_manager=$(detect_package_manager)
    
    case $package_manager in
        "apt")
            if [ ! -f "$APT_UPDATED_FLAG" ]; then
                log "INFO" "Updating apt package lists..."
                if is_root_user; then
                    apt update || error_exit "Failed to update apt package lists"
                else
                    sudo apt update || error_exit "Failed to update apt package lists"
                fi
                touch "$APT_UPDATED_FLAG"
            fi
            ;;
        "brew")
            # Homebrew handles its own caching, no explicit update needed
            ;;
    esac
}


# Modified install_package function
install_package() {
    local package=$1
    local force_reinstall=${2:-false}
    local package_manager=$(detect_package_manager)
    
    if command_exists "$package" && [ "$force_reinstall" = false ]; then
        log "INFO" "$package is already installed"
        return 0
    fi

    if [ "$force_reinstall" = true ]; then
        log "INFO" "Reinstalling $package..."
    else
        log "INFO" "Installing $package..."
    fi

    # Ensure package manager is updated before installation
    update_package_manager

    case $package_manager in
        "apt")
            if is_root_user; then
                apt install --reinstall -y "$package" || error_exit "Failed to install $package"
            else
                sudo apt install --reinstall -y "$package" || error_exit "Failed to install $package"
            fi
            ;;
        "brew")
            brew reinstall "$package" || error_exit "Failed to install $package"
            ;;
    esac
    
    log "SUCCESS" "$package installed successfully"
}


# Rest of the functions remain the same, but add force_reinstall parameter
setup_zsh() {
    local force_reinstall=${1:-false}
    if command_exists zsh && [ "$force_reinstall" = false ]; then
        log "INFO" "ZSH is already installed"
    else
        install_package "zsh" "$force_reinstall"
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
    local force_reinstall=${1:-false}

    if command_exists starship && [ "$force_reinstall" = false ]; then
        log "INFO" "Starship is already installed"
        return 0
    fi

    if [ "$force_reinstall" = true ]; then
        log "INFO" "Reinstalling Starship..."
    else
        log "INFO" "Installing Starship..."
    fi

    if command_exists brew; then
        # Use brew to install Starship if it is available
        log "INFO" "Homebrew detected, using brew to install Starship"
        if [ "$force_reinstall" = true ]; then
            brew reinstall starship || error_exit "Failed to reinstall Starship using Homebrew"
        else
            brew install starship || error_exit "Failed to install Starship using Homebrew"
        fi
    else
        # Fallback to Starship's installation script if brew is not available
        log "INFO" "Homebrew not detected, using curl to install Starship"
        curl -sS "$STARSHIP_INSTALL_URL" >> dotverse_starship_rs_latest_install.sh
        bash --posix dotverse_starship_rs_latest_install.sh || error_exit "Failed to install Starship using installation script"
        rm -rf dotverse_starship_rs_latest_install.sh
    fi

    log "SUCCESS" "Starship installed successfully"
}

setup_zsh_extensions() {
    local force_reinstall=${1:-false}
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

# Add this function near the other utility functions
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup" || error_exit "Failed to create backup of $file"
        log "INFO" "Created backup of $file at $backup"
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
    if ! grep -q "run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux" "$HOME/.tmux.conf"; then
        echo "run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux" >> "$HOME/.tmux.conf"
        log "SUCCESS" "Added Catppuccin theme run line to tmux.conf"
    else
        log "INFO" "Catppuccin theme run line already in tmux.conf"
    fi

    log "SUCCESS" "Catppuccin theme for tmux setup successfully. Reload tmux with 'tmux source ~/.tmux.conf'."
}

setup_tmux() {
    local force_reinstall=${1:-false}
    
    log "INFO" "Setting up tmux..."
    
    install_package "tmux" "$force_reinstall"

    if [ "$force_reinstall" = true ]; then
        setup_tmux_catppuccin_theme
    else
        if [ -f "$HOME/.tmux.conf" ]; then
            cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
            log "INFO" "Backed up existing tmux.conf"
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
    fi
}

setup_yazi() {
    local force_reinstall=${1:-false}
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
    
    chmod 744 "$tmp_dir/yazi.tar.gz"
    unzip "$tmp_dir/yazi.tar.gz" -d "$tmp_dir" || \
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

download_starship_presets() {
    mkdir -p "${STARSHIP_DIR}"
    
    local index=0
    for url in "${STARSHIP_PRESET_URLS[@]}"; do
        local preset_name="${STARSHIP_PRESET_NAMES[$index]}"
        local preset_path="${STARSHIP_DIR}/${preset_name}"
        
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
    
    mkdir -p "${STARSHIP_DIR}"
    cp gruvbox-custom.toml "$STARSHIP_DIR"

    backup_file "${HOME}/.zshrc"
    download_starship_presets

    cat > "${HOME}/.zshrc" << 'EOL'
# Enable Starship
eval "$(starship init zsh)"

# Starship preset
export STARSHIP_CONFIG=~/.config/starship/gruvbox-custom.toml

# Source ZSH extensions
source ~/.config/zsh/extensions/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/extensions/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

setup_go() {
    local force_reinstall=${1:-false}
    
    log "INFO" "Setting up Go programming language..."
    
    # Check if Go is already installed
    if command_exists go && [ "$force_reinstall" = false ]; then
        log "INFO" "Go is already installed"
        return 0
    fi

    # Detect package manager and install Go
    local package_manager=$(detect_package_manager)

    case $package_manager in
        "brew")
            log "INFO" "Using Homebrew to install Go"
            if [ "$force_reinstall" = true ]; then
                brew reinstall go || error_exit "Failed to reinstall Go using Homebrew"
            else
                brew install go || error_exit "Failed to install Go using Homebrew"
            fi
            ;;

        "apt")
            log "INFO" "Using apt to install Go"
            update_package_manager

            # Install necessary tools and add Go repository
            install_package "software-properties-common" "$force_reinstall"
            if [ "$force_reinstall" = true ]; then
                if is_root_user; then
                    add-apt-repository --remove ppa:longsleep/golang-backports || true
                else
                    sudo add-apt-repository --remove ppa:longsleep/golang-backports || true
                fi
            fi
            if is_root_user; then
                add-apt-repository ppa:longsleep/golang-backports -y || error_exit "Failed to add Go PPA repository"
            else
                sudo add-apt-repository ppa:longsleep/golang-backports -y || error_exit "Failed to add Go PPA repository"
            fi

            update_package_manager

            # Install Go
            if is_root_user; then
                apt install -y golang-go || error_exit "Failed to install Go using apt"
            else
                sudo apt install -y golang-go || error_exit "Failed to install Go using apt"
            fi
            ;;

        *)
            error_exit "Unsupported package manager for Go installation"
            ;;
    esac

    # Verify installation
    if command_exists go; then
        log "SUCCESS" "Go installed successfully"
    else
        error_exit "Go installation failed"
    fi
}

setup_nvtop() {
    local force_reinstall=${1:-false}
    
    log "INFO" "Setting up nvtop (Nvidia GPU monitoring tool)..."

    # Check if nvtop is already installed
    if command_exists nvtop && [ "$force_reinstall" = false ]; then
        log "INFO" "nvtop is already installed"
        return 0
    fi

    # Detect package manager and install nvtop
    local package_manager=$(detect_package_manager)

    case $package_manager in
        "brew")
            log "INFO" "Using Homebrew to install nvtop"
            if [ "$force_reinstall" = true ]; then
                brew reinstall nvtop || error_exit "Failed to reinstall nvtop using Homebrew"
            else
                brew install nvtop || error_exit "Failed to install nvtop using Homebrew"
            fi
            ;;

        "apt")
            log "INFO" "Using apt to install nvtop"
            update_package_manager
            if is_root_user; then
                apt install -y nvtop || error_exit "Failed to install nvtop using apt"
            else
                sudo apt install -y nvtop || error_exit "Failed to install nvtop using apt"
            fi
            ;;

        *)
            error_exit "Unsupported package manager for nvtop installation"
            ;;
    esac

    # Verify installation
    if command_exists nvtop; then
        log "SUCCESS" "nvtop installed successfully"
    else
        error_exit "nvtop installation failed"
    fi
}

setup_uv() {
    local force_reinstall=${1:-false}
    
    log "INFO" "Setting up UV Python package manager..."
    
    # Check if UV is already installed
    if command_exists uv && [ "$force_reinstall" = false ]; then
        log "INFO" "UV is already installed"
        return 0
    fi

    # Detect package manager and install UV
    local package_manager=$(detect_package_manager)

    case $package_manager in
        "brew")
            log "INFO" "Using Homebrew to install UV"
            if [ "$force_reinstall" = true ]; then
                brew reinstall uv || error_exit "Failed to reinstall UV using Homebrew"
            else
                brew install uv || error_exit "Failed to install UV using Homebrew"
            fi
            ;;

        "apt")
            log "INFO" "Using curl to install UV"
            if [ "$force_reinstall" = true ]; then
                log "INFO" "Reinstalling UV..."
            else
                log "INFO" "Installing UV..."
            fi
            
            curl -LsSf https://astral.sh/uv/install.sh | sh || error_exit "Failed to install UV using installation script"
            ;;

        *)
            error_exit "Unsupported package manager for UV installation"
            ;;
    esac

    # Verify installation
    if command_exists uv; then
        log "SUCCESS" "UV installed successfully"
    else
        error_exit "UV installation failed"
    fi
}


main() {
    # Remove any existing apt update flag at the start
    rm -f "$APT_UPDATED_FLAG"

    log "INFO" "Starting development environment setup (v${SCRIPT_VERSION})..."
    
    # Install fzf first as it's needed for the menu
    install_package "fzf"

    # Define options with status checks
    local options=(
        "$(check_zsh_status)"
        "$(check_starship_status)"
        "$(check_zsh_extensions_status)"
        "$(check_tmux_status)"
        "$(check_yazi_status)"
        "$(check_go_status)"
        "$(check_nvtop_status)"
        "$(check_uv_status)"
    )
    # Debug: Print available options
    log "DEBUG" "Available options:"
    printf '%s\n' "${options[@]}"

    # Create temporary file for fzf output
    local tmp_file=$(mktemp)

    # Run fzf and save output
    printf '%s\n' "${options[@]}" | \
        fzf --multi --ansi --layout=reverse --bind "space:toggle" \
        --header 'Use Space to select/deselect. Press Enter to confirm. Selected items with ✓ will be reinstalled.' \
        --prompt "Select components to install/reinstall: " > "$tmp_file"

    # Read selections from temp file
    local selected_options=$(<"$tmp_file")
    rm -f "$tmp_file"

    # Debug: Print selections
    log "DEBUG" "Selected options:"
    echo "$selected_options"

    # Process selections with case-insensitive matching
    if echo "$selected_options" | grep -qi "Tmux"; then
        log "DEBUG" "Tmux selected for installation"
        local force_reinstall=$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)
        log "DEBUG" "force_reinstall value: $force_reinstall"
        setup_tmux "$force_reinstall"
    fi

    if echo "$selected_options" | grep -q "ZSH Shell"; then
        setup_zsh "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "Starship Prompt"; then
        setup_starship "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "ZSH Extensions"; then
        setup_zsh_extensions "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "Yazi"; then
        setup_yazi "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    # Always set up zshrc after all components are installed
    if echo "$selected_options" | grep -qE "ZSH Shell|Starship Prompt|ZSH Extensions"; then
        setup_zshrc
    fi
    if echo "$selected_options" | grep -q "Go"; then
       setup_go "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "UV"; then
        setup_uv "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    log "SUCCESS" "Setup complete! Please restart your shell for changes to take effect."
}

# Run the script
main
