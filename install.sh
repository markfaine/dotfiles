#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Bootstrap Installer
# ==============================================================================
# Quick install: curl -fsSL https://raw.githubusercontent.com/markfaine/dotfiles/main/install.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/markfaine/dotfiles/main/install.sh | bash
#
# This script will:
#   1. Clone dotfiles repository to ~/.config/dotfiles
#   2. Install tuckr (dotfiles manager)
#   3. Deploy all dotfiles using tuckr
#
# Requirements: git, curl or wget, bash
# ==============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# ==============================================================================
# Configuration
# ==============================================================================
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/markfaine/dotfiles.git}"
DOTFILES_DIR="${HOME}/.config/dotfiles"
TUCKR_VERSION="${TUCKR_VERSION:-latest}"
LOCAL_BIN="${HOME}/.local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Helper Functions
# ==============================================================================

# Print colored messages
info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and architecture
detect_platform() {
    local os arch

    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux";;
        Darwin*)    os="darwin";;
        *)          error "Unsupported OS: $(uname -s)"; exit 1;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        x86_64)     arch="x86_64";;
        aarch64)    arch="aarch64";;
        arm64)      arch="aarch64";;
        *)          error "Unsupported architecture: $(uname -m)"; exit 1;;
    esac

    echo "${arch}-${os}"
}

# Get latest tuckr version from GitHub
get_latest_tuckr_version() {
    local version

    if command_exists curl; then
        version=$(curl -fsSL https://api.github.com/repos/RaphGL/Tuckr/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command_exists wget; then
        version=$(wget -qO- https://api.github.com/repos/RaphGL/Tuckr/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        error "Neither curl nor wget found. Cannot fetch latest version."
        exit 1
    fi

    echo "$version"
}

# ==============================================================================
# Installation Steps
# ==============================================================================

# Step 1: Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    local missing=()

    # Essential tools
    if ! command_exists git; then
        missing+=("git")
    fi

    if ! command_exists curl && ! command_exists wget; then
        missing+=("curl or wget")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        error "Please install them and try again."
        exit 1
    fi

    success "All prerequisites found"
}

# Step 2: Clone dotfiles repository
clone_dotfiles() {
    info "Cloning dotfiles repository..."

    if [ -d "$DOTFILES_DIR" ]; then
        warn "Dotfiles directory already exists at $DOTFILES_DIR"
        read -p "Do you want to update it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Updating dotfiles repository..."
            git -C "$DOTFILES_DIR" pull
            success "Dotfiles updated"
        else
            info "Skipping repository clone"
        fi
    else
        mkdir -p "$(dirname "$DOTFILES_DIR")"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        success "Dotfiles cloned to $DOTFILES_DIR"
    fi
}

# Step 3: Install tuckr
install_tuckr() {
    info "Installing tuckr..."

    local platform version tuckr_url
    platform=$(detect_platform)

    if [ "$TUCKR_VERSION" = "latest" ]; then
        version=$(get_latest_tuckr_version)
        info "Latest tuckr version: $version"
    else
        version="$TUCKR_VERSION"
    fi

    tuckr_url="https://github.com/RaphGL/Tuckr/releases/download/${version}/tuckr-${platform}"

    # Create local bin directory
    mkdir -p "$LOCAL_BIN"

    # Download tuckr
    info "Downloading tuckr from $tuckr_url"
    if command_exists curl; then
        curl -fsSL "$tuckr_url" -o "${LOCAL_BIN}/tuckr"
    else
        wget -qO "${LOCAL_BIN}/tuckr" "$tuckr_url"
    fi

    # Make executable
    chmod +x "${LOCAL_BIN}/tuckr"

    # Verify installation
    if [ -x "${LOCAL_BIN}/tuckr" ]; then
        success "Tuckr installed to ${LOCAL_BIN}/tuckr"
        "${LOCAL_BIN}/tuckr" --version || true
    else
        error "Failed to install tuckr"
        exit 1
    fi
}

# Step 4: Deploy dotfiles with tuckr
deploy_dotfiles() {
    info "Deploying dotfiles with tuckr..."

    # Ensure tuckr is in PATH
    export PATH="${LOCAL_BIN}:${PATH}"

    if ! command_exists tuckr; then
        error "Tuckr not found in PATH"
        exit 1
    fi

    # Change to dotfiles directory
    cd "$DOTFILES_DIR"

    # Run tuckr set with force and yes flags
    info "Running: tuckr set -fy '*'"
    tuckr set -fy '*' || {
        error "Tuckr deployment failed"
        exit 1
    }

    success "Dotfiles deployed successfully"
}

# Step 5: Post-installation setup
post_install() {
    info "Post-installation setup..."

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":${LOCAL_BIN}:"* ]]; then
        warn "${LOCAL_BIN} is not in your PATH"
        info "Add this to your shell profile:"
        echo ""
        echo "    export PATH=\"${LOCAL_BIN}:\$PATH\""
        echo ""
    fi

    # Suggest shell change if not using zsh
    if [ "${SHELL##*/}" != "zsh" ]; then
        info "Current shell: $SHELL"
        if command_exists zsh; then
            warn "Consider changing your default shell to zsh:"
            echo ""
            echo "    chsh -s \$(which zsh)"
            echo ""
        else
            warn "Zsh not installed. Install it for the best experience."
        fi
    fi

    success "Installation complete!"
    echo ""
    info "Next steps:"
    echo "  1. Restart your shell or run: exec zsh"
    echo "  2. Review deployed configs in your home directory"
    echo "  3. Customize as needed with local overrides (~/.zshrc.local, etc.)"
    echo ""
}

# ==============================================================================
# Main Installation Flow
# ==============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            Dotfiles Bootstrap Installer                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_prerequisites
    clone_dotfiles
    install_tuckr
    deploy_dotfiles
    post_install

    echo ""
    success "🎉 Dotfiles installation completed successfully!"
    echo ""
}

# Run main function
main "$@"
