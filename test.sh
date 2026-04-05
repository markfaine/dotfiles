#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

# ==============================================================================
# Dotfiles Test Script
# ==============================================================================
# Tests dotfiles installation in a Docker container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="dotfiles_test"
IMAGE_NAME="localhost/ubuntu-test:latest"

DRY_RUN=0
DEBUG=0
NO_CLEANUP=0
KEEP_CONTAINER=0
RUN_ZSH_BENCH=0
USERNAME="${USER}"
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"
DOTFILES_BRANCH=""

# ==============================================================================
# Help Message
# ==============================================================================

usage() {
	cat <<'EOF'
Usage: test.sh [OPTIONS] [USERNAME]

Tests dotfiles installation in a Docker container.

Options:
  -n, --dry-run       Show what would run, but don't execute
  -d, --debug         Verbose output; show all commands
      --no-cleanup    Skip docker system prune before building
      --keep          Keep container running after test (for inspection)
	  --zsh-bench     Clone romkatv/zsh-bench and run benchmark in container
  -b, --branch BRANCH Specify git branch to clone (default: repo default)
  -h, --help          Show this help message

Arguments:
  USERNAME            Username to create in container (default: $USER)

Examples:
  ./test.sh                       # Test with current user
  ./test.sh testuser              # Test with specific username
  ./test.sh --debug               # Test with verbose output
  ./test.sh --keep testuser       # Test and keep container running
  ./test.sh --branch development  # Test with development branch
	./test.sh --zsh-bench           # Run zsh benchmark after install
EOF
}

# ==============================================================================
# Parse Arguments
# ==============================================================================

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-n|--dry-run)
				DRY_RUN=1
				shift
				;;
			-d|--debug)
				DEBUG=1
				shift
				;;
			--no-cleanup)
				NO_CLEANUP=1
				shift
				;;
			--keep)
				KEEP_CONTAINER=1
				shift
				;;
			--zsh-bench)
				RUN_ZSH_BENCH=1
				shift
				;;
			-b|--branch)
				if [[ -z "${2:-}" ]]; then
					echo "Error: --branch requires a branch name" >&2
					exit 2
				fi
				DOTFILES_BRANCH="$2"
				shift 2
				;;
			-h|--help)
				usage
				exit 0
				;;
			-*)
				echo "Unknown option: $1" >&2
				usage >&2
				exit 2
				;;
			*)
				USERNAME="$1"
				shift
				;;
		esac
	done
}

# ==============================================================================
# Logging Functions
# ==============================================================================

info() {
	echo "→ $*"
}

success() {
	echo "✓ $*"
}

error() {
	echo "✗ $*" >&2
}

debug_msg() {
	if (( DEBUG )); then
		echo "DEBUG: $*" >&2
	fi
}

# ==============================================================================
# Main Functions
# ==============================================================================

check_prerequisites() {
	info "Checking prerequisites..."

	if ! command -v docker &>/dev/null; then
		error "Docker not found. Please install Docker first."
		exit 1
	fi

	if ! docker info &>/dev/null; then
		error "Docker daemon not running or insufficient permissions."
		error "Try: sudo usermod -aG docker $USER && newgrp docker"
		exit 1
	fi

	if [[ ! -f "$SCRIPT_DIR/install.sh" ]]; then
		error "install.sh not found in $SCRIPT_DIR"
		exit 1
	fi

	if [[ ! -f "$SCRIPT_DIR/Dockerfile" ]]; then
		error "Dockerfile not found in $SCRIPT_DIR"
		exit 1
	fi

	success "Prerequisites check passed"
}

cleanup_docker() {
	if (( NO_CLEANUP )); then
		info "Skipping docker cleanup (--no-cleanup specified)"
		return 0
	fi

	info "Cleaning up Docker images and containers..."

	if (( DRY_RUN )); then
		echo "[DRY-RUN] Would run: docker system prune -af"
		return 0
	fi

	if (( DEBUG )); then
		docker system prune -af
	else
		docker system prune -af &>/dev/null
	fi

	success "Docker cleanup complete"
}

build_image() {
	info "Building Docker image: $IMAGE_NAME"
	debug_msg "Build args: USERNAME=$USERNAME UID=$USER_ID GID=$GROUP_ID"

	if (( DRY_RUN )); then
		echo "[DRY-RUN] Would run: docker build . -t $IMAGE_NAME --build-arg=USERNAME=$USERNAME --build-arg=UID=$USER_ID --build-arg=GID=$GROUP_ID"
		return 0
	fi

	local build_cmd=(docker build . -t "$IMAGE_NAME" --build-arg="USERNAME=$USERNAME" --build-arg="UID=$USER_ID" --build-arg="GID=$GROUP_ID")

	if (( DEBUG )); then
		"${build_cmd[@]}"
	else
		"${build_cmd[@]}" 2>&1 | grep -E '(Step|Successfully|ERROR)' || true
	fi

	success "Docker image built: $IMAGE_NAME"
}

