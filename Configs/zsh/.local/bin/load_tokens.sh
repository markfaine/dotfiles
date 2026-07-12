#!/usr/bin/zsh
# shellcheck shell=zsh
load_tokens() {
  # ================= Configuration =================
  local DB_PATH="$HOME/personal.kdbx"
  local KEY_FILE="${2:-"$HOME/personal.keyx"}"
  local DB_PASSWD="$HOME/.db-password"
  local GROUP_NAME="Personal/Tokens"
  # =================================================

  # Ensure the database and key file exist
  if [[ -f "$DB_PATH" && -f "$KEY_FILE" && -f "$DB_PASSWD" ]]; then
    # Run keepassxc-cli with an empty string as password input
    local csv_data
    csv_data=$(cat "$DB_PASSWD" | /usr/bin/keepassxc-cli export -q -k "$KEY_FILE" "$DB_PATH" -f csv) #2>/dev/null)
    # printf "csv_data: %s\n" "$csv_data"
    if [[ -n "$csv_data" ]]; then
      # Split CSV into rows, skipping the header line
      local -a rows
      rows=(${(f)csv_data})
      shift rows

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
        fi
      done
    fi
  fi
}
load_tokens
