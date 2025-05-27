#!/bin/sh

check_go_status() {
    if command_exists go; then
        echo "${CHECK_MARK} Go (Go programming language)"
    else
        echo "Go (Go programming language)"
    fi
}

setup_go() {
    local force_reinstall="${1:-false}"
    
    log "INFO" "Setting up Go programming language..."
    
    # Check if Go is already installed
    if command_exists go && [ "$force_reinstall" = false ]; then
        log "INFO" "Go is already installed"
        return 0
    fi

    # Detect package manager and install Go
    local package_manager
    package_manager=$(detect_package_manager)

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
