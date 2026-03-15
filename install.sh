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

# Enable debug mode if DEBUG=1 is set
if [ "${DEBUG:-0}" = "1" ]; then
    set -x
fi

# ==============================================================================
# Configuration
# ==============================================================================
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/markfaine/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-}"  # Empty means use repo default branch
DOTFILES_DIR="${ZDOTDIR:-$HOME}/.config/dotfiles"
TUCKR_VERSION="${TUCKR_VERSION:-latest}"
LOCAL_BIN="${ZDOTDIR:-$HOME}/.local/bin"

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

debug_msg() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

usage() {
    cat <<'EOF'
Usage: install.sh [OPTIONS]

Bootstrap dotfiles.

Options:
  -b, --branch BRANCH   Clone and deploy a specific dotfiles branch
  -h, --help            Show this help
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -b|--branch)
                if [ -z "${2:-}" ]; then
                    error "--branch requires a branch name"
                    exit 2
                fi
                DOTFILES_BRANCH="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage >&2
                exit 2
                ;;
        esac
    done
}

# Ensure hook scripts are executable so tuckr can run them.
ensure_hook_scripts_executable() {
    local base_dir="$1"
    local fixed_count=0

    if [ ! -d "$base_dir/Hooks" ]; then
        debug_msg "No Hooks directory found at $base_dir/Hooks"
        return 0
    fi

    while IFS= read -r -d '' script_path; do
        if [ ! -x "$script_path" ]; then
            chmod +x "$script_path"
            fixed_count=$((fixed_count + 1))
            debug_msg "Set executable bit: $script_path"
        fi
    done < <(find "$base_dir/Hooks" -type f -name '*.sh' -print0)

    if [ "$fixed_count" -gt 0 ]; then
        info "Fixed executable permissions on $fixed_count hook script(s)"
    else
        debug_msg "All hook scripts already executable"
    fi
}

# Configure repository-local git hooks.
configure_git_hooks() {
    local repo_dir="$1"

    if [ ! -d "$repo_dir/.git" ]; then
        debug_msg "Skipping git hook setup: $repo_dir is not a git repository"
        return 0
    fi

    if [ -d "$repo_dir/.githooks" ]; then
        git -C "$repo_dir" config core.hooksPath .githooks
        debug_msg "Configured core.hooksPath=.githooks"
    else
        debug_msg "No .githooks directory found; skipping core.hooksPath setup"
    fi
}

# Detect OS and architecture
detect_platform() {
    local os arch

    debug_msg "Detecting platform..."
    debug_msg "uname -s: $(uname -s)"
    debug_msg "uname -m: $(uname -m)"

    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux";;
        Darwin*)    os="darwin";;
        *)          error "Unsupported OS: $(uname -s)"; exit 1;;
    esac
    debug_msg "Detected OS: $os"

    # Detect architecture
    case "$(uname -m)" in
        x86_64)     arch="x86_64";;
        aarch64)    arch="aarch64";;
        arm64)      arch="aarch64";;
        *)          error "Unsupported architecture: $(uname -m)"; exit 1;;
    esac
    debug_msg "Detected architecture: $arch"
    debug_msg "Platform: ${arch}-${os}"

    echo "${arch}-${os}"
}

