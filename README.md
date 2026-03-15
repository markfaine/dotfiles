# Dotfiles

## Overview

This repository is a Tuckr-managed dotfiles setup for Linux/WSL. It is organized by module so not everything has to be used.  

High-level structure:

1. `Configs/<module>/...`: files that Tuckr symlinks.
2. `Hooks/<module>/pre.sh`: setup before symlinking.
3. `Hooks/<module>/post.sh`: setup after symlinking.
4. `Hooks/<module>/rm_.sh`: cleanup on `tuckr unset` (where implemented).

Design goals:

1. Modular adoption instead of all-or-nothing.
2. Automated setup/teardown via hooks.
3. XDG-oriented paths with sensible fallbacks.
4. Easy containerized testing before host adoption.

## Quickstart/Test

### Install On A Host

```bash
git clone https://github.com/markfaine/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles
bash install.sh
```

Install from a branch:

```bash
bash install.sh --branch development
```

### Quick Docker Test Before Adopting

Run the installer in a throwaway Ubuntu container:

```bash
cd ~/.config/dotfiles
./test.sh
```

Useful options:

1. `--branch <name>`: test a non-default dotfiles branch.
2. `--debug`: verbose output.
3. `--keep`: keep container running for manual inspection.
4. `--no-cleanup`: skip docker prune before image build.
5. `--zsh-bench`: run `romkatv/zsh-bench` inside the container after install.

Examples:

```bash
./test.sh --branch development --debug
./test.sh --keep --zsh-bench
```

## Tuckr Config Catalog

### `apt`

1. Dotfiles provided:
   `Configs/apt/.config/apt/install`, `Configs/apt/.config/apt/remove`
2. Hooks:
   `pre.sh` ensures apt config files exist.
   `post.sh` installs/removes packages from lists.
   `rm_.sh` removes module config.
3. External dependencies:
   `apt-get`, `dpkg-query`, and either root or `sudo`.
4. Assumptions:
   Debian/Ubuntu-like host package manager.

### `docker`

1. Dotfiles provided:
   Docker client config/state files under `.docker/...`.
2. Hooks:
   No dedicated `Hooks/docker` currently.
3. External dependencies:
   Docker CLI/daemon as needed by your workflows.
4. Assumptions:
   Often paired with `pass`/`gpg` if using pass credential helper.

### `fonts`

1. Dotfiles provided:
   `Configs/fonts/.config/fonts/install` (archive URLs).
2. Hooks:
   `pre.sh` ensures install list exists.
   `post.sh` downloads/extracts fonts and refreshes cache.
   `rm_.sh` removes module config.
3. External dependencies:
   `curl` or `wget`, `tar`, `unzip` for zip archives, `fc-cache` on Linux.
4. Assumptions:
   Network access to font URLs.

### `gpg`

1. Dotfiles provided:
   GPG helper scripts and key import files under `Configs/gpg/...`.
2. Hooks:
   `pre.sh` prepares `GNUPGHOME` and key import directories.
   `post.sh` imports `.asc` keys into keyring.
   `rm_.sh` removes module config directory.
3. External dependencies:
   `gpg` or `gpg2`.
4. Assumptions:
   Used by `pass` workflows for encrypted password storage.

### `kitty`

1. Dotfiles provided:
   Kitty config plus helper scripts under `Configs/kitty/...`.
2. Hooks:
   `pre.sh` prepares target dirs.
   `post.sh` installs kitty (if missing), links binaries, patches desktop entries, writes terminal list.
   `rm_.sh` removes generated artifacts and module config.
3. External dependencies:
   `curl`, `xz`, `sed`, standard POSIX tooling.
4. Assumptions:
   Linux desktop integration paths available if desktop entries are used.

### `mise`

1. Dotfiles provided:
   `Configs/mise/.config/mise/config.toml`
2. Hooks:
   `pre.sh` installs mise if missing.
   `post.sh` bootstraps Node, installs toolchain, reshim/prune.
   `rm_.sh` removes module config.
3. External dependencies:
   `curl` or `wget`, network access.
4. Assumptions:
   Other modules may depend on tools installed via mise.

### `nvim`

1. Dotfiles provided:
   Full Neovim tree under `Configs/nvim/.config/nvim/...`.
2. Hooks:
   `pre.sh` clears existing target for directory-level relink.
   `post.sh` runs headless lazy sync.
   `rm_.sh` removes module config.
3. External dependencies:
   `nvim`.
4. Assumptions:
   Better experience when language tools are already installed (often via `mise`).

### `pass`

1. Dotfiles provided:
   `Configs/pass/.config/pass/repos`
2. Hooks:
   `pre.sh` ensures config files exist.
   `post.sh` clones listed repos and writes docker-pass initialization marker.
   `rm_.sh` removes module config.
