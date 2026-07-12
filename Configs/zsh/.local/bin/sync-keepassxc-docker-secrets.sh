#!/usr/bin/env bash
#set -Eeuo pipefail
IFS=$'\n\t'

#KEEPASS_DB_PATH="$HOME/sync/personal.kdbx"
#KEEPASS_KEY_PATH="$HOME/sync/personal.keyx"
#KEEPASS_DB_PASSWD="$(cat "$HOME/sync/.db-password" )"
#export KEEPASS_DB_PATH KEEPASS_KEY_PATH KEEPASS_DB_PASSWD

progname=$(basename "$0")
current_step="starting"
temp_dir=""

usage() {
  cat <<EOF
Usage: $progname --database PATH [options]

Create Docker secrets from KeePassXC entries in a group.

By default, the script reads entries from system/docker-secrets.
For each entry, it uses the entry title as the Docker secret name.
If the entry has an attachment, the first attachment is used as the secret
content. Otherwise, the entry password field is used.

Options:
  -d, --database PATH      KeePassXC database path
  -g, --group PATH         Group path to sync (default: system/docker-secrets)
  -k, --key-file PATH      KeePassXC key file
      --no-password        Database does not require a password
  -y, --yubikey SLOT       YubiKey slot[:serial] for KeePassXC
  -f, --force              Replace existing Docker secrets
      --debug              Print progress and failure context
      --keep-temp          Keep temporary export files for debugging
  -h, --help               Show this help

Environment:
  KEEPASS_DB_PASSWD       Database password, if omitted the script prompts once

Notes:
  - Existing secrets are skipped unless --force is passed.
  - Entries with more than one attachment are treated as errors.
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "DEBUG: $*" >&2
  fi
}

cleanup() {
  if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
    if [[ "$KEEP_TEMP" == "true" ]]; then
      debug "keeping temporary files in $temp_dir"
    else
      rm -rf "$temp_dir"
    fi
  fi
}

on_error() {
  local line_number="$2"
  local command="$3"

  if [[ "$DEBUG" == "true" ]]; then
    echo "DEBUG: failure during '$current_step' at line $line_number: $command" >&2
    if [[ -n "$temp_dir" ]]; then
      echo "DEBUG: temporary directory: $temp_dir" >&2
    fi
  else
    echo "ERROR: $progname failed during $current_step" >&2
  fi
}

trap 'on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
trap cleanup EXIT

require_tools() {
  command -v keepassxc-cli >/dev/null 2>&1 || die "keepassxc-cli is required."
  command -v docker >/dev/null 2>&1 || die "docker is required."
  command -v getopt >/dev/null 2>&1 || die "getopt is required."
  command -v python3 >/dev/null 2>&1 || die "python3 is required."
}

require_swarm() {
  local swarm_state

  if ! swarm_state=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null); then
    die "Unable to query Docker Swarm status."
  fi

  [[ "$swarm_state" == "active" ]] || die "Docker Swarm must be active to manage Docker secrets."
}

run_keepassxc() {
  local subcommand="$1"
  shift
  local cli_args=("$subcommand")

  if [[ "$DEBUG" != "true" ]]; then
    cli_args+=(-q)
  fi

  cli_args+=("${KEEPASSXC_AUTH_ARGS[@]}")
  cli_args+=("$@")

  if [[ "$USE_DATABASE_PASSWORD" == "true" ]]; then
    printf '%s\n' "$DATABASE_PASSWORD" | keepassxc-cli "${cli_args[@]}"
  else
    keepassxc-cli "${cli_args[@]}"
  fi
}

secret_exists() {
  local secret_name="$1"
  docker secret inspect "$secret_name" >/dev/null 2>&1
}

create_secret_from_file() {
  local secret_name="$1"
  local payload_path="$2"

  docker secret create "$secret_name" "$payload_path" >/dev/null
}

