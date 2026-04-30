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
echo "    /_/                                       "
echo -e "${RESET}${DIM} ⚡ The Ultimate AI Agent Stack Initialization ⚡${RESET}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { echo -e "${CYAN}❯${RESET} $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "${RED}✘${RESET} $1"; exit 1; }

prompt_yes_no() {
  while true; do
    echo -e -n "${CYAN}?${RESET} ${BOLD}$1${RESET} ${DIM}(Y/n)${RESET} "
    read -r yn
    case ${yn:-Y} in
      [Yy]* ) return 0 ;;
      [Nn]* ) return 1 ;;
      * ) echo -e "${RED}Please answer yes or no.${RESET}" ;;
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
  local cmd=("$@")

  echo -e -n "${CYAN}⠋${RESET} ${msg}..."

  local tmpfile
  tmpfile=$(mktemp)
  "${cmd[@]}" > "$tmpfile" 2>&1 &
  local pid=$!

  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf "\r${CYAN}%c${RESET} ${msg}..." "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
  done

  local exit_code=0
  wait "$pid" || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    printf "\r${GREEN}✔${RESET} ${msg}... ${GREEN}Done!${RESET}       \n"
  else
    printf "\r${RED}✘${RESET} ${msg}... ${RED}Failed!${RESET}     \n"
    cat "$tmpfile"
    rm -f "$tmpfile"
    exit 1
  fi
  rm -f "$tmpfile"
}

npm_installed() { npm list -g "$1" >/dev/null 2>&1; }

# ─── Check Dependencies ────────────────────────────────────────────────────
info "Checking system requirements..."
command -v node >/dev/null 2>&1 || error "Node.js is required. Install from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || error "npm is required."
command -v git  >/dev/null 2>&1 || error "Git is required."
echo ""

# ─── Install Core ──────────────────────────────────────────────────────────
info "Installing Core Engine..."
if npm_installed opencode-ai; then
  success "opencode-ai is already installed.\n"
else
  spinner_task "Installing opencode-ai" npm install -g opencode-ai
  echo ""
fi

# ─── Ecosystem Selection ───────────────────────────────────────────────────
info "Select Ecosystem Plugins (Optional but Recommended)"

INSTALL_AUTH=false
if npm_installed opencode-antigravity-auth; then
  success "opencode-antigravity-auth is already installed."
  INSTALL_AUTH=true
elif prompt_yes_no "Install opencode-antigravity-auth (Antigravity Connection)?"; then
  spinner_task "Installing opencode-antigravity-auth" npm install -g opencode-antigravity-auth
  INSTALL_AUTH=true
fi

if npm_installed tokscale; then
  success "tokscale is already installed."
elif prompt_yes_no "Install tokscale (Analytics & Cost Dashboard)?"; then
  spinner_task "Installing tokscale" npm install -g tokscale
fi

INSTALL_OMA=false
if npm_installed oh-my-opencode; then
  success "oh-my-openagent is already installed."
  INSTALL_OMA=true
elif prompt_yes_no "Install oh-my-openagent (Advanced Terminal Harness)?"; then
  spinner_task "Installing oh-my-openagent" npm install -g oh-my-opencode
  INSTALL_OMA=true
fi

INSTALL_REPOMIX=false
if npm_installed repomix; then
  success "repomix is already installed."
  INSTALL_REPOMIX=true
elif prompt_yes_no "Install repomix (Pack any repo into a single AI-readable file)?"; then
  spinner_task "Installing repomix" npm install -g repomix
  INSTALL_REPOMIX=true
fi
echo ""

# ─── Configuration ─────────────────────────────────────────────────────────
info "Applying stack configurations..."
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

if [ -f "$SCRIPT_DIR/configs/opencode.json" ]; then
  cp "$SCRIPT_DIR/configs/opencode.json" "$OPENCODE_CONFIG_DIR/opencode.json"
fi

if [ "$INSTALL_OMA" = true ] && [ -f "$SCRIPT_DIR/configs/oh-my-openagent.json" ]; then
  cp "$SCRIPT_DIR/configs/oh-my-openagent.json" "$OPENCODE_CONFIG_DIR/oh-my-openagent.json"
fi

success "Configs applied successfully.\n"

# ─── Interactive Authentication ─────────────────────────────────────────────
info "Provider Authentication"

touch .env

if prompt_yes_no "Enable GitHub Copilot Integration?"; then
  if opencode auth list 2>/dev/null | grep -i -q "github"; then
    success "GitHub is already authenticated.\n"
  else
    conda deactivate 2>/dev/null || true
    echo -e "${DIM}Opening browser for GitHub authentication...${RESET}"
    opencode auth login -p "github-copilot" || warn "GitHub auth skipped."
    echo ""
  fi
fi

if prompt_yes_no "Configure Google Gemini Pro?"; then
  echo -e "${DIM}Get your key here: https://aistudio.google.com/app/apikey${RESET}"
  KEY=$(prompt_input "Enter your Google API Key:")
  KEY=$(echo "$KEY" | head -n 1 | tr -d '\r\n')

  if grep -q "^GOOGLE_API_KEY=" .env; then
    sed "s|^GOOGLE_API_KEY=.*|GOOGLE_API_KEY=\"$KEY\"|" .env > .env.tmp && mv .env.tmp .env
  else
    echo "GOOGLE_API_KEY=\"$KEY\"" >> .env
  fi

  mkdir -p "$HOME/.config/opencode"
  touch "$HOME/.config/opencode/.env"
  if grep -q "^GOOGLE_API_KEY=" "$HOME/.config/opencode/.env"; then
    sed "s|^GOOGLE_API_KEY=.*|GOOGLE_API_KEY=\"$KEY\"|" "$HOME/.config/opencode/.env" > "$HOME/.config/opencode/.env.tmp" && mv "$HOME/.config/opencode/.env.tmp" "$HOME/.config/opencode/.env"
  else
    echo "GOOGLE_API_KEY=\"$KEY\"" >> "$HOME/.config/opencode/.env"
  fi

  success "Google key saved (local and global)\n"
