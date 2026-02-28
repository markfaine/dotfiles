# Tool Color Conflict Reference Guide

## Quick Overview: Tools with Color Output

| Tool                             | Purpose                   | Conflict Risk | Solution                              |
| -------------------------------- | ------------------------- | ------------- | ------------------------------------- |
| **bat**                          | Syntax highlighting pager | 🔴 High        | `BAT_THEME=ansi` uses terminal colors |
| **fzf**                          | Fuzzy finder              | 🔴 High        | `FZF_DEFAULT_OPTS` with ANSI indices  |
| **ripgrep (rg)**                 | Grep replacement          | 🟡 Medium      | `.ripgreprc` with `--colors` palette  |
| **eza**                          | Modern ls replacement     | 🟡 Medium      | `EZA_COLORS` environment variable     |
| **jq**                           | JSON processor            | 🟡 Medium      | `JQ_COLORS` with ANSI format          |
| **glow**                         | Markdown viewer           | 🟡 Medium      | `GLOW_STYLE=dark` for theme match     |
| **delta**                        | Git diff viewer           | 🟢 Low         | Git integration, respects terminal    |
| **dircolors**                    | ls/eza file colors        | 🟢 Low         | Tokyo Night palette (now configured)  |
| **tmux**                         | Terminal multiplexer      | 🔴 High        | Separate theme (not affected)         |
| **Language Servers**             | Diagnostics output        | 🟡 Medium      | Use terminal colors via LSP config    |
| **linters** (shellcheck, flake8) | Error output              | 🟢 Low         | Respect CLICOLOR env vars             |

---

## Environment Variables Control

### Centralized Configuration
All color settings are defined in **`~/.theme-colors`** which is sourced by `.zshenv`.

### Key Variables and Defaults

```bash
# bat - Syntax Highlighter
BAT_THEME="ansi"  # Uses terminal color palette

# fzf - Fuzzy Finder
FZF_DEFAULT_OPTS="--color=bg:-1,bg+:-1 ..."  # ANSI indices (0-15)

# ripgrep - Grep Replacement
RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
# Config includes: --colors match:fg:red --colors path:fg:cyan

# eza - ls Replacement
EZA_COLORS="da=38;5;8:di=38;5;4"  # 256-color format

# jq - JSON Processor
JQ_COLORS="0;90:0;37:0;37:0;37:0;32:1;37:1;37"  # ANSI format

# glow - Markdown Viewer
GLOW_STYLE="dark"

# terminal - Global
COLORTERM="truecolor"  # Enables 256-color support
CLICOLOR=1             # Enable colors in CLI tools
CLICOLOR_FORCE=1       # Force colors even in pipes
```

---

## ANSI Color Index Reference

### Standard (0-7) and Bright (8-15) Variants

```
 0  = black              8  = bright black (gray)
 1  = red                9  = bright red
 2  = green             10  = bright green
 3  = yellow            11  = bright yellow
 4  = blue              12  = bright blue
 5  = magenta           13  = bright magenta
 6  = cyan              14  = bright cyan
 7  = white             15  = bright white
```

### Extended (16-255) for 256-color terminals

```
16-231  = 216 RGB colors in 6×6×6 cube
232-255 = 24 grayscale colors (black to white)

Format in tools:
- fzf: --color=hl:4  (color 4 = blue)
- rg: --colors match:fg:red  (named colors)
- Code: \033[38;5;4m (ISO 256-color: blue)
```

---

## Why Conflicts Happen

### Problem: Hardcoded vs. Theme Colors

**BAD (Hardcoded):**
```bash
# fzf original default (hardcoded)
--color=hl:33,hl+:229,fg:237

# If theme doesn't have those colors, output looks wrong
```

**GOOD (Terminal-aware):**
```bash
# Uses terminal's definitions of colors 0-15
--color=hl:4,hl+:12,fg:7

# Works with any theme that defines these standard colors
```

---

## Verification Checklist

Run this to verify configuration is working:

