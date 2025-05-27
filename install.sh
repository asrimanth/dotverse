#!/bin/sh

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source utilities and installers
. "${SCRIPT_DIR}/utils.sh"
. "${SCRIPT_DIR}/installers/zsh_installer.sh"
. "${SCRIPT_DIR}/installers/starship_installer.sh"
. "${SCRIPT_DIR}/installers/tmux_installer.sh"
. "${SCRIPT_DIR}/installers/yazi_installer.sh"
. "${SCRIPT_DIR}/installers/go_installer.sh"
. "${SCRIPT_DIR}/installers/nvtop_installer.sh"
. "${SCRIPT_DIR}/installers/uv_installer.sh"

main() {
    # Remove any existing apt update flag at the start
    rm -f "$APT_UPDATED_FLAG"

    log "INFO" "Starting development environment setup (v${SCRIPT_VERSION})..."
    
    # Install fzf first as it's needed for the menu
    install_package "fzf"

    # Define options with status checks
    local options
    options="$(check_zsh_status)
$(check_starship_status)
$(check_zsh_extensions_status)
$(check_tmux_status)
$(check_yazi_status)
$(check_nvtop_status)
$(check_uv_status)
$(check_go_status)"

    # Create temporary file for fzf output
    local tmp_file
    tmp_file=$(mktemp)

    # Run fzf and save output
    printf '%s\n' "$options" | \
        fzf --multi --ansi --layout=reverse --bind "space:toggle" \
        --header 'Use Space to select/deselect. Press Enter to confirm. Selected items with ✓ will be reinstalled.' \
        --prompt "Select components to install/reinstall: " > "$tmp_file"

    # Read selections from temp file
    local selected_options
    selected_options=$(<"$tmp_file")
    rm -f "$tmp_file"

    # Process selections
    if echo "$selected_options" | grep -q "ZSH Shell"; then
        setup_zsh "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "Starship Prompt"; then
        setup_starship "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "ZSH Extensions"; then
        setup_zsh_extensions "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "Tmux"; then
        setup_tmux "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "Yazi"; then
        setup_yazi "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "nvtop"; then
        setup_nvtop "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "UV"; then
        setup_uv "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    if echo "$selected_options" | grep -q "Go"; then
        setup_go "$(echo "$selected_options" | grep -q "^${CHECK_MARK}" && echo true || echo false)"
    fi

    # Always set up zshrc after all components are installed
    if echo "$selected_options" | grep -qE "ZSH Shell|Starship Prompt|ZSH Extensions"; then
        setup_zshrc
    fi

    log "SUCCESS" "Setup complete! Please restart your shell for changes to take effect."
}

# Run the script
main "$@"
