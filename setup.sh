#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — Interactive Setup
# =============================================================================

set -e

# --- Colors & Styles ---
BLUE='\033[38;2;0;102;255m'
CYAN='\033[38;2;0;210;255m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# --- UI Helpers ---
clear

echo -e "${BLUE}${BOLD}"
echo "                                         __   "
echo "  ____  ____  ___  ____  _________  ____/ /__ "
echo " / __ \/ __ \/ _ \/ __ \/ ___/ __ \/ __  / _ \\"
echo "/ /_/ / /_/ /  __/ / / / /__/ /_/ / /_/ /  __/"
echo "\____/ .___/\___/_/ /_/\___/\____/\__,_/\___/ "
echo "    /_/                                       "
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
      [Yy]* ) return 0 ;;
      [Nn]* ) return 1 ;;
      * ) echo -e "${RED}Please answer yes or no.${RESET}" ;;
    esac
  done
}

prompt_input() {
  echo -e -n "${CYAN}?${RESET} ${BOLD}$1${RESET} "
  read -rs val
  echo ""
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
  while kill -0 $pid 2>/dev/null; do
    local temp=${spinstr#?}
    printf "\r${CYAN}%c${RESET} ${msg}..." "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
  done
  
  wait $pid
  local exit_code=$?
  
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

# ─── Check Dependencies ────────────────────────────────────────────────────
info "Checking system requirements..."
command -v node >/dev/null 2>&1 || error "Node.js is required. Install from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || error "npm is required."
command -v git  >/dev/null 2>&1 || error "Git is required."
echo ""

# ─── Install Packages ──────────────────────────────────────────────────────
info "Installing core engine & plugins..."
spinner_task "Installing opencode-ai" npm install -g opencode-ai
spinner_task "Installing opencode-antigravity-auth" npm install -g opencode-antigravity-auth
spinner_task "Installing tokscale" npm install -g tokscale

if [ ! -d "$HOME/.oh-my-openagent" ]; then
  spinner_task "Installing oh-my-openagent" npx --yes oh-my-openagent install --no-tui --claude=no --openai=no --gemini=no --copilot=no --skip-auth
fi
echo ""

# ─── Configuration ─────────────────────────────────────────────────────────
info "Applying stack configurations..."
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"
if [ -f "configs/opencode.json" ]; then
  cp configs/opencode.json "$OPENCODE_CONFIG_DIR/opencode.json"
fi

OMA_CONFIG_DIR="$HOME/.oh-my-openagent"
if [ -d "$OMA_CONFIG_DIR" ]; then
  cp configs/oh-my-openagent/.openagentrc "$OMA_CONFIG_DIR/" 2>/dev/null || true
fi
success "Configs applied successfully.\n"

# ─── Interactive Authentication ─────────────────────────────────────────────
info "Provider Authentication"

touch .env

if prompt_yes_no "Enable GitHub Copilot Integration?"; then
  if opencode auth status github 2>/dev/null | grep -q "authenticated"; then
    success "GitHub is already authenticated.\n"
  else
    echo -e "${DIM}Opening browser for GitHub authentication...${RESET}"
    opencode auth github || warn "GitHub auth skipped."
    echo ""
  fi
fi

if prompt_yes_no "Configure Google Gemini Pro?"; then
  KEY=$(prompt_input "Enter your Google API Key (input hidden):")
  if grep -q "^GOOGLE_API_KEY=" .env; then
    sed -i.bak "s/^GOOGLE_API_KEY=.*/GOOGLE_API_KEY=\"$KEY\"/" .env && rm -f .env.bak
  else
    echo "GOOGLE_API_KEY=\"$KEY\"" >> .env
  fi
  success "Google key saved to .env\n"
fi

if prompt_yes_no "Configure OpenRouter (200+ Models)?"; then
  KEY=$(prompt_input "Enter your OpenRouter API Key (input hidden):")
  if grep -q "^OPENROUTER_API_KEY=" .env; then
    sed -i.bak "s/^OPENROUTER_API_KEY=.*/OPENROUTER_API_KEY=\"$KEY\"/" .env && rm -f .env.bak
  else
    echo "OPENROUTER_API_KEY=\"$KEY\"" >> .env
  fi
  success "OpenRouter key saved to .env\n"
fi

spinner_task "Initializing Antigravity Auth Layer" opencode-antigravity-auth init
echo ""

# ─── Final Auth Check ──────────────────────────────────────────────────────
if [ -x "scripts/auth-check.sh" ]; then
  ./scripts/auth-check.sh
fi