```bash
# 1. Check environment variables
echo $BAT_THEME              # Should be: ansi
echo $FZF_DEFAULT_OPTS       # Should have: --color=...
echo $COLORTERM              # Should be: truecolor

# 2. Test each tool
bat --version && echo "✓ bat"
fzf --version && echo "✓ fzf"
rg --version && echo "✓ ripgrep"
eza --version && echo "✓ eza"
jq --version && echo "✓ jq"

# 3. Visual test with color
echo "print('test')" | bat -l python
echo -e "red\ngreen\nblue" | fzf
rg "pattern" --color always .
eza -la --icons
echo '{"test":123}' | jq .
```

Or run the verification script:
```bash
chmod +x verify-colors.sh
./verify-colors.sh
```

---

## Common Issues and Solutions

### Issue: Colors don't change when switching kitty themes

**Cause:** Theme colors are cached or BAT_THEME isn't set to "ansi"

**Solution:**
```bash
# Verify current setting
echo $BAT_THEME  # Should be 'ansi'

# Force reload
source ~/.zshenv
source ~/.theme-colors

# Test again
bat --list-themes | grep ansi
```

### Issue: fzf colors look wrong with new theme

**Cause:** FZF_DEFAULT_OPTS uses hardcoded indices that don't match theme

**Solution:**
1. Check if colors are readable (contrast is most important)
2. If not, edit `~/.theme-colors` and adjust FZF_DEFAULT_OPTS
3. Examples:
   ```bash
   # Increase contrast for light background
   --color=fg:0,bg:15,hl:1

   # Increase contrast for dark background
   --color=fg:15,bg:0,hl:4
   ```

### Issue: Some tools still show wrong colors

**Cause:** Tool doesn't respect environment variables

**Solution:**
1. Check if tool has config file support (see "Tool-Specific" section below)
2. Create config file (e.g., `~/.config/bat/config`)
3. Set explicit theme/colors there

---

## Tool-Specific Configuration Files

### bat
**Location:** `~/.config/bat/config`
**If needed, add:**
```ini
--theme=ansi
--style=numbers,grid,snip
--line-range 1:2000
```

### ripgrep
**Location:** `~/.ripgreprc` (already configured)
**Key settings:**
```
--smart-case
--colors match:fg:red
--colors path:fg:cyan
--colors match:palette:yes
```

### fzf
**Location:** `~/.fzf.zsh` (optional, uses env var by default)
**Can also use:**`FZF_DEFAULT_OPTS` environment variable

### dircolors
**Location:** `.dircolors` (already configured with Tokyo Night colors)
**Key settings:**
```bash
# Now uses Tokyo Night palette colors
DIR 00;38;5;4       # Blue (directories)
EXEC 01;38;5;2      # Green (executables)
# Images, archives, videos, etc. use appropriate Tokyo Night colors
```

### eza
**Location:** `~/.config/eza/config.toml` (optional)
**Alternative:** Use `EZA_COLORS` environment variable

### jq
**Location:** `~/.jqrc` (optional)
**Alternative:** Use `JQ_COLORS` environment variable

### git (for diff colors)
**Location:** `~/.gitconfig`
**If needed:**
```ini
[color]
    ui = auto
[color "status"]
    added = green
    deleted = red
    modified = yellow
```

---

## Switching to Different Kitty Theme

### Step 1: Choose and Download Theme
```bash
# Example: Download Dracula theme
curl -o ~/.config/kitty/dracula.conf \
  https://raw.githubusercontent.com/dracula/kitty/master/dracula.conf
```

### Step 2: Update current-theme.conf
```bash
# Backup current
cp ~/.config/kitty/current-theme.conf ~/.config/kitty/current-theme.conf.bak

# Switch to new theme
cp ~/.config/kitty/dracula.conf ~/.config/kitty/current-theme.conf
```

### Step 3: Reload Kitty
```bash
# Option A: Kill and restart kitty
killall kitty; kitty &

# Option B: Use kitty's remote command
kitten @ set-colors current-theme.conf
```

### Step 4: Verify in New Shell
```bash
# Open new terminal tab/window

# Colors should automatically adapt
bat --list-themes  # Should still show 'ansi'
fzf               # Colors should match new theme
rg "test" .       # Colors should match new theme
```

**No other changes needed** — because tool configs use ANSI indices!

