#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — The Only Script You Need
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

step() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
err()  { echo -e "${RED}✘ $1${RESET}"; exit 1; }
fail() { echo -e "${RED}✘ $1${RESET}"; }

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║   opencode Ultimate Stack — Zero Setup   ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Check Dependencies ────────────────────────────────────────────────────
step "Checking system dependencies"
command -v node >/dev/null 2>&1 || err "Node.js not found. Install from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || err "npm not found"
command -v git  >/dev/null 2>&1 || err "Git not found"
command -v curl >/dev/null 2>&1 || err "curl not found"

ok "Dependencies OK"

# ─── Install Packages ──────────────────────────────────────────────────────
step "Installing Core Packages"

for pkg in "opencode-ai" "opencode-antigravity-auth"; do
  if npm list -g "$pkg" >/dev/null 2>&1; then
    ok "$pkg already installed"
  else
    npm install -g "$pkg"
    ok "$pkg installed"
  fi
done

if [ -d "$HOME/.oh-my-openagent" ]; then
  ok "oh-my-openagent already installed"
else
  npx oh-my-openagent install
  ok "oh-my-openagent installed"
fi

# ─── Configuration ─────────────────────────────────────────────────────────
step "Applying Configurations"

# Opencode config
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"
if [ -f "configs/opencode.json" ]; then
  cp configs/opencode.json "$OPENCODE_CONFIG_DIR/opencode.json"
  ok "opencode global config applied (~/.config/opencode/opencode.json)"
fi

# Oh My OpenAgent config
OMA_CONFIG_DIR="$HOME/.oh-my-openagent"
if [ -d "$OMA_CONFIG_DIR" ]; then
  mkdir -p "$OMA_CONFIG_DIR/themes"
  cp configs/oh-my-openagent/.openagentrc "$OMA_CONFIG_DIR/" 2>/dev/null || true
  cp configs/oh-my-openagent/themes/antigravity.theme "$OMA_CONFIG_DIR/themes/" 2>/dev/null || true
  ok "oh-my-openagent configs and theme applied"
fi

set -a
# shellcheck disable=SC1091
[ -f .env ] && source .env
set +a

# ─── Authentication ────────────────────────────────────────────────────────
step "GitHub Copilot Auth"
if opencode auth status github 2>/dev/null | grep -q "authenticated"; then
  ok "GitHub already authenticated"
else
  echo "Opening GitHub auth..."
  opencode auth github || warn "GitHub auth failed/skipped"
fi

step "Initializing Antigravity Auth"
opencode-antigravity-auth init || warn "Antigravity init failed"

# ─── Auth Check ────────────────────────────────────────────────────────────
if [ -x "scripts/auth-check.sh" ]; then
  ./scripts/auth-check.sh
else
  warn "Auth check script not found or not executable"
fi