extract_entries_via_open_session() {
  local payload_dir="$1"
  local metadata_path="$2"

  KEEPASSXC_SCRIPT_DATABASE="$DATABASE" \
    KEEPASSXC_SCRIPT_GROUP="$GROUP_PATH" \
    KEEPASSXC_SCRIPT_PAYLOAD_DIR="$payload_dir" \
    KEEPASSXC_SCRIPT_METADATA="$metadata_path" \
    KEEPASSXC_SCRIPT_PASSWORD="$DATABASE_PASSWORD" \
    KEEPASSXC_SCRIPT_USE_PASSWORD="$USE_DATABASE_PASSWORD" \
    KEEPASSXC_SCRIPT_DEBUG="$DEBUG" \
    python3 - "${KEEPASSXC_AUTH_ARGS[@]}" <<'PY'
import os
import pty
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path


DATABASE = os.environ["KEEPASSXC_SCRIPT_DATABASE"]
GROUP_PATH = os.environ["KEEPASSXC_SCRIPT_GROUP"]
PAYLOAD_DIR = Path(os.environ["KEEPASSXC_SCRIPT_PAYLOAD_DIR"])
METADATA_PATH = Path(os.environ["KEEPASSXC_SCRIPT_METADATA"])
DATABASE_PASSWORD = os.environ.get("KEEPASSXC_SCRIPT_PASSWORD", "")
USE_PASSWORD = os.environ.get("KEEPASSXC_SCRIPT_USE_PASSWORD") == "true"
DEBUG = os.environ.get("KEEPASSXC_SCRIPT_DEBUG") == "true"
AUTH_ARGS = sys.argv[1:]
PROMPT = f"{Path(DATABASE).name}> ".encode()
PROMPT_TEXT = PROMPT.decode("utf-8", errors="replace")
ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
CONTROL_CHAR_RE = re.compile(r"[\x00-\x08\x0b-\x1f\x7f]")


def debug(message: str) -> None:
    if DEBUG:
        print(f"DEBUG: {message}", file=sys.stderr)


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def write_record(handle, title: str, source_desc: str, payload_path: Path) -> None:
    handle.write(title.encode("utf-8"))
    handle.write(b"\0")
    handle.write(source_desc.encode("utf-8"))
    handle.write(b"\0")
    handle.write(str(payload_path).encode("utf-8"))
    handle.write(b"\0")


def normalize_group_path(group_path: str) -> str:
    normalized = group_path.strip()
    if not normalized or normalized == "/":
        return "/"
    normalized = normalized.rstrip("/")
    if normalized.startswith("/root/"):
        normalized = normalized[5:]
    elif normalized == "/root":
        normalized = "/"
    return normalized if normalized.startswith("/") else f"/{normalized}"


def join_entry_path(group_path: str, entry_name: str) -> str:
    if group_path == "/":
        return f"/{entry_name}"
    return f"{group_path}/{entry_name}"


def sanitize_terminal_text(text: str) -> str:
    text = text.replace("\r", "")
    text = ANSI_ESCAPE_RE.sub("", text)
    text = CONTROL_CHAR_RE.sub("", text)
    return text


def contains_prompt(output: bytes) -> bool:
    text = sanitize_terminal_text(output.decode("utf-8", errors="replace"))
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return False
    last_line = lines[-1]
    return last_line == PROMPT_TEXT.strip() or (
        last_line.endswith(">") and " " not in last_line
    )


def is_prompt_line(line: str) -> bool:
    stripped = line.strip()
    return bool(stripped) and (
        stripped == PROMPT_TEXT.strip() or (stripped.endswith(">") and " " not in stripped)
    )


def parse_command_output(output: bytes, command: str) -> str:
    text = sanitize_terminal_text(output.decode("utf-8", errors="replace"))
    lines = text.splitlines()
    if lines and command in lines[0]:
        lines = lines[1:]
    while lines and not lines[-1].strip():
        lines.pop()
    while lines and is_prompt_line(lines[-1]):
        lines = lines[:-1]
    return "\n".join(lines).strip("\n")


def parse_attachment_names(show_output: str) -> list[str]:
    attachments: list[str] = []
    in_attachments = False
    for line in show_output.splitlines():
        if line == "Attachments:":
            in_attachments = True
            continue
        if not in_attachments:
            continue
        if not line.strip() or is_prompt_line(line):
            break
        item = line.strip()
        if item.endswith(")") and " (" in item:
            item = item.rsplit(" (", 1)[0]
        attachments.append(item)
    return attachments


def read_until_prompt(master_fd: int, process: subprocess.Popen[bytes], timeout: float = 30.0) -> bytes:
    buffer = bytearray()
    deadline = time.time() + timeout
    while time.time() < deadline:
        if process.poll() is not None:
            try:
                chunk = os.read(master_fd, 4096)
                if chunk:
                    buffer.extend(chunk)
            except OSError:
                pass
            break
        try:
            chunk = os.read(master_fd, 4096)
        except BlockingIOError:
            time.sleep(0.05)
            continue
        except OSError as exc:
            die(f"failed reading keepassxc-cli output: {exc}")
        if not chunk:
            time.sleep(0.05)
            continue
        buffer.extend(chunk)
        if contains_prompt(bytes(buffer)):
            return bytes(buffer)

    if DEBUG and buffer:
        tail = sanitize_terminal_text(buffer.decode("utf-8", errors="replace")).strip()
        if tail:
            print(f"DEBUG: keepassxc output before timeout:\n{tail}", file=sys.stderr)
    die("timed out waiting for keepassxc-cli prompt")


def run_command(master_fd: int, process: subprocess.Popen[bytes], command: str, timeout: float = 30.0) -> str:
    debug(f"keepassxc> {command}")
    os.write(master_fd, command.encode("utf-8") + b"\n")
    output = read_until_prompt(master_fd, process, timeout=timeout)
    parsed = parse_command_output(output, command)
    if DEBUG and parsed:
        print(f"DEBUG: keepassxc output for {command!r}:\n{parsed}", file=sys.stderr)
    if parsed.startswith("ERROR:"):
      die(parsed)
    return parsed


def main() -> None:
    group_path = normalize_group_path(GROUP_PATH)
    debug(f"opening keepassxc session for {DATABASE} group {group_path}")

    master_fd, slave_fd = pty.openpty()
    process = subprocess.Popen(
        ["keepassxc-cli", "open", *AUTH_ARGS, DATABASE],
        stdin=slave_fd,
        stdout=slave_fd,
        stderr=slave_fd,
        close_fds=True,
    )
    os.close(slave_fd)
    os.set_blocking(master_fd, False)

    try:
        if USE_PASSWORD:
            os.write(master_fd, DATABASE_PASSWORD.encode("utf-8") + b"\n")

        initial_output = read_until_prompt(master_fd, process, timeout=120.0)
        if DEBUG:
            initial_text = sanitize_terminal_text(initial_output.decode("utf-8", errors="replace")).strip()
            if initial_text and initial_text != PROMPT_TEXT.strip():
                print(f"DEBUG: keepassxc initial output:\n{initial_text}", file=sys.stderr)

        ls_output = run_command(master_fd, process, f"ls {shlex.quote(group_path)}")
        entries = [
            line.strip()
            for line in ls_output.splitlines()
            if line.strip() and not line.endswith("/") and not is_prompt_line(line)
        ]

        with METADATA_PATH.open("wb") as metadata_handle:
            for index, entry in enumerate(entries, start=1):
                entry_path = join_entry_path(group_path, entry)
                title = run_command(master_fd, process, f"show -a Title {shlex.quote(entry_path)}").strip()
                if not title:
                    die(f"entry {entry_path} has an empty title")

                show_output = run_command(master_fd, process, f"show --show-attachments {shlex.quote(entry_path)}")
                attachment_names = parse_attachment_names(show_output)
                if len(attachment_names) > 1:
                    die(f"{title} has multiple attachments; expected at most one")

                payload_path = PAYLOAD_DIR / f"entry-{index:05d}.secret"
                if attachment_names:
                    attachment_name = attachment_names[0]
                    run_command(
                        master_fd,
                        process,
                        f"attachment-export {shlex.quote(entry_path)} {shlex.quote(attachment_name)} {shlex.quote(str(payload_path))}",
                        timeout=60.0,
                    )
                    if not payload_path.exists():
                        die(f"attachment export did not create payload for {title}")
                    write_record(metadata_handle, title, f"attachment: {attachment_name}", payload_path)
                    continue

                password = run_command(master_fd, process, f"show -s -a password {shlex.quote(entry_path)}")
                if password == "":
                    die(f"{title} has no attachment and an empty password field")
                payload_path.write_text(password, encoding="utf-8")
                write_record(metadata_handle, title, "password", payload_path)
    finally:
        try:
            if process.poll() is None:
                os.write(master_fd, b"exit\n")
        except OSError:
            pass
        try:
            process.wait(timeout=5.0)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5.0)
        os.close(master_fd)


