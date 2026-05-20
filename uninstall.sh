#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — Uninstaller
# =============================================================================
# Usage:
#   ./uninstall.sh                interactive (default)
#   ./uninstall.sh --yes          accept all defaults non-interactively
#   ./uninstall.sh --help
# =============================================================================

set -euo pipefail

# =============================================================================
# Parse flags
# =============================================================================
NON_INTERACTIVE=false

for arg in "$@"; do
  case "$arg" in
    --yes|-y|--all) NON_INTERACTIVE=true ;;
    --help|-h)
      sed -n 's/^# \{0,2\}//p' "$0" | head -8
      exit 0 ;;
    *)
      printf 'Unknown flag: %s  (try --help)\n' "$arg" >&2
      exit 1 ;;
  esac
done

# =============================================================================
# Color & Logging
# =============================================================================
BLUE="" CYAN="" GREEN="" YELLOW="" RED="" BOLD="" DIM="" RESET=""
_setup_colors() {
  [ ! -t 1 ]                 && return
  [ "${NO_COLOR:-}" != "" ]  && return
  [ "${TERM:-}" = "dumb" ]   && return
  local n; n=$(tput colors 2>/dev/null || echo 0)
  [ "$n" -lt 8 ]             && return
  BLUE='\033[34m'  CYAN='\033[36m'  GREEN='\033[32m'
  YELLOW='\033[33m' RED='\033[31m'  BOLD='\033[1m'
  DIM='\033[2m'    RESET='\033[0m'
}
_setup_colors

info()    { printf "  ${CYAN}>${RESET} %b\n" "$1"; }
success() { printf "  ${GREEN}v${RESET} %b\n" "$1"; }
warn()    { printf "  ${YELLOW}!${RESET} %b\n" "$1"; }
detail()  { printf "  ${DIM}  %b${RESET}\n" "$1"; }

prompt_yes_no() {
  local question="$1" default="${2:-Y}"
  local DEFAULT_UP; DEFAULT_UP=$(printf '%s' "$default" | tr '[:lower:]' '[:upper:]')
  local hint; [ "$DEFAULT_UP" = "Y" ] && hint="Y/n" || hint="y/N"
  [ "$NON_INTERACTIVE" = true ] && { [ "$DEFAULT_UP" = "Y" ] && return 0 || return 1; }
  while true; do
    printf "  ${CYAN}?${RESET} ${BOLD}%s${RESET} [%s] " "$question" "$hint"
    read -r yn </dev/tty
    yn="${yn:-$default}"
    local yn_low; yn_low=$(printf '%s' "$yn" | tr '[:upper:]' '[:lower:]')
    case "$yn_low" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *)     printf "  ${RED}Please answer y or n.${RESET}\n" ;;
    esac
  done
}

npm_installed() { npm list -g "$1" --depth=0 >/dev/null 2>&1; }

spinner_task() {
  local msg="$1"; shift
  if [ ! -t 1 ]; then
    printf "  > %s...\n" "$msg"
    local code=0; "$@" >/dev/null 2>&1 || code=$?
    [ "$code" -eq 0 ] && printf "  v %s  done\n" "$msg" || printf "  ! %s  failed\n" "$msg"
    return "$code"
  fi
  printf "  ${CYAN}|${RESET} %s..." "$msg"
  local tmpfile; tmpfile=$(mktemp)
  "$@" >"$tmpfile" 2>&1 &
  local pid=$! spinstr='/-\|' code=0
  while kill -0 "$pid" 2>/dev/null; do
    local head="${spinstr:0:1}"
    printf "\r  ${CYAN}%s${RESET} %s..." "$head" "$msg"
    spinstr="${spinstr:1}${head}"
    sleep 0.1
  done
  wait "$pid" || code=$?
  if [ "$code" -eq 0 ]; then
    printf "\r  ${GREEN}v${RESET} %s  ${DIM}done${RESET}               \n" "$msg"
  else
    printf "\r  ${YELLOW}!${RESET} %s  ${YELLOW}failed (non-fatal)${RESET}\n" "$msg"
  fi
  rm -f "$tmpfile"; return "$code"
}

sed_inplace() { sed -i.bak "$1" "$2" && rm -f "${2}.bak"; }

OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"

# =============================================================================
# BANNER
# =============================================================================
clear 2>/dev/null || true
printf "${RED}${BOLD}"
cat << 'BANNER'
   __  __      _           __        __ __
  / / / /____ (_)____  ___/ /____ _ / // /
 / /_/ // __// // __/ /_  _// __ `/ / // /
 \____//_/  /_//_/     /_/  \__,_/ /_//_/ 
BANNER
printf "${RESET}${DIM}  opencode Ultimate Stack  --  Removal Tool${RESET}\n\n"

if ! prompt_yes_no "This will remove the opencode stack and its configurations. Continue?" "N"; then
  printf "\n  ${YELLOW}Uninstallation cancelled.${RESET}\n"
  exit 0
fi

# =============================================================================
# 1. Global NPM Packages
# =============================================================================
printf "\n${BLUE}${BOLD}  -- Uninstalling NPM Packages${RESET}\n\n"

PACKAGES=(
  "opencode-ai"
  "mcp-server-docker"
  "@stripe/mcp"
  "tokscale"
  "repomix"
)

for pkg in "${PACKAGES[@]}"; do
  if npm_installed "$pkg"; then
    spinner_task "Removing ${pkg}" npm uninstall -g "$pkg"
  else
    detail "${pkg} is not installed"
  fi
done

if npm_installed playwright; then
  if prompt_yes_no "Remove Playwright and its browser binaries? (May affect other projects using Playwright globally)" "N"; then
    set +e
    spinner_task "Uninstalling Playwright browsers" npx playwright uninstall --all
    set -e
    spinner_task "Removing playwright package" npm uninstall -g playwright
  else
    detail "Playwright removal skipped"
  fi
fi

# =============================================================================
# 2. Config Files
# =============================================================================
printf "\n${BLUE}${BOLD}  -- Cleaning Configurations${RESET}\n\n"

if [ -d "$OPENCODE_CONFIG_DIR" ]; then
  if prompt_yes_no "Delete the ~/.config/opencode directory? (Removes all MCPs, skills, and agents)" "Y"; then
    spinner_task "Deleting ${OPENCODE_CONFIG_DIR}" rm -rf "$OPENCODE_CONFIG_DIR"
  else
    detail "Configuration directory preserved"
  fi
else
  detail "~/.config/opencode directory not found"
fi

if [ -f ".env" ]; then
  if grep -qE "^(GOOGLE_API_KEY|OPENROUTER_API_KEY)=" ".env"; then
    if prompt_yes_no "Remove added API keys from local .env file?" "Y"; then
      sed_inplace '/^GOOGLE_API_KEY=/d' ".env"
      sed_inplace '/^OPENROUTER_API_KEY=/d' ".env"
      success "Cleaned local .env file"
    fi
  fi
fi

printf "\n${GREEN}${BOLD}  v  Uninstallation complete.${RESET}\n\n"