---

## Customization: Creating Your Own Palette

If you want to force specific colors in tools regardless of theme:

### Option A: Override Specific Variables
```bash
# Edit ~/.theme-colors and change FZF colors:
export FZF_DEFAULT_OPTS="
  --color=bg:-1,bg+:238
  --color=fg:255,fg+:255
  --color=hl:208,hl+:208
  --color=border:240
  --color=prompt:220,pointer:208,marker:208
"
```

### Option B: Create Tool-Specific Config File
```bash
# ~/.config/bat/config
--theme=Dracula
--style=full

# Then BAT_THEME env var takes priority
```

### Option C: Use Command-Line Flags
```bash
# One-time override
bat --theme=Solarized test.py

# Environment variable override
BAT_THEME=GitHub fzf

# Config file merge
rg --colors path:fg:yellow pattern .
```

**Priority order:** CLI flags > env vars > config files > defaults

---

## When Colors Fail to Apply

### Debugging Checklist

1. **Verify tool is installed:**
   ```bash
   which bat fzf rg eza jq
   ```

2. **Verify environment variables are set:**
   ```bash
   env | grep -E "BAT_THEME|FZF_DEFAULT|EZA_COLORS"
   ```

3. **Verify configuration files exist:**
   ```bash
   ls -la ~/.theme-colors ~/.ripgreprc ~/.dircolors
   ```

4. **Check if .zshenv is sourcing theme-colors:**
   ```bash
   grep "theme-colors" ~/.zshenv
   ```

5. **Test in fresh shell:**
   ```bash
   zsh -i -c "echo $BAT_THEME"
   ```

6. **Check for conflicting configs:**
   - System-wide `/etc/` configs
   - Shell profile files (`.bashrc`, `.bash_profile`)
   - Tool-specific config files (`~/.config/bat/config`)

---

## File Location Reference

### Configuration Files in This Dotfiles Repo

```
Configs/zsh/
  ├── .theme-colors          # CENTRAL: All tool colors defined here
  ├── .zshenv                # LOADS: theme-colors on shell startup
  ├── .zshrc                 # Interactive shell config
  ├── .aliases               # Command aliases
  ├── .dircolors             # File listing colors (LS_COLORS)
  └── .ripgreprc             # Ripgrep search tool config

Configs/kitty/
  └── .config/kitty/
      ├── current-theme.conf # Active kitty theme (defines color0-15)
      ├── kitty.conf         # Kitty terminal settings
      └── keymap.py          # Kitty keybindings
```

### User Config Files (NOT in repo, optional)

```
~/.config/
  ├── bat/
  │   └── config             # Bat syntax highlighter config
  ├── eza/
  │   └── config.toml        # Exa/eza config
  ├── ripgrep/
  │   └── config             # Ripgrep config (symlink/copy .ripgreprc)
  └── fzf/
      └── (no standard location, uses env vars)

~/.gitconfig               # Git configuration
~/.fzf.zsh                 # FZF initialization (optional)
~/.dircolors               # Can be customized
~/.jqrc                    # JQ config (optional)
```

---

## Related Documentation

- [COLOR_CONFLICT_RESOLUTION.md](../COLOR_CONFLICT_RESOLUTION.md) - Detailed explanation and troubleshooting
- Kitty theme repository: https://github.com/dexpota/kitty-themes
- FZF color documentation: `fzf --help | grep -A 20 "COLOR SPECIFICATION"`
- Bat themes: `bat --list-themes`
- Exit and re-enter a shell to test: `exec zsh`

---

## Glossary

- **ANSI Colors:** Standard 0-15 color indices defined by ANSI/VT100
- **256 Colors:** Extended palette (16-255) for fine-grained color support
- **Truecolor:** 24-bit RGB colors (~16 million colors)
- **TTY:** Terminal emulator detection (forces colors even in pipes)
- **LS_COLORS:** Environment variable that controls ls/eza file colors
- **Theme:** Set of color definitions for terminal colors 0-15
- **Palette:** The 16 (or 256) colors available in a terminal
- **Index:** The number reference to a color (0-15, 0-255, etc.)

