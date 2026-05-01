#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — Teardown
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
echo -e "${RESET}${DIM} Teardown${RESET}\n"

info()    { echo -e "${CYAN}❯${RESET} $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }

prompt_yes_no() {
  while true; do
    echo -e -n "${CYAN}?${RESET} ${BOLD}$1${RESET} ${DIM}(y/N)${RESET} "
    read -r yn
    case ${yn:-N} in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo -e "${RED}Please answer yes or no.${RESET}" ;;
    esac
  done
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
    printf "\r${YELLOW}⚠${RESET} %s... ${YELLOW}Nothing to remove.${RESET}\n" "$msg"
  fi
  rm -f "$tmpfile"
}

# ─── Global npm packages ──────────────────────────────────────────────────
if prompt_yes_no "Remove global npm packages (opencode-ai, oh-my-opencode, tokscale, repomix)?"; then
  spinner_task "Removing global npm packages" \
    npm uninstall -g opencode-ai oh-my-opencode tokscale repomix
fi

# ─── npx cache ────────────────────────────────────────────────────────────
if prompt_yes_no "Clear npx cache for oh-my-opencode/oh-my-openagent?"; then
  spinner_task "Clearing npx cache" bash -c \
    'find "$HOME/.npm/_npx" -maxdepth 2 -type d 2>/dev/null | while read d; do
       ls "$d/node_modules/" 2>/dev/null | grep -q "oh-my-open" && rm -rf "$d" || true
     done; true'
fi

# ─── opencode binary ──────────────────────────────────────────────────────
if prompt_yes_no "Remove opencode binary (~/.opencode)?"; then
  spinner_task "Removing ~/.opencode" rm -rf "$HOME/.opencode"
fi

# ─── Config directory ─────────────────────────────────────────────────────
if prompt_yes_no "Remove config directory (~/.config/opencode)?"; then
  spinner_task "Removing ~/.config/opencode" rm -rf "$HOME/.config/opencode"
fi

# ─── Shell PATH entry ─────────────────────────────────────────────────────
info "Checking shell config for opencode PATH entries..."
FOUND_PATH=false
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.bash_profile"; do
  if [ -f "$rc" ] && grep -q "\.opencode" "$rc" 2>/dev/null; then
    FOUND_PATH=true
    warn "Found opencode PATH entry in $rc — remove manually:"
    grep -n "\.opencode" "$rc" | while read -r line; do
      echo -e "  ${DIM}$line${RESET}"
    done
    echo ""
  fi
done
[ "$FOUND_PATH" = false ] && success "No PATH entries found.\n"

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║   ✔  Teardown complete.              ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${RESET}"
echo ""