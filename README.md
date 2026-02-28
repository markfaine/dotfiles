# Dotfiles

A theme-agnostic, highly customized dotfiles configuration for a consistent and productive development environment across Ubuntu and WSL2.

## Overview

These configurations provide a modern terminal environment with:

*   **Shell:** Zsh with custom configuration
*   **Terminal:** Kitty with Tokyo Night theme
*   **Multiplexer:** Tmux with comprehensive plugin system
*   **Editor:** Neovim (Lua-based configuration)
*   **Version Control:** Git with theme-aware colors
*   **Tool Management:** mise for CLI tool versions
*   **Secrets Management:** Doppler

The setup uses **theme-agnostic color configuration** — all tools automatically adapt to your active terminal theme by using ANSI color indices instead of hardcoded values.

## Key Features

### Theme-Agnostic Color System
*   **Any Theme, Automatic Adaptation:** Switch kitty themes without reconfiguring tools
*   **ANSI Index Mapping:** All colors reference terminal palette (0-15) instead of hex values
*   **Centralized Control:** Single `.theme-colors` file manages all tool colors
*   **60+ CLI Tools:** bat, fzf, ripgrep, eza, jq, git, and more automatically adapt

### Modern Tooling & Configuration
*   **Consistent Formatting:** Clean section headers, no fold markers, readable structure
*   **Modular Organization:** Each application in separate, well-documented configs
*   **Automated Deployment:** Ansible-based deployment with Tuckr symlink management
*   **WSL2 Optimized:** Seamless experience on native Linux and WSL2
*   **Performance Tuned:** Optimized settings for fast shell startup and smooth operation

## Directory Structure