main()
PY
}

DATABASE="${KEEPASSXC_DATABASE:-}"
GROUP_PATH="system/docker-secrets"
KEY_FILE=""
YUBIKEY="2"
FORCE="false"
DEBUG="false"
KEEP_TEMP="false"
USE_DATABASE_PASSWORD="true"
DATABASE_PASSWORD="${KEEPASS_DB_PASSWD:-}"

if ! parsed=$(getopt -o d:g:k:y:fh --long database:,group:,key-file:,yubikey:,force,debug,keep-temp,no-password,help -- "$@"); then
  usage
  exit 2
fi
eval set -- "$parsed"

while true; do
  case "$1" in
  -d | --database)
    DATABASE="$2"
    shift 2
    ;;
  -g | --group)
    GROUP_PATH="$2"
    shift 2
    ;;
  -k | --key-file)
    KEY_FILE="$2"
    shift 2
    ;;
  -y | --yubikey)
    YUBIKEY="$2"
    shift 2
    ;;
  -f | --force)
    FORCE="true"
    shift
    ;;
  --debug)
    DEBUG="true"
    shift
    ;;
  --keep-temp)
    KEEP_TEMP="true"
    shift
    ;;
  --no-password)
    USE_DATABASE_PASSWORD="false"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  *)
    usage
    exit 2
    ;;
  esac