else
  node -e "const fs=require('fs'); const p=process.env.HOME+'/.config/opencode/opencode.json'; if(fs.existsSync(p)){const d=JSON.parse(fs.readFileSync(p)); if(d.provider && d.provider.google && d.provider.google.models) { delete d.provider.google.models['gemini-2.5-pro']; delete d.provider.google.models['gemini-2.5-flash']; if(Object.keys(d.provider.google.models).length === 0) { delete d.provider.google; } fs.writeFileSync(p, JSON.stringify(d, null, 2)); }}"
fi

if prompt_yes_no "Configure OpenRouter (200+ Models)?"; then
  echo -e "${DIM}Get your key here: https://openrouter.ai/settings/keys${RESET}"
  KEY=$(prompt_input "Enter your OpenRouter API Key:")
  KEY=$(echo "$KEY" | head -n 1 | tr -d '\r\n')

  if grep -q "^OPENROUTER_API_KEY=" .env; then
    sed "s|^OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=\"$KEY\"|" .env > .env.tmp && mv .env.tmp .env
  else
    echo "OPENROUTER_API_KEY=\"$KEY\"" >> .env
  fi

  mkdir -p "$HOME/.config/opencode"
  touch "$HOME/.config/opencode/.env"
  if grep -q "^OPENROUTER_API_KEY=" "$HOME/.config/opencode/.env"; then
    sed "s|^OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=\"$KEY\"|" "$HOME/.config/opencode/.env" > "$HOME/.config/opencode/.env.tmp" && mv "$HOME/.config/opencode/.env.tmp" "$HOME/.config/opencode/.env"
  else
    echo "OPENROUTER_API_KEY=\"$KEY\"" >> "$HOME/.config/opencode/.env"
  fi

  success "OpenRouter key saved (local and global)\n"
else
  node -e "const fs=require('fs'); const p=process.env.HOME+'/.config/opencode/opencode.json'; if(fs.existsSync(p)){const d=JSON.parse(fs.readFileSync(p)); if(d.provider && d.provider.openrouter) { delete d.provider.openrouter; fs.writeFileSync(p, JSON.stringify(d, null, 2)); }}"
fi

if [ "$INSTALL_AUTH" = true ]; then
  if opencode auth list 2>/dev/null | grep -i -q "google"; then
    success "Antigravity Auth is already configured.\n"
  else
    info "Initializing Antigravity Auth Layer..."
    conda deactivate 2>/dev/null || true
    echo -e "${DIM}Opening browser for Google Antigravity authentication...${RESET}"
    opencode auth login -p google -m "OAuth with Google (Antigravity)" || warn "Antigravity Auth skipped."
    echo ""
  fi
  if [ -z "$GOOGLE_API_KEY" ]; then
    touch "$HOME/.config/opencode/.env"
    if ! grep -q "^GOOGLE_GENERATIVE_AI_API_KEY=" "$HOME/.config/opencode/.env" 2>/dev/null; then
      echo 'GOOGLE_GENERATIVE_AI_API_KEY="antigravity-dummy-key"' >> "$HOME/.config/opencode/.env"
    fi
  fi
else
  node -e "const fs=require('fs'); const p=process.env.HOME+'/.config/opencode/opencode.json'; if(fs.existsSync(p)){const d=JSON.parse(fs.readFileSync(p)); if(d.provider && d.provider.google && d.provider.google.models) { delete d.provider.google.models['antigravity-gemini-3-pro']; delete d.provider.google.models['antigravity-gemini-3-flash']; delete d.provider.google.models['antigravity-claude-sonnet-4-6']; delete d.provider.google.models['antigravity-claude-opus-4-6-thinking']; if(Object.keys(d.provider.google.models).length === 0) { delete d.provider.google; } fs.writeFileSync(p, JSON.stringify(d, null, 2)); }}"
fi

# ─── Final Auth Check ──────────────────────────────────────────────────────
echo -e "\n${BLUE}${BOLD}▶ Final Auth Status Check${RESET}"

set -a
[ -f .env ] && source .env
set +a

ACTIVE_PROVIDERS=0

if opencode auth list 2>/dev/null | grep -i -q "github"; then
  success "GitHub Copilot  — active"
  ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
else
  warn "GitHub Copilot  — skipped (optional)"
fi

if [ -n "$GOOGLE_API_KEY" ]; then
  success "Google Pro      — active"
  ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
else
  warn "Google Pro      — skipped (optional)"
fi

if [ -n "$OPENROUTER_API_KEY" ]; then
  success "OpenRouter      — active"
  ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
else
  warn "OpenRouter      — skipped (optional)"
fi

if npm_installed opencode-antigravity-auth; then
  if opencode auth list 2>/dev/null | grep -i -q "google"; then
    success "Antigravity Auth — active"
    ACTIVE_PROVIDERS=$((ACTIVE_PROVIDERS + 1))
  else
    warn "Antigravity Auth — not active (run 'opencode auth login')"
  fi
else
  warn "Antigravity Auth — skipped (not installed)"
fi

if npm_installed repomix; then
  success "repomix         — active"
else
  warn "repomix         — skipped (optional)"
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