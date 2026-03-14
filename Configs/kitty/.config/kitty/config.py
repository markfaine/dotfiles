#!/usr/bin/env python3
"""Modern Kitty Config Kitten - Display and compare Kitty configuration.

A comprehensive kitten to visualize kitty's complete configuration including options,
keymaps, mouse bindings, colors, environment variables, and available actions.

Uses Python 3.12+ features: pattern matching, modern type hints, dataclasses, and
structural matching for cleaner, more maintainable code.
"""

from __future__ import annotations

import os
import re
import socket
import sys
import termios
import time
from collections import defaultdict
from contextlib import suppress
from dataclasses import dataclass, field, replace
from functools import partial
from io import StringIO
from itertools import chain
from pathlib import Path
from pprint import pformat
from typing import Any, Callable, Final, Iterator, NamedTuple, TypeVar

from kittens.tui.handler import result_handler
from kittens.tui.operations import colored, styled

from kitty import fast_data_types
from kitty.boss import Boss
from kitty.cli import create_default_opts, version
from kitty.config import load_config
from kitty.constants import (
    extensions_dir,
    is_macos,
    is_wayland,
    kitty_base_dir,
    kitty_exe,
    shell_path,
)
from kitty.fast_data_types import Color, num_users
from kitty.options.types import Options as KittyOpts
from kitty.options.types import defaults
from kitty.options.utils import KeyDefinition, KeyboardMode
from kitty.rgb import color_as_sharp
from kitty.types import MouseEvent, Shortcut, mod_to_names

# Type aliases using PEP 695 (Python 3.12+)
type EventMap[K] = dict[K, str]
type ShortcutMap = dict[Shortcut, str]
type PrintFn = Callable[..., None]
type FormatterFn = Callable[[str], str]
type JustifyFn = Callable[[int, str], str]

# Global compile patterns for performance
SHORTCUT_PATTERN: Final = re.compile(r"^((([^+]+)\+)*)(.*)$")
ACTION_PATTERN: Final = re.compile(r"([^ ]+)(.*)")
TTY_PATTERN: Final = re.compile(r"^/dev/([^/]+)/([^/]+)$")


class TableFormat(NamedTuple):
    """Column formatting specifications for table output."""

    indent: int = 0
    justify: JustifyFn = lambda _n, s: s
    format_fn: FormatterFn = lambda s: s


@dataclass
class ConfigOptions:
    """Command-line configuration with intelligent part resolution.

    Supports include/exclude semantics:
    - All parts None: include all
    - Any True: only include True parts
    - Any False: include everything except False parts
    """

    diff: bool = False
    plain: bool = False
    compact: bool = False  # Optimized output for piping to fzf/grep
    links: bool = True
    deleted: bool = True
    empty: bool = True
    parts: dict[str, bool | None] = field(
        default_factory=lambda: {
            "info": None,
            "config": None,
            "mouse": None,
            "keys": None,
            "colors": None,
            "env": None,
            "actions": None,
        }
    )

    def resolve_parts(self) -> None:
        """Intelligently resolve part visibility based on include/exclude rules."""
        values = list(self.parts.values())

        match values:
            case values if any(v is True for v in values):
                # Any True: disable all None parts
                self.parts = {
                    k: v if v is not None else False for k, v in self.parts.items()
                }
            case values if any(v is False for v in values):
                # Any False: enable all None parts
                self.parts = {
                    k: v if v is not None else True for k, v in self.parts.items()
                }
            case _:
                # All None: enable all
                self.parts = {k: True for k in self.parts}

        # Adjustments based on other options
        if self.diff:
            self.empty = False
        if self.plain:
            self.links = False

    def set_debug_config(self, value: bool) -> ConfigOptions:
        """Set options combination for debug output similarity."""
        if not value:
            return replace(self)
        return replace(
            self,
            diff=True,
            deleted=True,
            empty=False,
            plain=False,
            links=True,
            parts={**self.parts, "actions": False},
        )

    def set_all_parts(self, value: bool) -> ConfigOptions:
        """Set all parts visibility."""
        return replace(self, parts={k: value for k in self.parts})


class SystemInfo(NamedTuple):
    """System information collected at startup."""

    uname: os.uname_result
    hostname: str
    current_time: time.struct_time
    tty_name: str
    baud_rate: int
    num_users: int
    env_vars: dict[str, str]


