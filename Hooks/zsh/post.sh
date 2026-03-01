#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Apt Post Hook
# ==============================================================================

INSTALL_LIST="$HOME/.config/apt/install"
REMOVE_LIST="$HOME/.config/apt/remove"
APT_LOG_DIR="$HOME/.config/apt"
APT_LOG_FILE="$APT_LOG_DIR/hook-errors.log"

log_failure() {
	local message="$1"
	mkdir -p "$APT_LOG_DIR"
	printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$message" >> "$APT_LOG_FILE"
}

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
	log_failure "apt hook skipped: apt-get or dpkg-query not available"
	exit 0
fi

if [[ "${EUID}" -eq 0 ]]; then
	APT_PREFIX=()
elif command -v sudo >/dev/null 2>&1; then
	APT_PREFIX=(sudo)
else
	log_failure "apt hook skipped: not root and sudo unavailable"
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
		fi
	done < <(read_package_file "$file")

	(( ${#packages[@]} > 0 )) || return 0

	if ! "${APT_PREFIX[@]}" apt-get update -qq >/dev/null 2>&1; then
		log_failure "apt-get update failed before install from $file"
	fi

	if ! "${APT_PREFIX[@]}" apt-get install -y -qq "${packages[@]}" >/dev/null 2>&1; then
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
		fi
	done < <(read_package_file "$file")

	(( ${#packages[@]} > 0 )) || return 0

	if ! "${APT_PREFIX[@]}" apt-get remove -y -qq "${packages[@]}" >/dev/null 2>&1; then
		log_failure "apt-get remove failed for packages: ${packages[*]}"
	fi
}

install_packages_from_file "$INSTALL_LIST"
remove_packages_from_file "$REMOVE_LIST"



