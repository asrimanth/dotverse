#!/bin/sh

readonly UV_INSTALL_URL="https://astral.sh/uv/install.sh"

check_uv_status() {
    if command_exists uv; then
        echo "${CHECK_MARK} UV (Python package manager)"
    else
        echo "UV (Python package manager)"
    fi
}

setup_uv() {
    local force_reinstall="${1:-false}"
    
    log "INFO" "Setting up UV Python package manager..."
    
    # Check if UV is already installed
    if command_exists uv && [ "$force_reinstall" = false ]; then
        log "INFO" "UV is already installed"
        return 0
    fi

    # Detect package manager and install UV
    local package_manager
    package_manager=$(detect_package_manager)

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
            
            curl -LsSf "$UV_INSTALL_URL" | sh || error_exit "Failed to install UV using installation script"
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
