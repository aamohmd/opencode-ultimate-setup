#!/usr/bin/env bash
# Auth Check — verifies all providers are authenticated

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
fail() { echo -e "${RED}✘ $1${RESET}"; }

echo "─── Auth Status Check ──────────────────────"

# GitHub Copilot
if opencode auth status github 2>/dev/null | grep -q "authenticated"; then
  ok "GitHub Copilot  — authenticated"
else
  fail "GitHub Copilot  — NOT authenticated (run: opencode auth github)"
fi

# Google Pro
if [ -n "$GOOGLE_API_KEY" ]; then
  ok "Google Pro      — API key set"
else
  fail "Google Pro      — GOOGLE_API_KEY not set"
fi

# OpenRouter
if [ -n "$OPENROUTER_API_KEY" ]; then
  ok "OpenRouter      — API key set"
else
  fail "OpenRouter      — OPENROUTER_API_KEY not set"
fi

# Antigravity Auth
if opencode-antigravity-auth status 2>/dev/null | grep -q "active"; then
  ok "Antigravity Auth — active"
else
  warn "Antigravity Auth — run: opencode-antigravity-auth init"
fi

echo "────────────────────────────────────────────"
