#!/bin/sh

check_nvtop_status() {
    if command_exists nvtop; then
        echo "${CHECK_MARK} nvtop (Nvidia GPU monitoring)"
    else
        echo "nvtop (Nvidia GPU monitoring)"
    fi
}

setup_nvtop() {
    local force_reinstall="${1:-false}"
    
    log "INFO" "Setting up nvtop (Nvidia GPU monitoring tool)..."

    # Check if nvtop is already installed
    if command_exists nvtop && [ "$force_reinstall" = false ]; then
        log "INFO" "nvtop is already installed"
        return 0
    fi

    # Detect package manager and install nvtop
    local package_manager
    package_manager=$(detect_package_manager)

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
