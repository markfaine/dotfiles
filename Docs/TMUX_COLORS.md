# Tmux Color System Documentation

## Overview

The tmux color configuration follows the same theme-agnostic philosophy as the shell color system. Instead of hardcoding hex color values, we use terminal palette indices (color0-color15) that automatically adapt to your current kitty theme.

## File Structure

- **[.tmux-colors](.tmux-colors)** - Central color configuration for tmux
- **[.tmux.conf.local](.tmux.conf.local)** - Sources `.tmux-colors` and configures Tokyo Night plugin

## Color Mapping

Colors reference the terminal palette defined in kitty's theme:

| Palette Index | Tokyo Night Color    | Usage                  |
| ------------- | -------------------- | ---------------------- |
| color0        | #15161e (dark bg)    | Background, status bar |
| color1        | #f7768e (red)        | Errors, alerts         |
| color2        | #9ece6a (green)      | Success, active states |
| color3        | #e0af68 (yellow)     | Warnings, activity     |
| color4        | #7aa2f7 (blue)       | Highlights, borders    |
| color5        | #bb9af7 (purple)     | Special elements       |
| color6        | #7dcfff (cyan)       | Links, info            |
| color7        | #a9b1d6 (light gray) | Inactive text          |
| color8        | #414868 (gray)       | Borders, dividers      |
| color15       | #c0caf5 (white)      | Foreground text        |

## Tmux Elements Styled

### Status Bar
- Background: color0 (dark)
- Foreground: color15 (bright text)
- Current window: color4 (blue, bold)

### Panes
- Active border: color4 (blue)
- Inactive border: color8 (gray)
- Title bar: Configured via pane-border-format

### Messages
- Command prompt: color15 on color0 (bright text on dark)
- Copy mode: color0 on color4 (dark text on blue highlight)

### Clock
- Clock mode: color4 (blue)

## Plugin Integration

The Tokyo Night tmux plugin (`janoamaral/tokyo-night-tmux`) provides comprehensive theming for:
- Status bar widgets (path, hostname, network stats)
- Window list formatting
- Tab styling
- Icons and separators

Our `.tmux-colors` file complements this by ensuring non-themed elements match the same color palette.

## Changing Themes

To switch to a different kitty theme:

1. Change the theme in `Configs/kitty/.config/kitty/current-theme.conf`
2. Run `tuckr set -fy '*'` to update symlinks
3. Restart tmux or run `tmux source ~/.tmux.conf`

All colors will automatically adapt to the new theme's palette.

## Key Bindings Updated

### Fixed Conflicts
- **Clear scrollback**: Changed from `C-k` (global) to `<prefix>C-k`
  - Prevents conflict with shell/vim `C-k` usage

### Prefix Reminders
- **C-a reminder**: Changed from global to `<prefix>C-a`
- **C-b reminder**: Changed from global to `<prefix>C-b`
  - No longer intercepts these keys in other applications

### Session Restore
- **Manual restore**: `<prefix>C-r` - Manually restore last saved session
  - Auto-restore is disabled to avoid conflicts with tmuxinator sessions

## New Features Added

### Plugins
- **tmux-open**: Press `o` in copy mode to open files/URLs
- **tmux-logging**:
  - `<prefix>Shift-P` - Toggle logging
  - `<prefix>Alt-p` - Screen capture
  - `<prefix>Alt-P` - Save complete history

### Performance
- Network speed refresh: Reduced from 1s to 5s for better performance

### Session Management
- **Auto-restore disabled**: `@continuum-restore` set to 'off' to prevent conflicts with tmuxinator
- **Manual restore**: Use `<prefix>C-r` to manually restore last saved session
- **Auto-save**: Sessions still auto-save every 15 minutes
- **Tmuxinator compatibility**: Starting sessions with tmuxinator won't be overridden by continuum

## Removed Plugins

The following plugins were removed as their functionality overlaps with native tmux 3.0+ features:
- `tmux-copycat` - Native search is now sufficient
- `tmux-normalmode` - Native copy mode works well

If you find you miss these features, they can be re-added to the Plugins section in `.tmux.conf.local`.

## Troubleshooting

### Colors Don't Match
1. Verify COLORTERM=truecolor is set: `echo $COLORTERM`
2. Check terminal-overrides are loaded: `tmux show-options -g terminal-overrides`
3. Ensure `.tmux-colors` is sourced: `tmux source ~/.tmux-colors`

### Keybindings Not Working
1. List all bindings: `tmux list-keys`
2. Check for conflicts: `tmux list-keys | grep "<key>"`
3. Reload config: `<prefix>r`

### Plugins Not Loading
1. Verify TPM is installed: `ls ~/.tmux/plugins/tpm`
2. Install plugins: `<prefix>I` (capital I)
3. Update plugins: `<prefix>U`
4. Remove plugins: `<prefix>Alt-u`

### Session Restore Issues
- **Tmuxinator sessions getting overridden**: Auto-restore is now disabled. Use `<prefix>C-r` to manually restore when needed.
- **Sessions not saving**: Check continuum status with `<prefix>s` and look for save indicator in status bar
- **Manual save**: Use `<prefix>Ctrl-s` to force save current session
