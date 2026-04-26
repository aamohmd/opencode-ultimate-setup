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
  curl -fsSL https://raw.githubusercontent.com/oh-my-openagent/install/main/install.sh | bash
  ok "oh-my-openagent installed"
fi

# ─── Configuration ─────────────────────────────────────────────────────────
step "Applying Configurations"

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

if [ -f "opencode.json" ]; then
  cp opencode.json "$OPENCODE_CONFIG_DIR/opencode.json"
  ok "opencode global config applied (~/.config/opencode/opencode.json)"
else
  warn "opencode.json not found in the current directory"
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

step "Google Pro Auth"
if [ -z "$GOOGLE_API_KEY" ]; then
  warn "GOOGLE_API_KEY not set in .env"
else
  ok "GOOGLE_API_KEY found"
fi

step "OpenRouter Auth"
if [ -z "$OPENROUTER_API_KEY" ]; then
  warn "OPENROUTER_API_KEY not set in .env"
else
  ok "OPENROUTER_API_KEY found"
fi

step "Initializing Antigravity Auth"
opencode-antigravity-auth init || warn "Antigravity init failed"

# ─── Auth Check ────────────────────────────────────────────────────────────
step "Final Auth Status Check"

ACTIVE_PROVIDERS=0

if opencode auth status github 2>/dev/null | grep -q "authenticated"; then
  ok "GitHub Copilot  — active"
  ((ACTIVE_PROVIDERS++))
else
  warn "GitHub Copilot  — skipped (optional)"
fi

if [ -n "$GOOGLE_API_KEY" ]; then
  ok "Google Pro      — active"
  ((ACTIVE_PROVIDERS++))
else
  warn "Google Pro      — skipped (optional)"
fi

if [ -n "$OPENROUTER_API_KEY" ]; then
  ok "OpenRouter      — active"
  ((ACTIVE_PROVIDERS++))
else
  warn "OpenRouter      — skipped (optional)"
fi

if opencode-antigravity-auth status 2>/dev/null | grep -q "active"; then
  ok "Antigravity Auth — active"
else
  warn "Antigravity Auth — not active (run opencode-antigravity-auth init)"
fi

echo ""
if [ "$ACTIVE_PROVIDERS" -gt 0 ]; then
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║   ✔  Setup complete! You're ready.   ║${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${RESET}"
  echo -e "Run ${CYAN}opencode${RESET} to start."
else
  echo -e "${BOLD}${YELLOW}⚠ Setup finished, but no providers are active. You will need to set up at least one.${RESET}"
fi
echo ""
