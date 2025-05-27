#!/bin/sh

# URLs
readonly STARSHIP_INSTALL_URL="https://starship.rs/install.sh"

readonly STARSHIP_PRESET_URLS="https://starship.rs/presets/toml/gruvbox-rainbow.toml
https://starship.rs/presets/toml/tokyo-night.toml"

readonly STARSHIP_PRESET_NAMES="gruvbox-rainbow.toml
tokyo-night.toml"

check_starship_status() {
    if command_exists starship; then
        echo "${CHECK_MARK} Starship Prompt (Modern shell prompt)"
    else
        echo "Starship Prompt (Modern shell prompt)"
    fi
}

setup_starship() {
    local force_reinstall="${1:-false}"

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
        curl -sS "$STARSHIP_INSTALL_URL" > dotverse_starship_rs_latest_install.sh
        sh dotverse_starship_rs_latest_install.sh || error_exit "Failed to install Starship using installation script"
        rm -rf dotverse_starship_rs_latest_install.sh
    fi

    log "SUCCESS" "Starship installed successfully"
}

download_starship_presets() {
    mkdir -p "${STARSHIP_DIR}"
    
    local index=0
    echo "$STARSHIP_PRESET_URLS" | while IFS= read -r url; do
        local preset_name
        preset_name=$(echo "$STARSHIP_PRESET_NAMES" | sed -n "$((index + 1))p")
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
        index=$((index + 1))
    done
}