done

[[ $# -eq 0 ]] || die "Unexpected arguments: $*"
[[ -n "$DATABASE" ]] || die "--database is required."
[[ -f "$DATABASE" ]] || die "Database not found: $DATABASE"

if [[ "$GROUP_PATH" != "/" ]]; then
  GROUP_PATH="${GROUP_PATH%/}"
fi

require_tools
require_swarm
umask 077
debug "database=$DATABASE group=$GROUP_PATH force=$FORCE yubikey=${YUBIKEY:-<none>} key_file=${KEY_FILE:-<none>}"

KEEPASSXC_AUTH_ARGS=()
if [[ -n "$KEY_FILE" ]]; then
  [[ -f "$KEY_FILE" ]] || die "Key file not found: $KEY_FILE"
  KEEPASSXC_AUTH_ARGS+=(-k "$KEY_FILE")
fi
if [[ "$USE_DATABASE_PASSWORD" == "false" ]]; then
  KEEPASSXC_AUTH_ARGS+=(--no-password)
elif [[ -z "$DATABASE_PASSWORD" ]]; then
  read -rsp "KeePassXC database password: " DATABASE_PASSWORD
  echo
fi
if [[ -n "$YUBIKEY" ]]; then
  KEEPASSXC_AUTH_ARGS+=(-y "$YUBIKEY")
fi

temp_dir=$(mktemp -d)
export_path="$temp_dir/export.xml"
payload_dir="$temp_dir/payloads"
metadata_path="$temp_dir/entries.nul"
mkdir -p "$payload_dir"

current_step="extracting matching entries"
debug "extracting entries from group $GROUP_PATH via a single keepassxc open session"
extract_entries_via_open_session "$payload_dir" "$metadata_path"

if [[ ! -s "$metadata_path" ]]; then
  echo "No entries found under $GROUP_PATH."
  exit 0
fi

entry_count=$(
  python3 - "$metadata_path" <<'PY'
import sys

with open(sys.argv[1], "rb") as handle:
    print(handle.read().count(b"\0") // 3)
PY
)
debug "prepared $entry_count entries for sync"

created_count=0
skipped_count=0
failed_count=0

while IFS= read -r -d '' title &&
  IFS= read -r -d '' source_desc &&
  IFS= read -r -d '' payload_path; do
  current_step="processing secret $title"
  debug "processing $title from $source_desc"
  if secret_exists "$title"; then
    if [[ "$FORCE" == "true" ]]; then
      debug "removing existing secret $title before recreation"
      docker secret rm "$title" >/dev/null
    else
      echo "SKIPPED: $title already exists"
      ((skipped_count += 1))
      continue
    fi
  fi

  if create_secret_from_file "$title" "$payload_path"; then
    echo "CREATED: $title ($source_desc)"
    ((created_count += 1))
  else
    echo "FAILED: unable to create Docker secret $title from $source_desc" >&2
    ((failed_count += 1))
  fi
done <"$metadata_path"

current_step="printing summary"
echo "Summary: created=$created_count skipped=$skipped_count failed=$failed_count"

if [[ "$failed_count" -gt 0 ]]; then
  exit 1
fi
