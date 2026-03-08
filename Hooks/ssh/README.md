# SSH Post-Install Hook

This script manages SSH public keys by downloading them from URLs and adding them to `~/.ssh/authorized_keys`. It prevents duplicate keys while allowing unique keys to be appended.

## Overview

The script:
- Reads SSH public key URLs from `~/.config/ssh/config`
- Downloads each key from the provided URL
- Adds keys to `~/.ssh/authorized_keys` with deduplication
- Prevents duplicate keys using fingerprint comparison
- Logs any failures to `~/.config/ssh/hook-errors.log`
- Sets proper permissions (600) on `authorized_keys`

## Setup

### 1. Configure SSH key URLs

Edit or create `~/.config/ssh/config` with URLs to SSH public keys:

```bash
# SSH public key URLs
https://github.com/username.keys
https://example.com/path/to/public-key.pub
```

### 2. Run the hook

```bash
~/.config/dotfiles/Hooks/ssh/post.sh
```

## Usage

### Add keys to authorized_keys (standard)
```bash
./Hooks/ssh/post.sh
```

### Preview what would be added (dry-run)
```bash
./Hooks/ssh/post.sh --dry-run
```

### Verbose output (debug mode)
```bash
./Hooks/ssh/post.sh --debug
```

### Disable progress spinner
```bash
./Hooks/ssh/post.sh --no-spinner
```

### Help
```bash
./Hooks/ssh/post.sh --help
```

## Flags

- `--dry-run` / `-n` - Show what would be added without modifying authorized_keys
- `--debug` / `-d` - Verbose debug output with all downloads and modifications
- `--no-spinner` - Disable progress spinner animation
- `--help` / `-h` - Show help message

## Output

### Success
```
✓ Added key from: https://github.com/username.keys

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH Key Management Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total URLs:    1
Keys Added:    1
Duplicates:    0
Failed:        0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Duplicate Key (Not Added)
```
≈ Key already exists: https://github.com/username.keys
```

## Configuration Examples

### GitHub users
```bash
# Get all keys for a GitHub user
https://github.com/username.keys
```

### GitLab users
```bash
# Get all keys for a GitLab user
https://gitlab.com/username.keys
```

### Single public key file
```bash
https://example.com/path/to/id_rsa.pub
```

### Multiple servers
```bash
https://github.com/user1.keys
https://github.com/user2.keys
https://example.com/corporate-key.pub
```

## Deduplication

The script prevents duplicate keys by comparing key fingerprints. Even if:
- The same URL is added multiple times
- A key is added from different sources
- Keys have different comments

Only unique key material is stored. The fingerprint comparison uses the key type and public key components, ignoring comments.

## authorized_keys Format

After adding keys, `~/.ssh/authorized_keys` will look like:
```
# Added from: https://github.com/username.keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD...

# Added from: https://github.com/username.keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO...
```

Each key includes a comment showing its source URL for tracking.

## Error Handling

Failures are logged to `~/.config/ssh/hook-errors.log`:
```
2026-03-07 20:15:30: Failed to download: https://invalid-url.com/keys
2026-03-07 20:15:31: Invalid SSH key format from https://bad-format.com/keys
```

Check this file for troubleshooting.

## Security Considerations

- **File permissions**: The script automatically sets `authorized_keys` to 600 (user read/write only)
- **HTTPS only**: Use HTTPS URLs to secure key downloads
- **Key validation**: Downloaded content must match SSH public key format
- **No secret keys**: This script only handles public keys; secret keys must be managed separately

## Requirements

- `curl` - For downloading keys from URLs
- `~/.ssh` directory - Creates if doesn't exist
- `~/.config/ssh/config` - Configuration file with URLs

## Integration

Call as part of dotfiles deployment:
```bash
bash ~/.config/dotfiles/Hooks/ssh/post.sh
```

Or with options:
```bash
bash ~/.config/dotfiles/Hooks/ssh/post.sh --dry-run --debug
```

## Troubleshooting

### "curl not found"
Install curl:
```bash
# Ubuntu/Debian
sudo apt install curl

# macOS
brew install curl
```

### Keys not being added
Check for errors:
```bash
./Hooks/ssh/post.sh --debug
cat ~/.config/ssh/hook-errors.log
```

### Verify added keys
```bash
cat ~/.ssh/authorized_keys
```

### Clear and re-add all keys
```bash
# Backup first!
cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup

# Remove all
rm ~/.ssh/authorized_keys

# Re-run
./Hooks/ssh/post.sh
```

## Related Files

- Config: `~/.config/ssh/config`
- Output: `~/.ssh/authorized_keys`
- Log: `~/.config/ssh/hook-errors.log`