The repository is organized for deployment with [Tuckr](https://github.com/RaphGL/Tuckr):

```
dotfiles/
├── Configs/          # Application configurations (symlinked by Tuckr)
│   ├── zsh/         # Shell config with theme-agnostic colors
│   ├── kitty/       # Terminal config with Tokyo Night theme
│   ├── tmux/        # Multiplexer config with session management
│   ├── nvim/        # Neovim with Lua-based configuration
│   ├── git/         # Git with ANSI color indices
│   ├── mise/        # Tool version management
│   └── docker/      # Docker configurations
├── Hooks/           # Pre/post symlink scripts
│   ├── kitty/       # Kitty installation hooks
│   ├── nvim/        # Neovim setup hooks
│   ├── mise/        # Tool installation hooks
│   └── zsh/         # Shell initialization hooks
└── README.md        # This file
```

## Color System

All tools use **ANSI terminal color indices (0-15)** that automatically adapt to your active kitty theme:

### How It Works

1. **Kitty theme defines colors:** `current-theme.conf` sets what colors 0-15 actually display
2. **Tools reference indices:** bat, fzf, git, etc. use "color 4" instead of "#7aa2f7"
3. **Automatic adaptation:** Change theme → all tools instantly match new palette

### Configured Tools

| Tool        | Configuration      | Location        |
| ----------- | ------------------ | --------------- |
| **bat**     | `BAT_THEME=ansi`   | `.theme-colors` |
| **fzf**     | ANSI color indices | `.theme-colors` |
| **ripgrep** | Terminal palette   | `.ripgreprc`    |
| **eza**     | EZA_COLORS         | `.theme-colors` |
| **git**     | Color indices 0-15 | `.gitconfig`    |
| **tmux**    | colour0-colour15   | `.tmux-colors`  |
| **jq**      | ANSI format        | `.theme-colors` |

### Switching Themes

```bash
# 1. Update theme
cp new-theme.conf ~/.config/kitty/current-theme.conf

# 2. Reload kitty (restart or reload config)

# 3. Done! All tools automatically adapt
```

## Configuration Highlights

### Zsh Shell
*   **Fast startup:** Optimized loading with znap plugin manager
*   **SSH agent:** Persistent across sessions, tmux-aware
*   **Completions:** fpath-based system with tmuxinator support
*   **Theme colors:** Centralized in `.theme-colors`
*   **Location:** `Configs/zsh/`

### Kitty Terminal
*   **GPU-accelerated:** Hardware rendering for smooth scrolling
*   **Tokyo Night theme:** Cool-toned, eye-friendly color scheme
*   **Fira Code font:** 20+ OpenType features configured
*   **Mouse support:** Extensive click/scroll mappings
*   **Location:** `Configs/kitty/.config/kitty/`

### Tmux Multiplexer
*   **Plugin manager:** TPM with 15+ plugins
*   **Session management:** tmux-resurrect with manual restore
*   **Auto-save:** Every 15 minutes (auto-restore disabled)
*   **Tmuxinator:** Compatible session configuration
*   **Theme-aware:** Colors adapt to terminal palette
*   **Location:** `Configs/tmux/`

### Git Configuration
*   **ANSI colors:** Theme-agnostic diff/status output
*   **Nvim mergetool:** DiffviewOpen integration
*   **GitHub CLI:** Credential helper configured
*   **Smart aliases:** `lg`, `up`, `amend`, and more
*   **Location:** `Configs/git/.gitconfig`

### Tool Versions (mise)
*   **60+ tools:** bat, fzf, ripgrep, eza, node, python, etc.
*   **Version pinning:** Consistent tools across machines
*   **Auto-activation:** Per-directory .tool-versions support
*   **Location:** `Configs/mise/.config/mise/`

## Formatting Conventions

All configuration files follow consistent formatting standards:

*   **Section headers:** Clean `====` style separators
*   **No fold markers:** Removed `{{{ }}}` markers for cleaner diffs
*   **Comments:** Descriptive, explain "why" not "what"
*   **Indentation:** Tabs for shell/config, spaces for code
*   **Structure:** Logical grouping with clear boundaries

## Deployment

### Automated (Ansible)

These dotfiles deploy via the `user` role in the [net.markfaine](https://github.com/markfaine/net-markfaine) collection:

```bash
# Run ansible playbook that includes the user role
ansible-playbook site.yml
```

The directory structure is compatible with [Tuckr](https://github.com/RaphGL/Tuckr), which manages symlinking configurations to their appropriate locations. The `Hooks/` directory contains scripts that run at different stages to ensure dependencies are met.

### Manual (Tuckr)

```bash
# 1. Clone repository
git clone <repo-url> ~/.config/dotfiles
cd ~/.config/dotfiles

# 2. Install tuckr (if not installed)
cargo install tuckr

# 3. Symlink all configurations
tuckr set -fy '*'

# 4. Install dependencies (optional)
./Hooks/*/pre.sh   # Run pre-hooks
./Hooks/*/post.sh  # Run post-hooks
```

## Quick Start

### First Time Setup

1. **Deploy dotfiles** (see Deployment section above)
2. **Reload shell:** `exec zsh` or restart terminal
3. **Verify colors:** Tools should match your terminal theme
4. **Install tmux plugins:** `<prefix>I` (prefix defaults to C-j)

### Verify Installation

```bash
# Check environment
echo $BAT_THEME        # Should be: ansi
echo $COLORTERM        # Should be: truecolor

# Test tools
echo "print('test')" | bat -l python
echo -e "opt1\nopt2" | fzf
rg "pattern" ~/.config/dotfiles/
eza -la --icons

# Verify git colors
git log --oneline --color=always | head
```

### Common Tasks

**Switch themes:**
```bash
cd ~/.config/kitty
cp themes/new-theme.conf current-theme.conf
# Restart kitty - all tools adapt automatically
```

**Update tmux plugins:**
```bash
<prefix>U  # prefix is C-j by default
```

**Reload configurations:**
```bash
exec zsh                    # Reload shell
<prefix>r                   # Reload tmux
kitty @ load-config         # Reload kitty (from within kitty)
```

**Restore tmux session:**
```bash
<prefix>C-r  # Manual restore (auto-restore disabled)
```

## Troubleshooting

### Colors Don't Match Theme

**Issue:** Tool colors don't adapt to new theme

**Check:**
```bash
echo $BAT_THEME           # Should be 'ansi', not a theme name
echo $FZF_DEFAULT_OPTS    # Should have --color= with numbers
echo $COLORTERM           # Should be 'truecolor'
```

**Fix:** Reload shell or source `.zshenv`
```bash
source ~/.zshenv
```

### Tmux Colors Wrong

**Issue:** Tmux doesn't match terminal colors

**Check:**
```bash
tmux show-options -g | grep terminal-overrides
```

**Fix:** Reload tmux config
```bash
<prefix>r  # Or manually: tmux source ~/.tmux.conf
```

### SSH Loading Causes Tmux Exit

**Issue:** Tmux immediately exits on startup

**Fix:** Already handled - `.load_ssh` detects TMUX and skips initialization
```bash
# Verify in .load_ssh:
if [[ -n "${TMUX:-}" ]]; then return 0; fi
```

### Completions Not Working

**Issue:** Tab completion missing for tmuxinator or other tools

**Check:**
```bash
echo $fpath  # Should include home directory
ls -la ~/    # Should see _tmuxinator file
```

**Fix:** Rebuild completions
```bash
rm ~/.zcompdump*
exec zsh
```

### Session Restore Conflicts

**Issue:** Tmuxinator sessions overridden by continuum

**Solution:** Auto-restore is disabled. Use manual restore:
```bash
<prefix>C-r  # Manually restore last saved session only when needed
```

## Additional Documentation

For detailed information on specific components:

*   **Color system details:** See `COLOR_CONFLICT_RESOLUTION.md`
*   **Tool reference:** See `TOOL_COLOR_REFERENCE.md`
*   **Tmux colors:** See `Configs/tmux/TMUX_COLORS.md`
*   **Implementation summary:** See `IMPLEMENTATION_SUMMARY.md`
*   **Verification script:** Run `./verify-colors.sh`

## Contributing

When modifying configurations:

1. **Maintain formatting:** Use `====` headers, no fold markers
2. **Use ANSI colors:** Reference terminal indices (0-15), not hex values
3. **Document changes:** Add comments explaining non-obvious choices
4. **Test thoroughly:** Verify changes don't break theme adaptation

## License

Personal dotfiles - use at your own risk. Feel free to adapt for your own use.