class ActionRegistry:
    """Registry tracking actions and their keybindings."""

    def __init__(self) -> None:
        self._action_map: dict[str, list[tuple[str, str]]] = defaultdict(list)

    def register(self, action: str, shortcut: str) -> None:
        """Register a shortcut for an action."""
        base_action = re.sub(r" .*$", "", action)
        self._action_map[base_action].append((shortcut, action))

    def get_shortcuts_for(self, action: str) -> list[tuple[str, str]]:
        """Get all shortcuts for an action."""
        base_action = re.sub(r" .*$", "", action)
        return sorted(
            self._action_map.get(base_action, []),
            key=lambda x: self._shortcut_sort_key(x[0]),
        )

    @staticmethod
    def _shortcut_sort_key(shortcut: str) -> tuple[str, str]:
        """Extract sort key from shortcut (key first, then modifiers)."""
        mod, key = parse_shortcut(shortcut)
        return (key, mod)


# Color formatting functions
def fmt_red(s: str) -> str:
    return colored(s, "red")


def fmt_green(s: str) -> str:
    return colored(s, "green")


def fmt_yellow(s: str) -> str:
    return colored(s, "yellow")


def fmt_blue(s: str) -> str:
    return colored(s, "blue")


def fmt_title(s: str) -> str:
    return colored(s, "blue", intense=True)


def fmt_dim(s: str) -> str:
    return styled(s, dim=True)


def fmt_bold(s: str) -> str:
    return styled(s, bold=True)


# Utility functions
def parse_shortcut(text: str) -> tuple[str, str]:
    """Parse shortcut into modifiers and key."""
    if m := SHORTCUT_PATTERN.fullmatch(text):
        return m.group(1), m.group(4)
    return "", text


def parse_action(text: str) -> tuple[str, str]:
    """Parse action into action name and arguments."""
    if m := ACTION_PATTERN.fullmatch(text):
        return m.group(1), m.group(2)
    return text, ""


def format_shortcut_display(mod: str, key: str) -> str:
    """Format shortcut for display with colors."""
    return fmt_yellow(mod) + fmt_green(key)


def get_system_info() -> SystemInfo:
    """Collect comprehensive system information."""
    uname_info = os.uname()

    try:
        hostname = socket.gethostname()
    except OSError:
        hostname = "localhost"

    current_time = time.localtime()

    try:
        tty_name = format_tty_name(os.ctermid())
    except OSError:
        tty_name = "(none)"

    baud_rate = 0
    if sys.stdin.isatty():
        with suppress(OSError):
            baud_rate = termios.tcgetattr(sys.stdin.fileno())[5]

    try:
        num_users_count = num_users()
    except RuntimeError:
        num_users_count = -1

    # Collect environment variables
    env_vars = {}
    for key in chain(
        "PATH LANG KITTY_CONFIG_DIRECTORY KITTY_CACHE_DIRECTORY "
        "VISUAL EDITOR SHELL GLFW_IM_MODULE KITTY_WAYLAND_DETECT_MODIFIERS "
        "DISPLAY WAYLAND_DISPLAY USER XCURSOR_SIZE".split(),
        (k for k in os.environ if k.startswith(("LC_", "XDG_"))),
    ):
        if value := os.environ.get(key):
            env_vars[key] = value

    return SystemInfo(
        uname=uname_info,
        hostname=hostname,
        current_time=current_time,
        tty_name=tty_name,
        baud_rate=baud_rate,
        num_users=num_users_count,
        env_vars=env_vars,
    )


def format_tty_name(raw: str) -> str:
    """Format TTY name for display."""
    return TTY_PATTERN.sub(r"\1\2", raw)


def get_keyboard_keymaps(opts: KittyOpts) -> ShortcutMap:
    """Extract keyboard mappings from kitty options."""
    result: ShortcutMap = {}

    # Iterate through all keyboard modes (default and custom)
    for mode_name, mode in opts.keyboard_modes.items():
        # Each mode has a keymap dict of key -> list of KeyDefinition objects
        for key, defs in mode.keymap.items():
            if isinstance(defs, list) and defs:
                # Get the primary (first) definition
                defn = defs[0]
                # Use human_repr() method if available
                if hasattr(defn, "human_repr") and callable(defn.human_repr):
                    action = defn.human_repr()
                else:
                    action = str(defn)
                result[Shortcut((key,))] = action

    return result


