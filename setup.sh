#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — One-Shot Setup Script
# =============================================================================
# Usage: ./setup.sh
# =============================================================================

set -e

# Colors
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

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║   opencode Ultimate Stack — Setup v1.0   ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Check Dependencies ────────────────────────────────────────────────────
step "Checking system dependencies"

command -v node >/dev/null 2>&1 || err "Node.js not found. Install from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || err "npm not found"
command -v git  >/dev/null 2>&1 || err "Git not found"
command -v curl >/dev/null 2>&1 || err "curl not found"

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  err "Node.js 18+ required (found v$NODE_VERSION)"
fi

ok "Dependencies OK (Node $(node -v), npm $(npm -v))"

# ─── Install opencode ──────────────────────────────────────────────────────
step "Installing opencode"

if command -v opencode >/dev/null 2>&1; then
  warn "opencode already installed: $(opencode --version)"
else
  npm install -g opencode-ai
  ok "opencode installed: $(opencode --version)"
fi

# ─── Install opencode-antigravity-auth ────────────────────────────────────
step "Installing opencode-antigravity-auth"

if command -v opencode-antigravity-auth >/dev/null 2>&1; then
  warn "antigravity-auth already installed"
else
  npm install -g opencode-antigravity-auth
  ok "opencode-antigravity-auth installed"
fi

# ─── Install oh-my-openagent ──────────────────────────────────────────────
step "Installing oh-my-openagent"

if [ -d "$HOME/.oh-my-openagent" ]; then
  warn "oh-my-openagent already installed at ~/.oh-my-openagent"
else
  curl -fsSL https://raw.githubusercontent.com/oh-my-openagent/install/main/install.sh | bash
  ok "oh-my-openagent installed"
fi

# Copy oh-my-openagent config
if [ -f "configs/oh-my-openagent/.openagentrc" ]; then
  cp configs/oh-my-openagent/.openagentrc ~/.openagentrc
  ok "oh-my-openagent config applied"
fi

# Copy theme
if [ -f "configs/oh-my-openagent/themes/antigravity.theme" ]; then
  mkdir -p ~/.openagent/themes
  cp configs/oh-my-openagent/themes/antigravity.theme ~/.openagent/themes/
  ok "antigravity theme installed"
fi

# ─── Setup opencode config ─────────────────────────────────────────────────
step "Configuring opencode"

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

if [ ! -f "$OPENCODE_CONFIG_DIR/config.json" ]; then
  cp configs/opencode.json "$OPENCODE_CONFIG_DIR/config.json"
  ok "opencode config copied to $OPENCODE_CONFIG_DIR/config.json"
else
  warn "opencode config already exists — skipping (edit manually if needed)"
fi

# ─── Environment Variables ─────────────────────────────────────────────────
step "Setting up environment variables"

if [ ! -f ".env" ]; then
  cp configs/openrouter.env .env
  warn "Created .env from template — FILL IN your API keys!"
else
  warn ".env already exists — skipping"
fi

# Load .env
set -a
# shellcheck disable=SC1091
[ -f .env ] && source .env
set +a

# ─── GitHub Copilot Auth ───────────────────────────────────────────────────
step "GitHub Copilot authentication"
echo "   Opening GitHub auth in your browser..."
echo "   Make sure your account has the Student Pack activated."
echo ""
read -r -p "   Press ENTER to authenticate with GitHub (or Ctrl+C to skip)..."
opencode auth github || warn "GitHub auth skipped or failed — re-run: opencode auth github"

# ─── Google Pro Auth ──────────────────────────────────────────────────────
step "Google Pro (Gemini) setup"

if [ -z "$GOOGLE_API_KEY" ]; then
  echo ""
  warn "GOOGLE_API_KEY not set in .env"
  echo "   1. Go to: https://aistudio.google.com/apikey"
  echo "   2. Create a key and paste it in your .env file"
  echo "   3. Re-run this script or export it manually"
else
  ok "GOOGLE_API_KEY found"
fi

# ─── OpenRouter Auth ──────────────────────────────────────────────────────
step "OpenRouter setup"

if [ -z "$OPENROUTER_API_KEY" ]; then
  warn "OPENROUTER_API_KEY not set in .env"
  echo "   Get your key at: https://openrouter.ai/keys"
else
  ok "OPENROUTER_API_KEY found"
fi

# ─── Antigravity Auth Init ─────────────────────────────────────────────────
step "Initializing opencode-antigravity-auth"
opencode-antigravity-auth init || warn "Antigravity auth init failed — check individual provider auth"

# ─── Final Verification ────────────────────────────────────────────────────
step "Running auth check"
bash scripts/auth-check.sh || warn "Some providers may not be fully authenticated"

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║   ✔  Setup complete! Happy coding.   ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${RESET}"
echo ""
echo -e "Run ${CYAN}opencode${RESET} to start."
echo -e "Switch models with ${CYAN}./scripts/model-switcher.sh${RESET}"
echo ""
