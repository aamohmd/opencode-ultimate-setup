#!/usr/bin/env bash
# =============================================================================
# Auth Verification Script
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[38;2;0;102;255m'
CYAN='\033[38;2;0;210;255m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
step() { echo -e "\n${BLUE}${BOLD}▶ $1${RESET}"; }

set -a
[ -f .env ] && source .env
set +a

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