def justify_left(width: int, text: str) -> str:
    return text.ljust(width)


def justify_right(width: int, text: str) -> str:
    return text.rjust(width)


def justify_center(width: int, text: str) -> str:
    return text.center(width)


# Table formatting
def format_table(
    rows: list[list[str]], formats: list[TableFormat]
) -> list[tuple[list[str], str]]:
    """Format rows into aligned columns with specified formatting."""
    if not rows:
        return []

    # Calculate column widths
    column_widths = [max(len(row[i]) for row in rows) for i in range(len(rows[0]))]

    result = []
    for row in rows:
        formatted_cells = [
            " " * fmt.indent + fmt.format_fn(fmt.justify(width, cell))
            for cell, fmt, width in zip(row, formats, column_widths)
        ]
        result.append((row, "".join(formatted_cells)))

    return result


def print_table(
    rows: list[list[str]],
    formats: list[TableFormat],
    print_fn: PrintFn,
    row_format_fn: Callable[[list[str], str], str] | None = None,
) -> None:
    """Print formatted table."""
    for row, formatted_text in format_table(rows, formats):
        if row_format_fn:
            formatted_text = row_format_fn(row, formatted_text)
        print_fn(formatted_text)


def print_all_shortcuts(
    what: str,
    shortcuts: EventMap[Any],
    kitty_mod: int,
    print_fn: PrintFn,
    compact: bool = False,
) -> None:
    """Display all shortcuts without diffing."""
    if not shortcuts:
        return

    # Convert to display format and sort
    items = sorted([(k.human_repr(kitty_mod), v) for k, v in shortcuts.items()])

    if compact:
        # Compact mode: clean aligned output for fzf with `--ansi`
        # Find max shortcut length for alignment (using raw string length)
        max_len = max(len(s) for s, _ in items)
        for shortcut_str, action in items:
            # Align the shortcut first (before coloring), then apply color
            aligned_shortcut = shortcut_str.ljust(max_len)
            colored_shortcut = colored(aligned_shortcut, "yellow")
            # Format line with proper spacing for fzf
            print_fn(f"{colored_shortcut} → {action}")
    else:
        # Normal mode: with headers and indentation
        event_type = "shortcuts" if what == "keys" else "mouse actions"
        print_fn(fmt_title(f"Configured {what} ({event_type})"))
        for shortcut_str, action in items:
            print_fn(f"  {fmt_yellow(shortcut_str)} → {action}")


def compare_maps(
    what: str,
    final: EventMap[Any],
    initial: EventMap[Any],
    final_kitty_mod: int,
    initial_kitty_mod: int,
    print_fn: PrintFn,
) -> None:
    """Compare and display differences between event maps."""
    ef = {k.human_repr(final_kitty_mod): v for k, v in final.items()}
    ei = {k.human_repr(initial_kitty_mod): v for k, v in initial.items()}

    added = set(ef) - set(ei)
    removed = set(ei) - set(ef)
    changed = {k for k in set(ef) & set(ei) if ef[k] != ei[k]}

    event_type = "shortcuts" if what == "keys" else "mouse actions"
    title_text = f"Config {what} ({event_type})"

    if added or removed or changed:
        print_fn(fmt_title(title_text))

    # Print added
    if added:
        print_fn("  Added:")
        for item in sorted(added):
            print_fn(f"    {fmt_green(item)} → {fmt_dim(ef[item])}")

    # Print removed
    if removed:
        print_fn("  Removed:")
        for item in sorted(removed):
            print_fn(f"    {fmt_yellow(item)} → {fmt_dim(ei[item])}")

    # Print changed
    if changed:
        print_fn("  Changed:")
        for item in sorted(changed):
            print_fn(f"    {fmt_yellow(item)}")
            print_fn(f"      from: {fmt_dim(ei[item])}")
            print_fn(f"      to:   {fmt_green(ef[item])}")


