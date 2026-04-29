#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — Interactive Setup
# =============================================================================

set -e

BLUE='\033[38;2;0;102;255m'
CYAN='\033[38;2;0;210;255m'
GREEN='\033[38;2;0;255;157m'
YELLOW='\033[38;2;255;184;0m'
RED='\033[38;2;255;0;85m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

clear

echo -e "${BLUE}${BOLD}"
echo "                                         __   "
echo "  ____  ____  ___  ____  _________  ____/ /__ "
echo " / __ \/ __ \/ _ \/ __ \/ ___/ __ \/ __  / _ \\"
echo "/ /_/ / /_/ /  __/ / / / /__/ /_/ / /_/ /  __/"
echo "\____/ .___/\___/_/ /_/\___/\____/\__,_/\___/ "
echo "    /_/                                        "
echo -e "${RESET}${DIM} ⚡ The Ultimate AI Agent Stack Initialization ⚡${RESET}\n"

info()    { echo -e "${CYAN}❯${RESET} $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "${RED}✘${RESET} $1"; exit 1; }

prompt_yes_no() {
  while true; do
    echo -e -n "${CYAN}?${RESET} ${BOLD}$1${RESET} ${DIM}(Y/n)${RESET} "
    read -r yn
    case ${yn:-Y} in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo -e "${RED}Please answer yes or no.${RESET}" ;;
    esac
  done
}

prompt_input() {
  echo -e -n "${CYAN}?${RESET} ${BOLD}$1${RESET} " >&2
  read -r val
  echo "$val"
}

spinner_task() {
  local msg="$1"
  shift
  local tmpfile
  tmpfile=$(mktemp)
  "$@" > "$tmpfile" 2>&1 &
  local pid=$!
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  printf "${CYAN}⠋${RESET} %s..." "$msg"
  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf "\r${CYAN}%c${RESET} %s..." "$spinstr" "$msg"
    spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
  done
  local exit_code=0
  wait "$pid" || exit_code=$?
  if [ $exit_code -eq 0 ]; then
    printf "\r${GREEN}✔${RESET} %s... ${GREEN}Done!${RESET}       \n" "$msg"
  else
    printf "\r${RED}✘${RESET} %s... ${RED}Failed!${RESET}     \n" "$msg"
    cat "$tmpfile"
    rm -f "$tmpfile"
    exit 1
  fi
  rm -f "$tmpfile"
}

npm_installed() { npm list -g "$1" >/dev/null 2>&1; }

set_env_key() {
  local file="$1" key="$2" val="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=\"${val}\"|" "$file" && rm -f "${file}.bak"
  else
    echo "${key}=\"${val}\"" >> "$file"
  fi
}

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_ENV="$OPENCODE_CONFIG_DIR/.env"
mkdir -p "$OPENCODE_CONFIG_DIR"

set -a
[ -f "$OPENCODE_ENV" ] && source "$OPENCODE_ENV"
set +a

# ─── Check Dependencies ───────────────────────────────────────────────────
info "Checking system requirements..."
command -v node >/dev/null 2>&1 || error "Node.js is required. Install from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || error "npm is required."
command -v git  >/dev/null 2>&1 || error "Git is required."
success "Requirements met.\n"

# ─── opencode ────────────────────────────────────────────────────────────
info "Core Engine..."
if npm_installed opencode-ai; then
  success "opencode-ai is already installed.\n"
else
  spinner_task "Installing opencode-ai" npm install -g opencode-ai
  echo ""
fi

# ─── Plugins ─────────────────────────────────────────────────────────────
info "Select Ecosystem Plugins"

INSTALL_AUTH=false
if npm_installed opencode-antigravity-auth; then
  success "opencode-antigravity-auth is already installed."
  INSTALL_AUTH=true
elif prompt_yes_no "Install opencode-antigravity-auth (free Gemini models via Google IDE auth)?"; then
  spinner_task "Installing opencode-antigravity-auth" npm install -g opencode-antigravity-auth
  INSTALL_AUTH=true
fi

if npm_installed tokscale; then
  success "tokscale is already installed."
elif prompt_yes_no "Install tokscale (token usage dashboard)?"; then
  spinner_task "Installing tokscale" npm install -g tokscale
fi

INSTALL_OMA=false
if npm_installed oh-my-opencode; then
  success "oh-my-openagent is already installed."
  INSTALL_OMA=true
elif prompt_yes_no "Install oh-my-openagent (multi-agent harness)?"; then
  spinner_task "Installing oh-my-openagent" npm install -g oh-my-opencode
  INSTALL_OMA=true
fi

INSTALL_REPOMIX=false
if npm_installed repomix; then
  success "repomix is already installed."
  INSTALL_REPOMIX=true
elif prompt_yes_no "Install repomix (pack repo into single AI-readable file)?"; then
  spinner_task "Installing repomix" npm install -g repomix
  INSTALL_REPOMIX=true
fi
echo ""

# ─── Provider Authentication ──────────────────────────────────────────────
info "Provider Authentication"

INSTALL_COPILOT=false
if opencode auth list 2>/dev/null | grep -i -q "github"; then
  success "GitHub Copilot — already active."
  INSTALL_COPILOT=true
elif prompt_yes_no "Enable GitHub Copilot?"; then
  conda deactivate 2>/dev/null || true
  echo -e "${DIM}Opening browser for GitHub authentication...${RESET}"
  opencode auth login -p "github-copilot" || warn "GitHub auth skipped."
  INSTALL_COPILOT=true
  echo ""
fi

INSTALL_GOOGLE=false
if [ -n "$GOOGLE_API_KEY" ]; then
  success "Google Gemini — already configured."
  INSTALL_GOOGLE=true
  if prompt_yes_no "Update your Google API Key?"; then
    echo -e "${DIM}Get your key: https://aistudio.google.com/app/apikey${RESET}"
    KEY=$(prompt_input "Enter your new Google API Key:")
    KEY=$(echo "$KEY" | head -n 1 | tr -d '\r\n')
    set_env_key "$OPENCODE_ENV" "GOOGLE_API_KEY" "$KEY"
    set_env_key "$OPENCODE_ENV" "GOOGLE_GENERATIVE_AI_API_KEY" "$KEY"
    success "Google key updated.\n"
  fi
elif prompt_yes_no "Configure Google Gemini?"; then
  echo -e "${DIM}Get your key: https://aistudio.google.com/app/apikey${RESET}"
  KEY=$(prompt_input "Enter your Google API Key:")
  KEY=$(echo "$KEY" | head -n 1 | tr -d '\r\n')
  set_env_key "$OPENCODE_ENV" "GOOGLE_API_KEY" "$KEY"
  set_env_key "$OPENCODE_ENV" "GOOGLE_GENERATIVE_AI_API_KEY" "$KEY"
  INSTALL_GOOGLE=true
  success "Google key saved.\n"
fi

INSTALL_OPENROUTER=false
if [ -n "$OPENROUTER_API_KEY" ]; then
  success "OpenRouter — already configured."
  INSTALL_OPENROUTER=true
  if prompt_yes_no "Update your OpenRouter API Key?"; then
    echo -e "${DIM}Get your key: https://openrouter.ai/settings/keys${RESET}"
    KEY=$(prompt_input "Enter your new OpenRouter API Key:")
    KEY=$(echo "$KEY" | head -n 1 | tr -d '\r\n')
    set_env_key "$OPENCODE_ENV" "OPENROUTER_API_KEY" "$KEY"
    success "OpenRouter key updated.\n"
  fi
elif prompt_yes_no "Configure OpenRouter (200+ models)?"; then
  echo -e "${DIM}Get your key: https://openrouter.ai/settings/keys${RESET}"
  KEY=$(prompt_input "Enter your OpenRouter API Key:")
  KEY=$(echo "$KEY" | head -n 1 | tr -d '\r\n')
  set_env_key "$OPENCODE_ENV" "OPENROUTER_API_KEY" "$KEY"
  INSTALL_OPENROUTER=true
  success "OpenRouter key saved.\n"
fi

if [ "$INSTALL_AUTH" = true ]; then
  if opencode auth list 2>/dev/null | grep -i -q "google"; then
    success "Antigravity Auth — already active.\n"
  else
    info "Initializing Antigravity Auth..."
    conda deactivate 2>/dev/null || true
    echo -e "${DIM}Opening browser for Google authentication...${RESET}"
    opencode auth login -p google -m "OAuth with Google (Antigravity)" || warn "Antigravity auth skipped."
    echo ""
  fi
fi
echo ""

# ─── opencode.json ───────────────────────────────────────────────────────
info "Configuring opencode.json..."
OPENCODE_JSON="$OPENCODE_CONFIG_DIR/opencode.json"

[ -f "$OPENCODE_JSON" ] || echo '{}' > "$OPENCODE_JSON"

INSTALL_OMA="$INSTALL_OMA" \
INSTALL_AUTH="$INSTALL_AUTH" \
INSTALL_REPOMIX="$INSTALL_REPOMIX" \
INSTALL_OPENROUTER="$INSTALL_OPENROUTER" \
node -e "
  const fs = require('fs');
  const cfg = JSON.parse(fs.readFileSync('$OPENCODE_JSON', 'utf8'));

  const plugins = new Set(cfg.plugin || []);
  if (process.env.INSTALL_OMA === 'true')   plugins.add('oh-my-openagent');
  if (process.env.INSTALL_AUTH === 'true')  plugins.add('opencode-antigravity-auth@latest');
  cfg.plugin = [...plugins];

  cfg.provider = cfg.provider || {};
  if (process.env.INSTALL_OPENROUTER === 'true') {
    cfg.provider.openrouter = { apiKey: '\${env:OPENROUTER_API_KEY}' };
  }

  cfg.instructions = [
    'Think Before Coding: State assumptions explicitly. Present multiple interpretations instead of picking silently. Push back when warranted. Stop and ask if confused.',
    'Simplicity First: Write the minimum code that solves the problem. No speculative features, abstractions, or error handling for impossible scenarios.',
    'Surgical Changes: Touch only what you must. Do not improve adjacent code, comments, or formatting. Clean up only your own mess.',
    'Goal-Driven Execution: Transform tasks into verifiable goals. State a brief verification plan for multi-step tasks.',
    ...(process.env.INSTALL_REPOMIX === 'true'
      ? ['Codebase Context: Use repomix output when available for full codebase awareness.']
      : [])
  ];

  fs.writeFileSync('$OPENCODE_JSON', JSON.stringify(cfg, null, 2));
"
success "opencode.json configured.\n"

# ─── oh-my-openagent.json ────────────────────────────────────────────────
if [ "$INSTALL_OMA" = true ]; then
  info "Configuring oh-my-openagent.json..."
  OMA_JSON="$OPENCODE_CONFIG_DIR/oh-my-openagent.json"
  if [ ! -f "$OMA_JSON" ]; then
    cat > "$OMA_JSON" <<'EOF'
{
  "categories": {
    "quick":              { "model": "github-copilot/gpt-4.1-mini" },
    "unspecified-low":    { "model": "github-copilot/gpt-4.1-mini" },
    "unspecified-high":   { "model": "github-copilot/gpt-4.1" },
    "visual-engineering": { "model": "github-copilot/claude-haiku-4.5" },
    "artistry":           { "model": "github-copilot/gemini-2.5-pro" },
    "ultrabrain":         { "model": "github-copilot/gpt-4.1" },
    "deep":               { "model": "github-copilot/gpt-4.1" }
  }
}
EOF
    success "oh-my-openagent.json created.\n"
  else
    success "oh-my-openagent.json already exists, skipping.\n"
  fi
fi

# ─── Final Status ─────────────────────────────────────────────────────────
echo -e "\n${BLUE}${BOLD}▶ Final Status${RESET}"

set -a
[ -f "$OPENCODE_ENV" ] && source "$OPENCODE_ENV"
set +a

ACTIVE_PROVIDERS=0

if opencode auth list 2>/dev/null | grep -i -q "github"; then
  success "GitHub Copilot   — active"
  ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
else
  warn "GitHub Copilot   — skipped (optional)"
fi

if [ -n "$GOOGLE_API_KEY" ]; then
  success "Google Gemini    — active"
  ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
else
  warn "Google Gemini    — skipped (optional)"
fi

if [ -n "$OPENROUTER_API_KEY" ]; then
  success "OpenRouter       — active"
  ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
else
  warn "OpenRouter       — skipped (optional)"
fi

if [ "$INSTALL_AUTH" = true ]; then
  if opencode auth list 2>/dev/null | grep -i -q "google"; then
    success "Antigravity Auth — active"
    ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
  else
    warn "Antigravity Auth — not active (run: opencode auth login)"
  fi
else
  warn "Antigravity Auth — skipped (not installed)"
fi

echo ""
if [ "$ACTIVE_PROVIDERS" -gt 0 ]; then
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║   ✔  Setup complete! You're ready.   ║${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${RESET}"
  echo -e "Run ${CYAN}opencode${RESET} to start.\n"
else
  echo -e "${BOLD}${YELLOW}⚠ Setup finished but no providers active. Run setup again to configure one.${RESET}\n"
fi