3. External dependencies:
   `git`, `pass`.
4. Assumptions:
   Usually paired with working `gpg` setup.

### `ssh`

1. Dotfiles provided:
   `Configs/ssh/.config/ssh/authorized_keys` (URL list).
2. Hooks:
   `pre.sh` prepares ssh config and `~/.ssh` perms.
   `post.sh` downloads keys, deduplicates by fingerprint, appends to `~/.ssh/authorized_keys`.
   `rm_.sh` removes module config.
3. External dependencies:
   `curl`, `sha256sum`, `awk`, `grep`.
4. Assumptions:
   Network access to key URLs.

### `tools`

1. Dotfiles provided:
   `Configs/tools/.config/tools/sources`
2. Hooks:
   `pre.sh` ensures sources file exists.
   `post.sh` downloads binaries/archives and installs to `~/.local/bin`.
   `rm_.sh` removes module config.
3. External dependencies:
   `curl`, `tar`, `unzip` for zip archives.
4. Assumptions:
   Complements `mise` for tools not managed there.

### `wsl_wsl`

1. Dotfiles provided:
   WSL-specific files including `.wsl`.
2. Hooks:
   `post.sh` is currently a placeholder/prototype for WSL configuration behavior.
3. External dependencies:
   WSL environment, `sudo`, writable Windows mount paths.
4. Assumptions:
   Intended for WSL only.

### `zsh`

1. Dotfiles provided:
   Main shell files (`.zshrc`, `.zplugins`, `.paths`, aliases, plugin snippets, site-functions).
2. Hooks:
   `pre.sh` prepares config/data/cache and relink behavior for `site-functions`.
   `post.sh` validates startup files and runs zsh startup checks.
   `rm_.sh` removes module dirs and shell caches.
3. External dependencies:
   `zsh`; plugin repositories fetched by znap during startup.
4. Assumptions:
   Core module used by most workflows in this repo.

## Additional Notes

### Safety: Existing Dotfiles, Backups, and Revert

If you already manage dotfiles, do this before first install.

1. Backup existing dotfiles directory if present:

```bash
if [ -d ~/.config/dotfiles ]; then
  mv ~/.config/dotfiles ~/.config/dotfiles.backup.$(date +%Y%m%d-%H%M%S)
fi
```

2. Backup currently active files you care about before symlinking:

```bash
mkdir -p ~/.dotfiles-preinstall-backup
cp -a ~/.zshrc ~/.zplugins ~/.paths ~/.zlogout ~/.dotfiles-preinstall-backup/ 2>/dev/null || true
cp -a ~/.config/kitty ~/.config/nvim ~/.dotfiles-preinstall-backup/ 2>/dev/null || true
```

3. Find existing symlinks in common locations:

```bash
find ~ -maxdepth 2 -type l \( -name '.zshrc' -o -name '.zplugins' -o -name '.paths' -o -name '.zlogout' \)
find ~/.config -maxdepth 3 -type l 2>/dev/null
```

4. Remove old symlinks only (leave regular files intact):

```bash
find ~ -maxdepth 2 -type l \( -name '.zshrc' -o -name '.zplugins' -o -name '.paths' -o -name '.zlogout' \) -delete
find ~/.config -maxdepth 3 -type l -delete 2>/dev/null || true
```

5. Revert installation (safe default):

```bash
cd ~/.config/dotfiles
~/.local/bin/tuckr unset -fy '*'
```

6. Revert installation (module-by-module):

```bash
~/.local/bin/tuckr unset -fy zsh nvim kitty mise pass ssh tools gpg fonts apt wsl
```

7. Restore your backups:

```bash
cp -a ~/.dotfiles-preinstall-backup/.zshrc ~/.dotfiles-preinstall-backup/.zplugins ~/.dotfiles-preinstall-backup/.paths ~/.dotfiles-preinstall-backup/.zlogout ~/
cp -a ~/.dotfiles-preinstall-backup/kitty ~/.config/ 2>/dev/null || true
cp -a ~/.dotfiles-preinstall-backup/nvim ~/.config/ 2>/dev/null || true
```

### Incremental Adoption Is Recommended

Start with a subset and expand gradually.

1. Begin with `zsh` and `mise`.
2. Add `kitty` and `nvim`.
3. Add `pass`, `gpg`, and `ssh` only if needed.

### Validation Commands

```bash
# Hook syntax sanity
find Hooks -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n

# Container test
./test.sh --debug

# Container test with zsh benchmark
./test.sh --zsh-bench
```

### Customization Points

1. Add machine-local shell overrides in `~/.zshrc.local`.
2. Edit package/tool/font source lists in `Configs/*/.config/*/...`.
3. Keep secrets and host-specific values out of tracked files.

## License

Personal dotfiles published for reuse and adaptation. Use at your own risk.