def collect_actions() -> list[tuple[str, str, str]]:
    """Collect all available actions from Kitty objects."""
    import inspect
    from kitty.window import Window
    from kitty.tabs import Tab
    from kitty.boss import Boss as BossClass

    action_order = {
        "win": "10",
        "tab": "20",
        "sc": "30",
        "lay": "40",
        "mk": "50",
        "cp": "60",
        "misc": "70",
        "debug": "80",
        "mouse": "zzz",
    }

    actions = []
    for klass in [Window, Tab, BossClass]:
        for name, method in klass.__dict__.items():
            if inspect.isfunction(method) and hasattr(method, "action_spec"):
                spec = method.action_spec
                group_key = action_order.get(spec.group, spec.group)
                # Extract first line of docstring
                doc = re.sub(r"^[\r\n ]*|[\r\n\.].*$", "", spec.doc or "", flags=re.S)
                actions.append((group_key, spec.group, name, doc))

    return [(g, n, d) for _, g, n, d in sorted(actions)]


def print_info_section(info: SystemInfo, opts: KittyOpts, print_fn: PrintFn) -> None:
    """Print system information section."""
    print_fn(fmt_title("System Information"))
    print_fn(fmt_green("Version:"), version(add_rev=True))
    print_fn(fmt_green("Hostname:"), info.hostname)
    print_fn(" ".join(info.uname))

    if is_macos:
        with suppress(Exception):
            import subprocess

            sw_vers = subprocess.check_output(["sw_vers"]).decode().strip()
            print_fn(sw_vers)

    # Detect Wayland with try/except fallback
    try:
        wayland = is_wayland()
    except Exception:
        wayland = "WAYLAND_DISPLAY" in os.environ

    print_fn(
        fmt_green("Running under:"),
        fmt_green("Wayland") if wayland else fmt_green("X11"),
    )
    print_fn(fmt_green("Frozen:"), "Yes" if getattr(sys, "frozen", False) else "No")

    print_fn(fmt_green("Paths:"))
    print_fn("  kitty:", os.path.realpath(kitty_exe()))
    print_fn("  base dir:", kitty_base_dir)
    print_fn("  extensions dir:", extensions_dir)
    print_fn("  system shell:", shell_path)

    if opts.config_paths:
        print_fn(fmt_green("Loaded config files:"))
        for path in opts.config_paths:
            print_fn("  ", path)

    if opts.config_overrides:
        print_fn(fmt_green("Loaded config overrides:"))
        for override in opts.config_overrides:
            print_fn("  ", override)


def print_config_section(
    opts: KittyOpts, default_opts: KittyOpts, print_fn: PrintFn
) -> None:
    """Print configuration options section."""
    print_fn(fmt_title("Configuration Options"))

    ignored_fields = {"keymap", "sequence_map", "mousemap", "map", "mouse_map"}
    changed_opts = [
        f
        for f in sorted(defaults._fields)
        if f not in ignored_fields and getattr(opts, f) != getattr(defaults, f)
    ]

    if not changed_opts:
        print_fn(fmt_dim("  (no changes from defaults)"))
        return

    max_len = max(map(len, changed_opts), default=20)
    fmt_str = f"{{:{max_len}s}}"

    colors_to_print = []

    for field_name in changed_opts:
        if field_name in ignored_fields:
            continue

        is_changed = field_name in changed_opts
        value = getattr(opts, field_name)

        if isinstance(value, dict):
            print_fn(fmt_yellow(fmt_str.format(field_name)) + ":")
            for key, val in sorted(value.items()):
                if field_name == "symbol_map":
                    print_fn(f"  U+{key[0]:04x}-U+{key[1]:04x} → {val}")
                elif field_name == "modify_font":
                    print_fn(f"  {val}")
                else:
                    print_fn(f"  {pformat(val)}")
        elif isinstance(value, Color):
            color_hex = color_as_sharp(value)
            colors_to_print.append(
                fmt_yellow(fmt_str.format(field_name))
                + " "
                + color_hex
                + " "
                + styled("  ", bg=value)
            )
        elif field_name == "kitty_mod":
            mod_str = "+".join(mod_to_names(value))
            print_fn(fmt_yellow(fmt_str.format(field_name)), mod_str, end="")
            if is_changed:
                print_fn(
                    " ",
                    fmt_dim(
                        f"(was {'+'.join(mod_to_names(getattr(defaults, field_name)))})"
                    ),
                )
            else:
                print_fn()
        else:
            print_fn(fmt_yellow(fmt_str.format(field_name)), str(value), end="")
            if is_changed:
                default_val = getattr(defaults, field_name)
                print_fn(" ", fmt_dim(f"(was {default_val})"))
            else:
                print_fn()

    if colors_to_print:
        print_fn(fmt_title("Colors:"))
        for color_line in sorted(colors_to_print):
            print_fn(color_line)