# Resolve tuckr download URL from release assets by exact asset name.
# Args:
#   $1 = platform (e.g. x86_64-linux)
#   $2 = version tag or "latest"
get_tuckr_asset_url() {
    local platform="$1"
    local requested_version="$2"
    local api_url=""
    local release_json=""
    local asset_name="tuckr-${platform}"
    local tuckr_url=""

    if [ "$requested_version" = "latest" ]; then
        api_url="https://api.github.com/repos/RaphGL/Tuckr/releases/latest"
        debug_msg "Fetching latest release metadata"
    else
        api_url="https://api.github.com/repos/RaphGL/Tuckr/releases/tags/${requested_version}"
        debug_msg "Fetching release metadata for tag: $requested_version"
    fi

    if command_exists curl; then
        release_json=$(curl -fsSL -H "User-Agent: dotfiles-installer" "$api_url")
    elif command_exists wget; then
        release_json=$(wget -qO- --header="User-Agent: dotfiles-installer" "$api_url")
    else
        error "Neither curl nor wget found. Cannot fetch release metadata."
        exit 1
    fi

    tuckr_url=$(printf '%s' "$release_json" | tr -d '\n' | awk -v asset_name="\"name\":\"${asset_name}\"" '
        {
            pos = index($0, asset_name)
            if (pos > 0) {
                s = substr($0, pos)
                if (match(s, /"browser_download_url":"[^"]+"/)) {
                    url = substr(s, RSTART, RLENGTH)
                    sub(/^"browser_download_url":"/, "", url)
                    sub(/"$/, "", url)
                    print url
                }
            }
        }
    ')

    if [ -z "$tuckr_url" ]; then
        error "Failed to find asset '$asset_name' in Tuckr release metadata"
        exit 1
    fi

    debug_msg "Resolved asset URL: $tuckr_url"
    echo "$tuckr_url"
}

# ==============================================================================
# Installation Steps
# ==============================================================================

# Step 1: Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    local missing=()

    debug_msg "Ensuring scripts are executable"

    debug_msg "Checking for git..."
    # Essential tools
    if ! command_exists git; then
        missing+=("git")
        debug_msg "git not found"
    else
        debug_msg "git found: $(command -v git)"
    fi

    debug_msg "Checking for curl or wget..."
    if ! command_exists curl && ! command_exists wget; then
        missing+=("curl or wget")
        debug_msg "Neither curl nor wget found"
    else
        if command_exists curl; then
            debug_msg "curl found: $(command -v curl)"
        fi
        if command_exists wget; then
            debug_msg "wget found: $(command -v wget)"
        fi
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

    debug_msg "Repository: $DOTFILES_REPO"
    debug_msg "Branch: ${DOTFILES_BRANCH:-default}"
    debug_msg "Target directory: $DOTFILES_DIR"

    if [ -d "$DOTFILES_DIR" ]; then
        warn "Dotfiles directory already exists at $DOTFILES_DIR"
        debug_msg "Directory contents: $(find "$DOTFILES_DIR" -mindepth 1 -maxdetph 1 2>/dev/null | wc -l) items"

        read -p "Do you want to update it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Updating dotfiles repository..."
            debug_msg "Running: git -C $DOTFILES_DIR pull"
            git -C "$DOTFILES_DIR" pull
            success "Dotfiles updated"
        else
            info "Skipping repository clone"
        fi
    else
        debug_msg "Creating parent directory: $(dirname "$DOTFILES_DIR")"
        mkdir -p "$(dirname "$DOTFILES_DIR")"

        debug_msg "Cloning from: $DOTFILES_REPO"
        if [ -n "$DOTFILES_BRANCH" ]; then
            debug_msg "Using branch: $DOTFILES_BRANCH"
            git clone -b "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
        else
            debug_msg "Using default branch"
            git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        fi
        success "Dotfiles cloned to $DOTFILES_DIR"
    fi
}

# Step 3: Install tuckr
install_tuckr() {
    info "Installing tuckr..."

    local platform requested_version tuckr_url
    platform=$(detect_platform)
    debug_msg "Platform: $platform"

    requested_version="$TUCKR_VERSION"
    if [ "$requested_version" = "latest" ]; then
        info "Resolving latest tuckr asset for $platform"
    else
        info "Resolving tuckr asset for version: $requested_version"
    fi

    tuckr_url=$(get_tuckr_asset_url "$platform" "$requested_version")
    debug_msg "Download URL: $tuckr_url"

    # Create local bin directory
    debug_msg "Creating directory: $LOCAL_BIN"
    mkdir -p "$LOCAL_BIN"

    # Download tuckr
    info "Downloading tuckr from $tuckr_url"
    if command_exists curl; then
        debug_msg "Downloading with curl"
        curl -fsSL -H "User-Agent: dotfiles-installer" "$tuckr_url" -o "${LOCAL_BIN}/tuckr"
    else
        debug_msg "Downloading with wget"
        wget -qO "${LOCAL_BIN}/tuckr" --header="User-Agent: dotfiles-installer" "$tuckr_url"
    fi

    # Make executable
    debug_msg "Setting executable permissions on ${LOCAL_BIN}/tuckr"
    chmod +x "${LOCAL_BIN}/tuckr"

    # Verify installation
    debug_msg "Verifying tuckr installation"
    if [ -x "${LOCAL_BIN}/tuckr" ]; then
        success "Tuckr installed to ${LOCAL_BIN}/tuckr"
        "${LOCAL_BIN}/tuckr" --version || true
    else
        error "Failed to install tuckr"
        exit 1
    fi
}

# Ensure common XDG directories exist before tuckr creates symlinks
ensure_xdg_directories() {
    debug_msg "Creating XDG base directories"

    local xdg_dirs=(
        "${XDG_CONFIG_HOME:-$HOME/.config}"
        "${XDG_DATA_HOME:-$HOME/.local/share}"
        "${XDG_STATE_HOME:-$HOME/.local/state}"
        "${XDG_CACHE_HOME:-$HOME/.cache}"
        "$LOCAL_BIN"
    )

    for dir in "${xdg_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            debug_msg "Creating: $dir"
            mkdir -p "$dir"
        fi
    done
}

# Step 4: Deploy dotfiles with tuckr
deploy_dotfiles() {
    info "Deploying dotfiles with tuckr..."

    # Ensure tuckr is in PATH
    debug_msg "Adding ${LOCAL_BIN} to PATH"
    export PATH="${LOCAL_BIN}:${PATH}"
    debug_msg "Current PATH: $PATH"

    if ! command_exists tuckr; then
        error "Tuckr not found in PATH"
        debug_msg "tuckr location: $(which tuckr 2>&1 || echo 'not found')"
        exit 1
    fi
    debug_msg "tuckr found: $(which tuckr)"

    # Create XDG directories before symlink operations
    ensure_xdg_directories

    # Ensure hook scripts are executable before running tuckr hooks.
    ensure_hook_scripts_executable "$DOTFILES_DIR"

    # Discover all dotfile groups by basename and sort in natural version order.
    # This supports ordered prefixes like apt, fonts, ... and avoids
    # mixing full paths with group names.

    info "Deploying dotfiles with tuckr set..."

    debug_msg "Running: tuckr set for non-dependent configs"
    if ! tuckr set -fy \* -e mise,pass,nvim,wsl,zsh  ; then
        error "Tuckr non-dependent config deployment failed"
        exit 1
    fi

    debug_msg "Running: tuckr set mise"
    if ! tuckr set -fy mise; then
        error "Tuckr mise config deployment failed"
        exit 1
    fi

    debug_msg "Running: tuckr set pass"
    if ! tuckr set -fy pass; then
        warn "Tuckr pass config deployment failed"
    fi

    debug_msg "Running: tuckr set nvim"
    if ! tuckr set -fy nvim; then
        warn "Tuckr nvim config deployment failed"
    fi

    debug_msg "Running: tuckr set wsl"
    if ! tuckr set -fy wsl; then
        warn "Tuckr wsl config deployment failed"
    fi

    debug_msg "Running: tuckr set zsh"
    if ! tuckr set -fy zsh; then
        error "Tuckr zsh config deployment failed"
        exit 1
    fi

    success "Dotfiles deployed successfully"
}

# Step 5: Post-installation setup
post_install() {
    info "Post-installation setup..."

    debug_msg "Checking PATH for ${LOCAL_BIN}"
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":${LOCAL_BIN}:"* ]]; then
        warn "${LOCAL_BIN} is not in your PATH"
        info "Add this to your shell profile:"
        echo ""
        echo "    export PATH=\"${LOCAL_BIN}:\$PATH\""
        echo ""
    else
        debug_msg "${LOCAL_BIN} is already in PATH"
    fi

    debug_msg "Current shell: $SHELL"
    # Suggest shell change if not using zsh
    if [ "${SHELL##*/}" != "zsh" ]; then
        info "Current shell: $SHELL"
        if command_exists zsh; then
            debug_msg "zsh found: $(which zsh)"
            warn "Consider changing your default shell to zsh:"
            echo ""
            echo "    chsh -s \$(which zsh)"
            echo ""
        else
            warn "Zsh not installed. "
        fi
    else
        debug_msg "Already using zsh"
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
    parse_args "$@"

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            Dotfiles Bootstrap Installer                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    if [ "${DEBUG:-0}" = "1" ]; then
        debug_msg "DEBUG mode enabled"
        debug_msg "Repository: $DOTFILES_REPO"
        debug_msg "Branch: ${DOTFILES_BRANCH:-default}"
        debug_msg "Install directory: $DOTFILES_DIR"
        debug_msg "Tuckr version: $TUCKR_VERSION"
        debug_msg "Local bin: $LOCAL_BIN"
    fi

    check_prerequisites
    clone_dotfiles
    configure_git_hooks "$DOTFILES_DIR"
    install_tuckr
    ensure_xdg_directories
    ensure_hook_scripts_executable "$DOTFILES_DIR"
    #deploy_dotfiles
    post_install

    echo ""
    success "🎉 Dotfiles installation completed successfully!"
    echo ""
}

# Run main function
main "$@"