start_container() {
	info "Starting container: $CONTAINER_NAME"
	debug_msg "Mount: $SCRIPT_DIR/install.sh -> /home/$USERNAME/install.sh"

	# Stop any existing container with the same name
	if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
		debug_msg "Removing existing container: $CONTAINER_NAME"
		docker rm -f "$CONTAINER_NAME" &>/dev/null || true
	fi

	if (( DRY_RUN )); then
		echo "[DRY-RUN] Would run: docker run -d --rm -it --name $CONTAINER_NAME ..."
		return 0
	fi

	local run_flags=(-d -it --name "$CONTAINER_NAME")

	# Only add --rm if not keeping container
	if (( !KEEP_CONTAINER )); then
		run_flags+=(--rm)
	fi

	run_flags+=(
		-v "$SCRIPT_DIR/install.sh:/home/$USERNAME/install.sh:ro"
    -v "/home/$USERNAME/.ssh:/home/$USERNAME/.ssh"
		"$IMAGE_NAME"
		sleep infinity
	)

	docker run "${run_flags[@]}" &>/dev/null

	# Wait for container to be ready
	sleep 2

	success "Container started: $CONTAINER_NAME"
}

run_tests() {
	info "Running installation test in container..."

	local exec_cmd=(docker exec -it)

	# Pass DEBUG flag to install.sh if enabled
	if (( DEBUG )); then
		exec_cmd+=(-e DEBUG=1)
	fi

	# Pass branch to install.sh if specified
	if [[ -n "$DOTFILES_BRANCH" ]]; then
		exec_cmd+=(-e DOTFILES_BRANCH="$DOTFILES_BRANCH")
	fi

	exec_cmd+=("$CONTAINER_NAME" bash "/home/$USERNAME/install.sh")

	if (( DRY_RUN )); then
		echo "[DRY-RUN] Would run: ${exec_cmd[*]}"
		return 0
	fi

	debug_msg "Executing: ${exec_cmd[*]}"

	if "${exec_cmd[@]}"; then
		success "Installation test completed successfully"

		if (( RUN_ZSH_BENCH )); then
			info "Running zsh-bench in container..."
			local bench_cmd=(
				docker exec -it "$CONTAINER_NAME" bash -lc
				'mkdir -p "$HOME/.cache" &&
				 if [[ -d "$HOME/.cache/zsh-bench/.git" ]]; then
				   git -C "$HOME/.cache/zsh-bench" pull --ff-only;
				 else
				   git clone --depth 1 https://github.com/romkatv/zsh-bench.git "$HOME/.cache/zsh-bench";
				 fi &&
				 cd "$HOME/.cache/zsh-bench" && ./zsh-bench'
			)

			if (( DRY_RUN )); then
				echo "[DRY-RUN] Would run: ${bench_cmd[*]}"
			else
				debug_msg "Executing: ${bench_cmd[*]}"
				"${bench_cmd[@]}"
			fi
		fi

		return 0
	else
		error "Installation test failed"
		return 1
	fi
}

cleanup_container() {
	if (( KEEP_CONTAINER )); then
		echo ""
		info "Container kept running: $CONTAINER_NAME"
		info "Inspect with: docker exec -it $CONTAINER_NAME bash"
		info "Stop with:    docker stop $CONTAINER_NAME"
		return 0
	fi

	if (( DRY_RUN )); then
		echo "[DRY-RUN] Would stop container: $CONTAINER_NAME"
		return 0
	fi

	if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
		debug_msg "Stopping container: $CONTAINER_NAME"
		docker stop "$CONTAINER_NAME" &>/dev/null || true
	fi
}

# ==============================================================================
# Main Script
# ==============================================================================

main() {
	parse_args "$@"

	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "Dotfiles Installation Test"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "Username:  $USERNAME"
	echo "Image:     $IMAGE_NAME"
	echo "Container: $CONTAINER_NAME"
	if [[ -n "$DOTFILES_BRANCH" ]]; then
		echo "Branch:    $DOTFILES_BRANCH"
	fi
	if (( DRY_RUN )); then
		echo "Mode:      DRY-RUN"
	fi
	if (( DEBUG )); then
		echo "Debug:     ENABLED"
	fi
	if (( KEEP_CONTAINER )); then
		echo "Keep:      YES"
	fi
	if (( RUN_ZSH_BENCH )); then
		echo "Zsh bench: YES"
	fi
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""

  info "Changing permissions on scripts..."
  find . -type f -name '*.sh' -exec chmod +x "{}" \;
  info "Changing permissions on scripts complete."

	check_prerequisites
	cleanup_docker
	build_image
	start_container

	# Run tests and capture result
	test_result=0
	run_tests || test_result=$?

	# Cleanup unless keeping container
	if (( test_result == 0 )); then
		cleanup_container
	else
		if (( !KEEP_CONTAINER )); then
			error "Test failed. Container logs:"
			docker logs "$CONTAINER_NAME" 2>&1 | tail -20 || true
		fi
		cleanup_container
	fi

	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	if (( test_result == 0 )); then
		echo "✓ Test completed successfully"
	else
		echo "✗ Test failed"
	fi
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""

	exit $test_result
}

# Trap for cleanup on exit
trap cleanup_container EXIT INT TERM

main "$@"