def print_colors_section(opts: KittyOpts, print_fn: PrintFn) -> None:
    """Print colors section with color swatches."""
    print_fn(fmt_title("Colors"))

    # Collect color attributes
    colors_to_print = []

    for field_name in sorted(defaults._fields):
        if "color" in field_name.lower():
            try:
                value = getattr(opts, field_name)
                if isinstance(value, Color):
                    color_hex = color_as_sharp(value)
                    colors_to_print.append(
                        fmt_yellow(field_name.ljust(25))
                        + " "
                        + color_hex.ljust(8)
                        + " "
                        + styled("  ", bg=value)
                    )
            except (AttributeError, TypeError):
                continue

    if colors_to_print:
        for line in sorted(colors_to_print):
            print_fn(line)
    else:
        print_fn(fmt_dim("  (no custom colors configured)"))


def print_env_section(info: SystemInfo, print_fn: PrintFn) -> None:
    """Print environment variables section."""
    print_fn(fmt_title("Environment Variables"))

    rows = [[k, v] for k, v in sorted(info.env_vars.items())]
    print_table(
        rows,
        [
            TableFormat(justify=justify_left, format_fn=fmt_yellow),
            TableFormat(format_fn=fmt_dim),
        ],
        print_fn,
    )


def print_actions_section(
    actions: list[tuple[str, str, str]], print_fn: PrintFn
) -> None:
    """Print available actions section."""
    print_fn(fmt_title("Available Actions"))

    rows = [[group, action, desc] for group, action, desc in actions]
    print_table(
        rows,
        [
            TableFormat(justify=justify_left, format_fn=fmt_blue),
            TableFormat(indent=2, format_fn=fmt_blue),
            TableFormat(indent=2, format_fn=fmt_dim),
        ],
        print_fn,
    )


def generate_config_output(opts: KittyOpts, config: ConfigOptions) -> str:
    """Generate complete configuration output string."""
    out = StringIO()
    print_fn = partial(print, file=out)

    # Collect system info and defaults
    info = get_system_info()
    default_opts = load_config()

    # Print requested sections (skip info/config in compact mode)
    if config.parts.get("info") and not config.compact:
        print_info_section(info, opts, print_fn)
        print_fn()

    if config.parts.get("config") and not config.compact:
        print_config_section(opts, default_opts, print_fn)
        print_fn()

    if config.parts.get("mouse"):
        if config.diff:
            compare_maps(
                "mouse",
                opts.mousemap,
                default_opts.mousemap,
                opts.kitty_mod,
                default_opts.kitty_mod,
                print_fn,
            )
        else:
            print_all_shortcuts(
                "mouse", opts.mousemap, opts.kitty_mod, print_fn, config.compact
            )
        if not config.compact:
            print_fn()

    if config.parts.get("keys"):
        # Extract keyboard keymaps
        final_keys = get_keyboard_keymaps(opts)

        if config.diff:
            initial_keys = get_keyboard_keymaps(default_opts)
            compare_maps(
                "keys",
                final_keys,
                initial_keys,
                opts.kitty_mod,
                default_opts.kitty_mod,
                print_fn,
            )
        else:
            # Show all shortcuts when not in diff mode
            print_all_shortcuts(
                "keys", final_keys, opts.kitty_mod, print_fn, config.compact
            )
        if not config.compact:
            print_fn()

    if config.parts.get("colors") and not config.compact:
        print_colors_section(opts, print_fn)
        print_fn()

    if config.parts.get("env") and not config.compact:
        print_env_section(info, print_fn)
        print_fn()

    if config.parts.get("actions") and not config.compact:
        actions = collect_actions()
        print_actions_section(actions, print_fn)

    output = out.getvalue()

    # Remove ANSI codes if plain output requested
    if config.plain:
        # Remove all ANSI escape sequences
        output = re.sub(
            r"\x1b\[[0-9;]*[a-zA-Z]|\x1b\][0-9]*;[^\x07]*\x07|\x1b\][0-9]*;[^\x1b]*\x1b\\",
            "",
            output,
        )

    return output


