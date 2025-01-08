#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}==> ${1}${NC}"
}

# Function to check URL availability
check_url() {
    if curl --output /dev/null --silent --head --fail "$1"; then
        return 0
    else
        return 1
    fi
}

# Check and install ZSH if not present
setup_zsh() {
    if ! command_exists zsh; then
        print_status "Installing ZSH..."
        if command_exists apt; then
            sudo apt update && sudo apt install -y zsh
        elif command_exists dnf; then
            sudo dnf install -y zsh
        elif command_exists brew; then
            brew install zsh
        else
            echo -e "${RED}Error: Package manager not found. Please install ZSH manually.${NC}"
            exit 1
        fi
    fi

    # Set ZSH as default shell
    if [[ $SHELL != *"zsh"* ]]; then
        print_status "Setting ZSH as default shell..."
        chsh -s $(which zsh)
    fi
}

# Install Starship if not present
setup_starship() {
    if ! command_exists starship; then
        print_status "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh
    fi
}

# Setup ZSH extensions
setup_zsh_extensions() {
    print_status "Setting up ZSH extensions..."
    
    # Create .zsh directory if it doesn't exist
    mkdir -p ~/.zsh

    # Install/update zsh-autosuggestions
    if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi

    # Install/update zsh-syntax-highlighting
    if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
    fi
}

# Setup tmux configuration
setup_tmux() {
    print_status "Setting up tmux configuration..."

    # Check if tmux is installed, if not install it
    if ! command_exists tmux; then
        print_status "Installing tmux..."
        if command_exists apt; then
            sudo apt update && sudo apt install -y tmux
        elif command_exists dnf; then
            sudo dnf install -y tmux
        elif command_exists brew; then
            brew install tmux
        else
            echo -e "${RED}Error: Package manager not found. Please install tmux manually.${NC}"
            return 1
        fi
    fi

    # Backup existing tmux config if it exists
    if [ -f ~/.tmux.conf ]; then
        print_status "Backing up existing tmux configuration..."
        mv ~/.tmux.conf ~/.tmux.conf.backup
    fi

    # Remove existing tmux config if it exists
    rm -rf ~/.tmux.conf

    # Move tmux configuration from current directory
    cp ./.tmux.conf ~/.tmux.conf
}

# Download Starship presets with validation
download_starship_presets() {
    local gruvbox_url="https://starship.rs/presets/toml/gruvbox-rainbow.toml"
    local tokyo_url="https://starship.rs/presets/toml/tokyo-night.toml"
    
    if check_url "$gruvbox_url"; then
        curl -o ~/.starship/presets/gruvbox-rainbow.toml "$gruvbox_url"
    else
        echo -e "${RED}Error: Unable to download gruvbox-rainbow preset${NC}"
        return 1
    fi
    
    if check_url "$tokyo_url"; then
        curl -o ~/.starship/presets/tokyo-night.toml "$tokyo_url"
    else
        echo -e "${RED}Error: Unable to download tokyo-night preset${NC}"
        return 1
    fi
}

# Setup Starship configuration
setup_zshrc() {
    print_status "Setting up Starship configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p ~/.starship/presets

    # Backup existing zshrc if it exists
    if [ -f ~/.zshrc ]; then
        print_status "Backing up existing zshrc configuration..."
        mv ~/.zshrc ~/.zshrc.backup
    fi

    # Remove existing zshrc if it exists
    rm -rf ~/.zshrc

    # Download presets
    download_starship_presets

    # Create/update .zshrc
    cat > ~/.zshrc << 'EOL'
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
}

# Install fzf if not present
install_fzf() {
    if ! command_exists fzf; then
        print_status "Installing fzf..."
        if command_exists apt; then
            sudo apt update && sudo apt install -y fzf
        elif command_exists dnf; then
            sudo dnf install -y fzf
        elif command_exists brew; then
            brew install fzf
        else
            echo -e "${RED}Error: Package manager not found. Please install fzf manually.${NC}"
            exit 1
        fi
    fi
}

# Function to setup Catppuccin theme for Yazi
setup_yazi_theme() {
    print_status "Setting up Catppuccin theme for Yazi..."
    
    # Create Yazi config directory
    mkdir -p ~/.config/yazi
    
    # Create theme.toml
    cat > ~/.config/yazi/theme.toml << 'EOL'
[flavor]
dark = "catppuccin-mocha"
light = "catppuccin-mocha"
EOL

    # Install the Catppuccin theme using Yazi's package manager
    if command_exists ya; then
        ya pack -a yazi-rs/flavors:catppuccin-mocha
    fi
}

# Function to install Yazi
setup_yazi() {
    print_status "Setting up Yazi file manager..."
    
    if command_exists brew; then
        # macOS installation
        brew install yazi
    else
        # Ubuntu/Debian installation
        print_status "Installing Yazi dependencies..."
        sudo apt update && sudo apt install -y \
            ffmpeg \
            p7zip-full \
            jq \
            poppler-utils \
            fd-find \
            ripgrep \
            fzf \
            zoxide \
            imagemagick

        # Create temporary directory for download
        local tmp_dir=$(mktemp -d)
        
        # Download latest Yazi release for Ubuntu (x86_64)
        curl -L https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.tar.gz -o "$tmp_dir/yazi.tar.gz"
        
        # Extract the binary
        tar xf "$tmp_dir/yazi.tar.gz" -C "$tmp_dir"
        
        # Move yazi binary to /usr/local/bin
        sudo mv "$tmp_dir/yazi" /usr/local/bin/
        sudo mv "$tmp_dir/ya" /usr/local/bin/
        
        # Cleanup
        rm -rf "$tmp_dir"
    fi

    # Setup the theme
    setup_yazi_theme
}

# Main execution with interactive menu
main() {
    print_status "Starting development environment setup..."
    install_fzf

    # Define options
    options=("ZSH" "Starship" "ZSH Extensions" "tmux" "Yazi")

    # Use fzf to create a checkbox menu
    selected_options=$(printf '%s\n' "${options[@]}" | fzf --multi --ansi --prompt "Select components to install: ")

    [[ "$selected_options" =~ "ZSH" ]] && setup_zsh
    [[ "$selected_options" =~ "Starship" ]] && setup_starship
    [[ "$selected_options" =~ "ZSH Extensions" ]] && setup_zsh_extensions
    [[ "$selected_options" =~ "tmux" ]] && setup_tmux
    [[ "$selected_options" =~ "Yazi" ]] && setup_yazi

    print_status "All done! Restart your shell for the changes to take effect."
}

# Run the script
main
