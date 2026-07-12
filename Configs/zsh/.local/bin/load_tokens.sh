#!/usr/bin/zsh
# shellcheck shell=zsh

_LOAD_TOKENS_SOURCED=false
if [[ "$ZSH_EVAL_CONTEXT" == *file* ]]; then
  _LOAD_TOKENS_SOURCED=true
fi

usage() {
  cat <<'EOF'
Usage: load_tokens.sh [options]

Export KeePassXC secrets from a specified group as environment variables.

Options:
  -h, --help            Show this help message
  --debug               Print debugging information to stderr

Environment Variables:
  KEEPASS_DB_PATH       Path to the KeePassXC database (default: $HOME/sync/personal.kdbx)
  KEEPASS_KEY_PATH      Path to the database key file (default: $HOME/personal.keyx)
  KEEPASS_DB_PASSWD     KeePassXC database password (default: contents of $HOME/.db-password)
EOF
}

load_tokens() {
  local debug_enabled=false
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        return 0
        ;;
      --debug)
        debug_enabled=true
        ;;
      *)
        echo "Error: Unknown option: $arg" >&2
        usage >&2
        return 1
        ;;
    esac
  done

  debug() {
    if [[ "$debug_enabled" == "true" ]]; then
      echo "DEBUG: $1" >&2
    fi
  }

  local sourced=$_LOAD_TOKENS_SOURCED
  debug "Sourced mode: $sourced"

  # ================= Configuration =================
  local DB_PATH="${KEEPASS_DB_PATH:-"$HOME/sync/personal.kdbx"}"
  local KEY_FILE="${KEEPASS_KEY_PATH:-"$HOME/personal.keyx"}"
  local GROUP_NAME="Personal/Tokens"
  # =================================================

  local errors=0
  local DB_PASSWD=""

  debug "Checking paths and files..."
  # Check environment variables and file presence
  if [[ -z "${KEEPASS_DB_PATH:-}" ]]; then
    echo "Warning: KEEPASS_DB_PATH variable is not set. Defaulting to: $DB_PATH" >&2
  fi
  if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Database file does not exist: $DB_PATH" >&2
    errors=$((errors + 1))
  fi

  if [[ -z "${KEEPASS_KEY_PATH:-}" ]]; then
    echo "Warning: KEEPASS_KEY_PATH variable is not set. Defaulting to: $KEY_FILE" >&2
  fi
  if [[ ! -f "$KEY_FILE" ]]; then
    echo "Error: Key file does not exist: $KEY_FILE" >&2
    errors=$((errors + 1))
  fi

  if [[ -n "${KEEPASS_DB_PASSWD:-}" ]]; then
    DB_PASSWD="$KEEPASS_DB_PASSWD"
    debug "Password loaded from KEEPASS_DB_PASSWD variable (length: ${#DB_PASSWD})"
  else
    echo "Warning: KEEPASS_DB_PASSWD variable is not set. Defaulting to contents of: $HOME/.db-password" >&2
    if [[ -f "$HOME/.db-password" ]]; then
      DB_PASSWD="$(cat "$HOME/.db-password")"
      debug "Password loaded from $HOME/.db-password (length: ${#DB_PASSWD})"
    else
      echo "Error: Password file does not exist: $HOME/.db-password" >&2
      errors=$((errors + 1))
    fi
  fi

  if [[ ! -x "/usr/bin/keepassxc-cli" ]]; then
    echo "Error: /usr/bin/keepassxc-cli is not executable or not found" >&2
    errors=$((errors + 1))
  fi

  if [[ $errors -gt 0 ]]; then
    debug "Validation failed with $errors error(s)"
    return 1
  fi

  debug "Running keepassxc-cli..."
  # Run keepassxc-cli with password input
  local csv_data
  if [[ "$debug_enabled" == "true" ]]; then
    debug "Command: /usr/bin/keepassxc-cli export -q -k \"$KEY_FILE\" \"$DB_PATH\" -f csv"
    csv_data=$(printf "%s\n" "$DB_PASSWD" | /usr/bin/keepassxc-cli export -q -k "$KEY_FILE" "$DB_PATH" -f csv)
  else
    csv_data=$(printf "%s\n" "$DB_PASSWD" | /usr/bin/keepassxc-cli export -q -k "$KEY_FILE" "$DB_PATH" -f csv 2>/dev/null)
  fi

  if [[ -n "$csv_data" ]]; then
    debug "keepassxc-cli exported successfully"
    # Split CSV into rows, skipping the header line
    local -a rows
    rows=(${(f)csv_data})
    shift rows

    debug "Processing $(( ${#rows} )) CSV rows..."
    local row group title password env_name
    for row in $rows; do

      # Parse CSV columns safely ignoring surrounding quotes
      # Uses Zsh (s) parameter expansion to split by comma
      local -a fields
      fields=(${(s:,:)row})

      # Strip outer quotes from fields: :s/\"// deletes quotes
      group="${fields[1]//\"/}"
      title="${fields[2]//\"/}"
      password="${fields[4]//\"/}"

      # Only process entries matching your targeted group
      if [[ "$group" == "$GROUP_NAME" ]]; then
        # 1. Convert to UPPERCASE using Zsh built-in :u modifier
        env_name="${title:u}"

        # 2. Replace all non-alphanumeric characters with underscores
        env_name="${env_name//[^A-Z0-9]/_}"

        # 3. Export to the current environment
        export "$env_name"="$password"
        if [[ "$sourced" == "false" ]]; then
          echo "export $env_name=${(q)password}"
        else
          debug "Exported $env_name"
        fi
      fi
    done
  else
    debug "No CSV data retrieved or keepassxc-cli failed"
  fi
}
load_tokens "$@"