def print_help() -> None:
    """Print help message and exit."""
    help_text = """
Kitty Config Kitten - Display and manage Kitty configuration

Usage: kitty +kitten config [OPTIONS]

OPTIONS:
  -h, --help              Show this help message and exit

SECTIONS (control what to display):
  -i, --info              System information
  -c, --config            Configuration options
  -k, --keys              Keyboard shortcuts
  -m, --mouse             Mouse bindings
  -l, --colors            Color scheme
  -e, --env               Environment variables
  -t, --actions           Available actions

  --no-<section>          Hide a specific section (e.g., --no-info)
  -a, --all               Show all sections (default)
  --no-all                Show none (use with -k, -m, etc. to select)

OUTPUT MODES:
  --compact, --fzf        Compact format optimized for fzf piping
  --diff                  Show only changes from defaults
  -d, --debug             Show debug config (many sections, no empty)

DISPLAY OPTIONS:
  --plain, --plaintext    Remove ANSI colors from output
  --links                 Use hyperlinks (default: enabled)
  --no-links              Disable hyperlinks
  --deleted               Show deleted key bindings (default: enabled)
  --no-deleted            Hide deleted key bindings
  --empty, --unassigned   Show unassigned actions (default: enabled)
  --no-empty              Hide unassigned actions

EXAMPLES:
  kitty +kitten config -k              # Show keyboard shortcuts
  kitty +kitten config -k --fzf | fzf # Filter shortcuts with fzf
  kitty +kitten config --diff          # Show changes from defaults
  kitty +kitten config -a --plain      # Full config without colors
"""
    print(help_text)
    sys.exit(0)


def parse_args(args: list[str]) -> ConfigOptions:
    """Parse command-line arguments into ConfigOptions."""
    # Check for help first
    if "-h" in args or "--help" in args:
        print_help()

    config = ConfigOptions()

    for arg in args:
        match arg:
            case "-h" | "--help":
                print_help()
            case "-d" | "--diff":
                config.diff = True
            case "-a" | "--all":
                config = config.set_all_parts(True)
            case "--no-all":
                config = config.set_all_parts(False)
            case "--debug" | "--debug_config":
                config = config.set_debug_config(True)
            case "--compact" | "--fzf":
                config.compact = True
            case "--links":
                config.links = True
            case "--no-links":
                config.links = False
            case "--plain" | "--plaintext":
                config.plain = True
            case "--no-plain" | "--no-plaintext":
                config.plain = False
            case "--deleted":
                config.deleted = True
            case "--no-deleted":
                config.deleted = False
            case "--empty" | "--unassigned":
                config.empty = True
            case "--no-empty" | "--no-unassigned":
                config.empty = False
            # Handle section flags
            case "-i" | "--info":
                config.parts["info"] = True
            case "--no-info":
                config.parts["info"] = False
            case "-c" | "--config":
                config.parts["config"] = True
            case "--no-config":
                config.parts["config"] = False
            case "-k" | "--keys":
                config.parts["keys"] = True
            case "--no-keys":
                config.parts["keys"] = False
            case "-m" | "--mouse":
                config.parts["mouse"] = True
            case "--no-mouse":
                config.parts["mouse"] = False
            case "-l" | "--colors":
                config.parts["colors"] = True
            case "--no-colors":
                config.parts["colors"] = False
            case "-e" | "--env":
                config.parts["env"] = True
            case "--no-env":
                config.parts["env"] = False
            case "-t" | "--actions":
                config.parts["actions"] = True
            case "--no-actions":
                config.parts["actions"] = False

    config.resolve_parts()
    return config


def main(args: list[str]) -> None:
    """Main entry point for command-line execution."""
    try:
        config = parse_args(args)
        opts = create_default_opts()
        output = generate_config_output(opts, config)
        print(output, end="")
    except Exception as e:
        print(f"Error in config kitten: {e}", file=sys.stderr)
        import traceback

        traceback.print_exc()
        sys.exit(1)


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: Boss
) -> None:
    """Kitten UI handler for scrollback display."""
    config = parse_args(args)
    opts = fast_data_types.get_options()
    output = generate_config_output(opts, config)

    boss.display_scrollback(
        boss.active_window,
        output,
        title="Kitty Configuration",
        report_cursor=False,
    )


if __name__ == "__main__":
    main(sys.argv)
