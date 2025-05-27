#!/bin/sh

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color
readonly CHECK_MARK="✓"

# Add these variables near the top of the script with other readonly variables
readonly APT_UPDATED_FLAG="/tmp/apt_updated_${USER}"

# Directory constants
readonly ZSH_DIR="${HOME}/.config/zsh/extensions"
readonly STARSHIP_DIR="${HOME}/.config/starship"
readonly CONFIG_DIR="${HOME}/.config"
readonly YAZI_CONFIG_DIR="${CONFIG_DIR}/yazi"

# Check if running as root
is_root_user() {
    [ "$(id -u)" -eq 0 ]
}

# Logging functions
log() {
    local level="$1"
    local message="$2"
    local color

    case $level in
        "ERROR")   color=$RED ;;
        "WARNING") color=$YELLOW ;;
        "INFO")    color=$YELLOW ;;
        "SUCCESS") color=$GREEN ;;
        *)         color=$NC ;;
    esac

    printf "${color}[%s] %s${NC}\n" "$level" "$message"
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
    curl --output /dev/null --silent --head --fail "$1"
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
    local package_manager
    package_manager=$(detect_package_manager)
    
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
    local package="$1"
    local force_reinstall="${2:-false}"
    local package_manager
    package_manager=$(detect_package_manager)
    
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

# Add this function near the other utility functions
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup" || error_exit "Failed to create backup of $file"
        log "INFO" "Created backup of $file at $backup"
    fi
}
