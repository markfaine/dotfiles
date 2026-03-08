# Utilities Post-Install Hook

This script downloads and installs tools from a configuration file that aren't available via `mise`.

## Overview

The script reads a list of URLs from `~/.config/utilities/config` and:
- Downloads each tool/archive
- Extracts archives if needed (tar.gz, tar.bz2, tar.xz, tar, zip)
- Installs executables to `~/.local/bin`
- Makes files executable
- Overwrites existing files (assumes downloaded version is latest)

## Configuration

Create/edit `~/.config/utilities/config` with one URL per line:

```bash
# Comments are allowed (lines starting with #)
https://example.com/binary-tool
https://example.com/archive.tar.gz
https://example.com/archive.zip
```

## Usage

### Interactive install
```bash
~/.config/dotfiles/Hooks/utilties/post.sh
```

### Preview what would be installed (dry-run)
```bash
~/.config/dotfiles/Hooks/utilties/post.sh --dry-run
```

### Verbose output (debug mode)
```bash
~/.config/dotfiles/Hooks/utilties/post.sh --debug
```

### Disable spinner/progress animation
```bash
~/.config/dotfiles/Hooks/utilties/post.sh --no-spinner
```

## Features

- **Archive support**: Automatically detects and extracts tar.gz, tar.bz2, tar.xz, tar, and zip archives
- **Smart extraction**: Finds the executable inside extracted archives automatically
- **Dry-run mode**: Preview installations without downloading
- **Debug mode**: Verbose output for troubleshooting
- **Error logging**: Failures logged to `~/.config/utilities/hook-errors.log`
- **Progress spinner**: Visual feedback during downloads (can be disabled)
- **Overwrite safety**: Always gets latest version from URL

## Current Configuration

The example in `config` downloads:
- `ansible-vault-pass-client` - a helper tool for Ansible vault operations

## Error Handling

All failures are logged to `~/.config/utilities/hook-errors.log` with timestamps. If any downloads fail, the script exits with code 1 after attempting all URLs.

## Requirements

- `curl`: For downloading files
- `tar`: For extracting tar archives
- `unzip`: For extracting zip archives
- `~/.local/bin`: Must be in your PATH

## Integration

This script can be called as part of your dotfiles deployment process:
```bash
bash ~/.config/dotfiles/Hooks/utilties/post.sh
```

Or with options:
```bash
bash ~/.config/dotfiles/Hooks/utilties/post.sh --dry-run --debug
```
