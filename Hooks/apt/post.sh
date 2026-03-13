#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Apt Post Hook
# ==============================================================================

INSTALL_LIST="$HOME/.config/apt/install"
REMOVE_LIST="$HOME/.config/apt/remove"
APT_LOG_DIR="$HOME/.config/apt"
APT_LOG_FILE="$APT_LOG_DIR/hook-errors.log"

DRY_RUN=0
DEBUG=0
USE_SPINNER=1

usage() {
	cat <<'EOF'
Usage: post.sh [--dry-run|-n] [--debug|-d] [--no-spinner] [--help|-h]

Options:
  -n, --dry-run    Show what would run, but do not execute apt commands
  -d, --debug      Verbose output; show commands and apt output
      --no-spinner Disable spinner/progress animation
  -h, --help       Show this help
EOF
}

for arg in "$@"; do
	case "$arg" in
		-n|--dry-run)
			DRY_RUN=1
			;;
		-d|--debug)
			DEBUG=1
			;;
		--no-spinner)
			USE_SPINNER=0
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown argument: $arg" >&2
			usage >&2
			exit 2
			;;
	esac
done

if [[ ! -t 1 ]]; then
	USE_SPINNER=0
fi

if (( DEBUG )); then
	USE_SPINNER=0
fi

info() {
	printf '%s\n' "$*"
}

debug() {
	if (( DEBUG )); then
		printf '[debug] %s\n' "$*"
	fi
}

log_failure() {
	local message="$1"
	mkdir -p "$APT_LOG_DIR"
	printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$message" >> "$APT_LOG_FILE"
	if (( DEBUG )); then
		printf '[error] %s\n' "$message" >&2
	fi
}

run_apt() {
	local label="$1"
	shift

	if (( DRY_RUN )); then
		info "[dry-run] $label"
		info "          $*"
		return 0
	fi

	if (( DEBUG )); then
		info "[run] $label"
		debug "cmd: $*"
		"$@"
		return $?
	fi

	if (( USE_SPINNER )); then
		local spinner='|/-\\'
		local idx=0
		local pid
		local status=0

		printf '→ %s ' "$label"
		"$@" >/dev/null 2>&1 &
		pid=$!

		while kill -0 "$pid" 2>/dev/null; do
			printf '\r→ %s [%c]' "$label" "${spinner:idx++%4:1}"
			sleep 0.15
		done

		if ! wait "$pid"; then
			status=$?
		fi

		if (( status == 0 )); then
			printf '\r✓ %s\n' "$label"
		else
			printf '\r✗ %s\n' "$label"
		fi

		return $status
	fi

	printf '→ %s\n' "$label"
	if "$@" >/dev/null 2>&1; then
		printf '✓ %s\n' "$label"
		return 0
	fi
	printf '✗ %s\n' "$label"
	return 1
}

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
	log_failure "apt hook skipped: apt-get or dpkg-query not available"
	debug "skip reason: apt-get or dpkg-query not available"
	exit 0
fi

if [[ "${EUID}" -eq 0 ]]; then
	APT_PREFIX=()
elif command -v sudo >/dev/null 2>&1; then
	APT_PREFIX=(sudo)
else
	log_failure "apt hook skipped: not root and sudo unavailable"
	debug "skip reason: not root and sudo unavailable"
	exit 0
fi

read_package_file() {
	local file="$1"
	grep -Ev '^\s*($|#)' "$file" 2>/dev/null || true
}

package_available() {
	local package="$1"
	apt-cache show "$package" >/dev/null 2>&1
}

package_installed() {
	local package="$1"
	dpkg-query -W -f='${Status}\n' "$package" 2>/dev/null | grep -q '^install ok installed$'
}

install_packages_from_file() {
	local file="$1"
	local package
	local packages=()

	[[ -f "$file" ]] || return 0

	while IFS= read -r package; do
		[[ -z "$package" ]] && continue
		if package_available "$package"; then
			packages+=("$package")
		else
			log_failure "package unavailable for install: $package"
			debug "unavailable package (install): $package"
		fi
	done < <(read_package_file "$file")

	if (( ${#packages[@]} == 0 )); then
		info "No installable packages found in $file"
		return 0
	fi

	info "Install queue (${#packages[@]}): ${packages[*]}"

	if ! run_apt "apt-get update" "${APT_PREFIX[@]}" DEBIAN_FRONTEND=noninteractive apt-get update -qq -o Dpkg::Progress-Fancy=0; then
		log_failure "apt-get update failed before install from $file"
	fi

	if ! run_apt "apt-get install (${#packages[@]} packages)" "${APT_PREFIX[@]}" DEBIAN_FRONTEND=noninteractive apt-get install -y -qq -o Dpkg::Progress-Fancy=0 --no-install-recommends "${packages[@]}"; then
		log_failure "apt-get install failed for packages: ${packages[*]}"
	fi
}

remove_packages_from_file() {
	local file="$1"
	local package
	local packages=()

	[[ -f "$file" ]] || return 0

	while IFS= read -r package; do
		[[ -z "$package" ]] && continue
		if package_installed "$package"; then
			packages+=("$package")
		else
			debug "not installed, skipping remove: $package"
		fi
	done < <(read_package_file "$file")

	if (( ${#packages[@]} == 0 )); then
		info "No removable packages found in $file"
		return 0
	fi

	info "Remove queue (${#packages[@]}): ${packages[*]}"

	if ! run_apt "apt-get remove (${#packages[@]} packages)" "${APT_PREFIX[@]}" DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq -o Dpkg::Progress-Fancy=0 "${packages[@]}"; then
		log_failure "apt-get remove failed for packages: ${packages[*]}"
	fi
}

info "Running apt post hook"
if (( DRY_RUN )); then
	info "Dry-run mode enabled"
fi
if (( DEBUG )); then
	info "Debug mode enabled"
fi

install_packages_from_file "$INSTALL_LIST"
remove_packages_from_file "$REMOVE_LIST"

info "Apt post hook complete"
