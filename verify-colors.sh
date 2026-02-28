#!/usr/bin/env zsh
# Color Configuration Verification Script
# Tests all tools to ensure theme-agnostic color configuration is working
#
# Usage: zsh ./verify-colors.sh
# Location: Should be run from dotfiles root

set -euo pipefail

echo "🎨 Color Configuration Verification"
echo "===================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track results
PASSED=0
FAILED=0
WARNINGS=0

# Test function
test_config() {
    local tool=$1
    local env_var=$2
    local description=$3

    echo -n "Testing $tool... "

    if eval "[ -n \"\${$env_var:-}\" ]"; then
        echo -e "${GREEN}✓${NC} $description"
        echo "  Value: $(eval "echo \$$env_var" | head -c 80)"
        echo ""
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} $description (not set)"
        echo ""
        FAILED=$((FAILED + 1))
    fi
}

test_command() {
    local tool=$1
    local expected_output=$2

    echo -n "Testing $tool command... "

    if command -v "$tool" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $tool is installed"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} $tool is not installed (optional)"
        WARNINGS=$((WARNINGS + 1))
    fi
    echo ""
}

# ============================================================================
# Environment Variables Check
# ============================================================================
echo -e "${BLUE}[1/4] ENVIRONMENT VARIABLES${NC}"
echo "-----------------------------------"

test_config "bat" "BAT_THEME" "BAT_THEME should be 'ansi'"
test_config "fzf" "FZF_DEFAULT_OPTS" "FZF_DEFAULT_OPTS color spec"
test_config "ripgrep" "RIPGREP_CONFIG_PATH" "RIPGREP_CONFIG_PATH should point to .ripgreprc"
test_config "eza" "EZA_COLORS" "EZA_COLORS should be defined"
test_config "jq" "JQ_COLORS" "JQ_COLORS should be defined"
test_config "terminal" "COLORTERM" "COLORTERM should support truecolor"

echo ""
echo -e "${BLUE}[2/4] TERMINAL CONFIGURATION${NC}"
echo "-----------------------------------"

echo -n "TERM variable: "
if [ -n "${TERM:-}" ]; then
    echo -e "${GREEN}✓${NC} $TERM"
else
    echo -e "${RED}✗${NC} Not set"
fi

echo -n "Color support: "
if [ -n "${COLORTERM:-}" ]; then
    echo -e "${GREEN}✓${NC} $COLORTERM"
else
    echo -e "${YELLOW}⚠${NC} May not support 256 colors"
fi
echo ""

# ============================================================================
# Installed Tools Check
# ============================================================================
echo -e "${BLUE}[3/4] INSTALLED TOOLS${NC}"
echo "-----------------------------------"

test_command "bat" ""
test_command "fzf" ""
test_command "rg" ""
test_command "eza" ""
test_command "jq" ""
test_command "glow" ""
test_command "delta" ""
test_command "tmux" ""

# ============================================================================
# Configuration Files Check
# ============================================================================
echo -e "${BLUE}[4/4] CONFIGURATION FILES${NC}"
echo "-----------------------------------"

echo -n "Checking ~/.theme-colors... "
if [ -f "$HOME/.theme-colors" ]; then
    echo -e "${GREEN}✓${NC} File exists"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} File not found"
    FAILED=$((FAILED + 1))
fi

echo -n "Checking ~/.ripgreprc... "
if [ -f "$HOME/.ripgreprc" ]; then
    echo -e "${GREEN}✓${NC} File exists"
    if grep -q "palette:yes" "$HOME/.ripgreprc" 2>/dev/null; then
        echo "  Contains palette configuration ${GREEN}✓${NC}"
    fi
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} File not found (optional)"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "Checking ~/.dircolors... "
if [ -f "$HOME/.dircolors" ]; then
    echo -e "${GREEN}✓${NC} File exists"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} File not found (optional)"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "Checking ~/.zshenv loads theme-colors... "
if grep -q "source.*\.theme-colors" "$HOME/.zshenv" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} Not sourced"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "===================================="
echo -e "${GREEN}Passed:${NC}  $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC}  $FAILED"
echo ""

# ============================================================================
# Recommendations
# ============================================================================
echo -e "${BLUE}RECOMMENDATIONS${NC}"
echo "-----------------------------------"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}⚠${NC} Fix failed items above"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} Optional tools not installed (no action needed)"
    echo "   These tools are optional and have graceful fallbacks"
fi

echo ""
echo -e "${BLUE}NEXT STEPS${NC}"
echo "-----------------------------------"
echo "1. Test individual tools:"
echo "   - bat: echo 'print(123)' | bat -l python"
echo "   - fzf: echo -e 'a\\nb\\nc' | fzf"
echo "   - rg: rg --color always 'pattern' ."
echo ""
echo "2. Verify colors look good with your terminal theme"
echo ""
echo "3. Check COLOR_CONFLICT_RESOLUTION.md for detailed troubleshooting"
echo ""
