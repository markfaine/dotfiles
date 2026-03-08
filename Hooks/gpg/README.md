# GPG Post-Install Hook

This script imports GPG public keys from `.asc` files into the local keyring.

## Overview

The script:
- Scans `~/.gnupg/` for `.asc` files (exported public keys)
- Imports each key into the GPG keyring using `gpg --import`
- Logs any failures to `~/.config/gpg/hook-errors.log`
- Provides progress feedback with spinner animation

## Setup

### 1. Prepare key files

Export your GPG public keys to `.asc` format and place them in `~/.gnupg/`:

```bash
# Export a key by key ID
gpg --export -a KEY_ID > ~/.gnupg/KEY_ID.asc

# Or export all public keys
gpg --export -a > ~/.gnupg/all-keys.asc
```

Alternatively, if using symlinked configuration:
```bash
# Link from dotfiles config
ln -s ~/.config/dotfiles/Configs/gpg/.gnupg/keyid.asc ~/.gnupg/keyid.asc
```

### 2. Run the hook

```bash
~/.config/dotfiles/Hooks/gpg/post.sh
```

## Usage

### Import keys (standard)
```bash
./Hooks/gpg/post.sh
```

### Preview what would be imported (dry-run)
```bash
./Hooks/gpg/post.sh --dry-run
```

### Verbose output (debug mode)
```bash
./Hooks/gpg/post.sh --debug
```

### Disable progress spinner
```bash
./Hooks/gpg/post.sh --no-spinner
```

### Help
```bash
./Hooks/gpg/post.sh --help
```

## Flags

- `--dry-run` / `-n` - Show what would be imported without importing
- `--debug` / `-d` - Verbose debug output with all import details
- `--no-spinner` - Disable progress spinner animation
- `--help` / `-h` - Show help message

## Output

### Success
```
✓ Imported: mykey.asc

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GPG Key Import Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total:     1
Imported:  1
Failed:    0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Errors

If imports fail, they're logged to `~/.config/gpg/hook-errors.log`:
```
2026-03-07 19:45:32: Failed to import: mykey.asc
```

## Key File Naming

Any `.asc` file in `~/.gnupg/` will be imported. Suggested naming:
- `8F1234567890ABCD.asc` - By key ID
- `user@example.com.asc` - By user ID
- `primary-key.asc` - By purpose
- `keyname.asc` - By display name

## Requirements

- `gpg` or `gpg2` - GnuPG for key management
- `~/.gnupg` directory exists - Default GPG home directory

## Integration

Call as part of dotfiles deployment:
```bash
bash ~/.config/dotfiles/Hooks/gpg/post.sh
```

Or in a deploy script with options:
```bash
bash ~/.config/dotfiles/Hooks/gpg/post.sh --dry-run --debug
```

## Troubleshooting

### "gpg: no default secret key" errors
This is normal - the script imports public keys. If you need secret keys, import them separately:
```bash
gpg --import ~/.gnupg/secret-key.asc
```

### Import fails
Check `~/.config/gpg/hook-errors.log` for details:
```bash
cat ~/.config/gpg/hook-errors.log
```

### Verify imported keys
```bash
gpg --list-keys
```
