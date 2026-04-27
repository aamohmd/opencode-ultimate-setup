#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — Teardown & Uninstall
# =============================================================================

set -e

# --- Colors & Styles ---
BLUE='\033[38;2;0;102;255m'
CYAN='\033[38;2;0;210;255m'
GREEN='\033[38;2;0;255;157m'
YELLOW='\033[38;2;255;184;0m'
RED='\033[38;2;255;0;85m'
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
echo -e "${RESET}${DIM} ⚡ The Ultimate AI Agent Stack Uninstaller ⚡${RESET}\n"

info()    { echo -e "${CYAN}❯${RESET} $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "${RED}✘${RESET} $1"; exit 1; }

prompt_yes_no() {
  while true; do
    echo -e -n "${CYAN}?${RESET} ${BOLD}$1${RESET} ${DIM}(y/N)${RESET} "
    read -r yn
    case ${yn:-N} in
      [Yy]* ) return 0 ;;
      [Nn]* ) return 1 ;;
      * ) echo -e "${RED}Please answer yes or no.${RESET}" ;;
    esac
  done
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

info "This script will remove the opencode Ultimate Stack components from your system."
echo ""

if prompt_yes_no "Remove global npm packages (opencode-ai, opencode-antigravity-auth, tokscale)?"; then
  spinner_task "Uninstalling global packages" npm uninstall -g opencode-ai opencode-antigravity-auth tokscale
fi

if prompt_yes_no "Remove oh-my-openagent terminal harness?"; then
  if [ -d "$HOME/.oh-my-openagent" ]; then
    spinner_task "Removing oh-my-openagent directory" rm -rf "$HOME/.oh-my-openagent"
  else
    success "oh-my-openagent is not installed or already removed."
  fi
fi

if prompt_yes_no "Remove opencode configuration directory (~/.config/opencode)?"; then
  if [ -d "$HOME/.config/opencode" ]; then
    spinner_task "Removing opencode configs" rm -rf "$HOME/.config/opencode"
  else
    success "opencode config directory not found or already removed."
  fi
fi

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║ ✔  Uninstallation complete!          ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${RESET}"
