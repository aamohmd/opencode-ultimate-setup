#!/usr/bin/env bash
# =============================================================================
# opencode Ultimate Stack — Interactive Setup
# =============================================================================

set -euo pipefail

# =============================================================================
# 0. Parse flags
# =============================================================================
DRY_RUN=false
NON_INTERACTIVE=false
VERBOSE=false
PROFILE=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=true ;;
    --yes|--all)  NON_INTERACTIVE=true ;;
    --verbose)    VERBOSE=true ;;
    --profile=*)  PROFILE="${arg#*=}" ;;
    --help|-h)
      sed -n 's/^# \{0,2\}//p' "$0" | head -14
      exit 0 ;;
    *)
      printf 'Unknown flag: %s  (try --help)\n' "$arg" >&2
      exit 1 ;;
  esac
done

# =============================================================================
# 1. OS detection
# =============================================================================
OS_TYPE="unknown"
case "$(uname -s 2>/dev/null)" in
  Darwin) OS_TYPE="macos" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS_TYPE="wsl"
    else
      OS_TYPE="linux"
    fi ;;
esac

# =============================================================================
# 2. Color support  (NO_COLOR / TERM=dumb / non-tty safe)
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

# =============================================================================
# 3. Logging
# =============================================================================
info()    { printf "  ${CYAN}>${RESET} %b\n" "$1"; }
success() { printf "  ${GREEN}v${RESET} %b\n" "$1"; }
warn()    { printf "  ${YELLOW}!${RESET} %b\n" "$1"; }
err()     { printf "  ${RED}x${RESET} %b\n" "$1" >&2; }
fatal()   { printf "  ${RED}x${RESET} %b\n" "$1" >&2; exit 1; }
detail()  { printf "  ${DIM}  %b${RESET}\n" "$1"; }
already() { printf "  ${DIM}v${RESET} %b${DIM} -- already configured${RESET}\n" "$1"; }

section() {
  local label="$1" n="$2" total="$3"
  local filled=$(( n * 24 / total )) bar="" i
  for ((i=0; i<filled; i++));  do bar="${bar}#"; done
  for ((i=filled; i<24; i++)); do bar="${bar}."; done
  local pct=$(( n * 100 / total ))
  printf "\n${BLUE}${BOLD}  -- %s${RESET}\n" "$label"
  printf "  ${DIM}[%s] Step %d/%d (%d%%)${RESET}\n\n" "$bar" "$n" "$total" "$pct"
}

# =============================================================================
# 4. Prompts
# =============================================================================
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

prompt_secret() {
  printf "  ${CYAN}?${RESET} ${BOLD}%s${RESET} (input hidden) " "$1" >&2
  local val=""
  if read -rs val </dev/tty 2>/dev/null; then printf '\n' >&2
  else read -r val </dev/tty; fi
  printf '%s' "$val"
}

# =============================================================================
# 5. npm / path helpers
# =============================================================================
refresh_npm_path() {
  local npm_bin; npm_bin="$(npm prefix -g 2>/dev/null)/bin"
  case ":${PATH}:" in *":${npm_bin}:"*) ;; *) export PATH="${npm_bin}:${PATH}" ;; esac
}

npm_installed() { npm list -g "$1" --depth=0 >/dev/null 2>&1; }

spinner_task() {
  local msg="$1"; shift
  [ "$DRY_RUN" = true ] && { printf "  ${DIM}[dry-run] %s${RESET}\n" "$msg"; return 0; }
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
    [ "$VERBOSE" = true ] && cat "$tmpfile"
  fi
  rm -f "$tmpfile"; return "$code"
}

sed_inplace() { sed -i.bak "$1" "$2" && rm -f "${2}.bak"; }

save_env_key() {
  local file="$1" var="$2" val="$3"
  [ "$DRY_RUN" = true ] && { detail "[dry-run] Would write ${var} to ${file}"; return; }
  if grep -q "^${var}=" "$file" 2>/dev/null; then
    sed_inplace "s|^${var}=.*|${var}=\"${val}\"|" "$file"
  else
    printf '%s="%s"\n' "$var" "$val" >> "$file"
  fi
}

# =============================================================================
# 6. State-detection helpers
# =============================================================================
mcp_configured() {
  local key="$1" ocfile="${OPENCODE_CONFIG_DIR}/opencode.json"
  [ -f "$ocfile" ] || return 1
  node -e "
    try {
      var d = JSON.parse(require('fs').readFileSync('${ocfile}','utf8'));
      process.exit((d.mcp && d.mcp['${key}']) ? 0 : 1);
    } catch(e) { process.exit(1); }
  " 2>/dev/null
}

any_backend_configured() {
  local ocfile="${OPENCODE_CONFIG_DIR}/opencode.json"
  [ -f "$ocfile" ] || return 1
  node -e "
    try {
      var d = JSON.parse(require('fs').readFileSync('${ocfile}','utf8'));
      var keys = ['docker','sentry','context7','stripe'];
      process.exit(keys.some(function(k){ return d.mcp && d.mcp[k]; }) ? 0 : 1);
    } catch(e) { process.exit(1); }
  " 2>/dev/null
}

env_key_set() {
  local file="$1" var="$2"
  [ -f "$file" ] && grep -q "^${var}=.\+" "$file" 2>/dev/null
}

backend_skills_installed() {
  local src="${SCRIPT_DIR}/configs/skills/backend"
  [ -d "$src" ] || return 1
  for d in "$src"/*/; do
    [ -d "${OPENCODE_CONFIG_DIR}/skills/$(basename "$d")" ] && return 0
  done
  return 1
}

github_authed() {
  command -v opencode >/dev/null 2>&1 \
    && opencode auth list 2>/dev/null | grep -iq "github"
}

has_browser() {
  case "$OS_TYPE" in
    macos)  return 0 ;;
    wsl)    command -v wslview >/dev/null 2>&1 || command -v cmd.exe >/dev/null 2>&1; return $? ;;
    linux)  command -v xdg-open >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; return $? ;;
    *)      return 1 ;;
  esac
}

# =============================================================================
# 7. Install tracking
# =============================================================================
INSTALLED=()
SKIPPED=()
ACTIVE_PROVIDERS=()
REMINDERS=()
mark_installed() { INSTALLED+=("$1"); }
mark_skipped()   { SKIPPED+=("$1"); }
remind()         { REMINDERS+=("$1"); }

# =============================================================================
# 8. Profile gating
# =============================================================================
profile_includes() {
  local feature="$1"
  case "$PROFILE" in
    minimal)    return 1 ;;
    backend)    case "$feature" in backend) return 0 ;; esac; return 1 ;;
    fullstack)  case "$feature" in backend|frontend|tokscale|repomix) return 0 ;; esac; return 1 ;;
    everything) return 0 ;;
    *)          return 1 ;;
  esac
}

want() {
  local feature="$1" question="$2" default="${3:-Y}"
  profile_includes "$feature" && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "$question" "$default"
}

# =============================================================================
# Resolved paths
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"

# =============================================================================
# Banner
# =============================================================================
clear 2>/dev/null || true
printf "${BLUE}${BOLD}"
cat << 'BANNER'
                                         __   
  ____  ____  ___  ____  _________  ____/ /__ 
 / __ \/ __ \/ _ \/ __ \/ ___/ __ \/ __  / _ \
/ /_/ / /_/ /  __/ / / / /__/ /_/ / /_/ /  __/
\____/ .___/\___/_/ /_/\___/\____/\__,_/\___/ 
    /_/                                        
BANNER
printf "${RESET}${DIM}  opencode Ultimate Stack  --  one script, zero friction${RESET}\n"
[ "$DRY_RUN" = true ]         && printf "  ${YELLOW}${BOLD}DRY-RUN MODE -- no changes will be made${RESET}\n"
[ "$NON_INTERACTIVE" = true ] && printf "  ${YELLOW}${BOLD}NON-INTERACTIVE -- accepting all defaults${RESET}\n"
printf "  ${DIM}Platform: %s${RESET}\n\n" "$OS_TYPE"

# =============================================================================
# STEP 1 -- Prerequisites
# =============================================================================
section "Prerequisites" 1 7

PREREQ_FAIL=0
BASH_MAJOR="${BASH_VERSINFO[0]:-0}"; BASH_MINOR="${BASH_VERSINFO[1]:-0}"
if [ "$BASH_MAJOR" -lt 3 ] || { [ "$BASH_MAJOR" -eq 3 ] && [ "$BASH_MINOR" -lt 2 ]; }; then
  err "bash 3.2+ required (found ${BASH_VERSION:-unknown}).  macOS: brew install bash"
  PREREQ_FAIL=1
else
  success "bash  ${DIM}(${BASH_VERSION})${RESET}"
fi

for tool in node npm git; do
  if command -v "$tool" >/dev/null 2>&1; then
    ver=$("$tool" --version 2>/dev/null | head -1)
    success "$tool  ${DIM}(${ver})${RESET}"
  else
    case "$tool" in
      node|npm) err "node/npm not found. Install: https://nodejs.org" ;;
      git)      err "git not found. Install: https://git-scm.com" ;;
    esac
    PREREQ_FAIL=1
  fi
done
[ "$PREREQ_FAIL" -eq 1 ] && fatal "Fix the above issues then re-run."

NODE_MAJOR=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
if [ "${NODE_MAJOR:-0}" -lt 18 ]; then
  warn "Node.js $(node --version) detected -- opencode requires v18+."
  prompt_yes_no "Continue anyway?" "N" || fatal "Aborted. Please upgrade Node.js first."
else
  success "Node.js >= 18  ${DIM}(${NODE_MAJOR})${RESET}"
fi

refresh_npm_path

# =============================================================================
# STEP 2 -- Profile
# =============================================================================
section "Setup Profile" 2 7

if [ -z "$PROFILE" ] && [ "$NON_INTERACTIVE" = false ]; then
  printf "  ${BOLD}Choose a preset, or pick components manually:${RESET}\n\n"
  printf "  ${CYAN}1${RESET}  ${BOLD}Minimal${RESET}      Core engine only\n"
  printf "  ${CYAN}2${RESET}  ${BOLD}Backend Dev${RESET}  Core + Backend MCPs + Skills + Agent\n"
  printf "  ${CYAN}3${RESET}  ${BOLD}Full Stack${RESET}   Backend + Frontend + tokscale + repomix\n"
  printf "  ${CYAN}4${RESET}  ${BOLD}Everything${RESET}   All of the above + Mobile + Playwright\n"
  printf "  ${CYAN}5${RESET}  ${BOLD}Custom${RESET}       I'll pick each component myself\n\n"
  printf "  ${CYAN}?${RESET} ${BOLD}Profile${RESET} [1-5, default: 5]: "
  read -r pick </dev/tty
  case "${pick:-5}" in
    1) PROFILE=minimal ;;
    2) PROFILE=backend ;;
    3) PROFILE=fullstack ;;
    4) PROFILE=everything ;;
    *) PROFILE=custom ;;
  esac
fi
PROFILE="${PROFILE:-custom}"
success "Profile: ${BOLD}${PROFILE}${RESET}"

# =============================================================================
# STEP 3 -- Core engine
# =============================================================================
section "Core Engine" 3 7

if npm_installed opencode-ai; then
  already "opencode-ai (core engine)"
  mark_installed "opencode-ai"
else
  spinner_task "Installing opencode-ai (core engine)" npm install -g opencode-ai
  mark_installed "opencode-ai"
fi
refresh_npm_path

mkdir -p "$OPENCODE_CONFIG_DIR"
touch .env "${OPENCODE_CONFIG_DIR}/.env" 2>/dev/null || true

if [ "$DRY_RUN" = false ]; then
  OC_SCRIPT_DIR="$SCRIPT_DIR" OC_CONFIG_DIR="$OPENCODE_CONFIG_DIR" node - <<'BASECFG'
const fs   = require('fs');
const path = require('path');
const configDir    = process.env.OC_CONFIG_DIR;
const opencodePath = path.join(configDir, 'opencode.json');
const srcPath      = path.join(process.env.OC_SCRIPT_DIR, 'configs', 'opencode.json');
const readJson = p => { try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; } };

const fallbackBase = {
  "$schema": "https://opencode-ai.github.io/opencode/schema.json",
  "model": "gemini-2.5-pro"
};

const src = readJson(srcPath) || fallbackBase;
const dst = readJson(opencodePath) || {};

if (src) {
  ['$schema','plugin','model','small_model','instructions','provider'].forEach(k => {
    if (src[k] !== undefined) dst[k] = src[k];
  });
  if (!dst.mcp || typeof dst.mcp !== 'object') dst.mcp = {};
  fs.mkdirSync(configDir, { recursive: true });
  fs.writeFileSync(opencodePath, JSON.stringify(dst, null, 2));
}
BASECFG
fi


# =============================================================================
# STEP 4 -- Backend Pack
# =============================================================================
section "Backend Pack" 4 7

MCP_DOCKER=false
MCP_SENTRY=false
MCP_STRIPE=false
MCP_CONTEXT7=false
STRIPE_KEY=""

_want_backend() {
  profile_includes "backend"  && return 0
  any_backend_configured      && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "Install Backend Pack? (MCPs + skills + @backend agent)"
}

if _want_backend; then

  printf "\n  ${BOLD}Infrastructure MCPs${RESET}\n"

  if mcp_configured docker && npm_installed mcp-server-docker; then
    already "  Docker MCP"
    mark_installed "Docker MCP"
    MCP_DOCKER=true
  elif prompt_yes_no "  Docker MCP?"; then
    MCP_DOCKER=true
    spinner_task "Installing mcp-server-docker" npm install -g mcp-server-docker
    mark_installed "Docker MCP"
  fi

  printf "\n  ${BOLD}Observability & API MCPs${RESET}\n"

  if mcp_configured sentry; then
    already "  Sentry MCP"
    mark_installed "Sentry MCP"
    MCP_SENTRY=true
  elif prompt_yes_no "  Sentry MCP? (remote OAuth -- run 'opencode mcp auth sentry' after)"; then
    MCP_SENTRY=true
    mark_installed "Sentry MCP"
    remind "Run 'opencode mcp auth sentry' to finish Sentry authentication."
  fi

  if mcp_configured stripe && npm_installed @stripe/mcp; then
    already "  Stripe MCP"
    mark_installed "Stripe MCP"
    MCP_STRIPE=true
  elif prompt_yes_no "  Stripe MCP?"; then
    STRIPE_KEY=$(prompt_secret "  Stripe secret key [sk_test_...]:")
    STRIPE_KEY=$(printf '%s' "$STRIPE_KEY" | head -1 | tr -d '\r\n ')
    if [ -n "$STRIPE_KEY" ]; then
      MCP_STRIPE=true
      spinner_task "Installing @stripe/mcp" npm install -g @stripe/mcp
      mark_installed "Stripe MCP"
    else
      warn "  No key entered -- Stripe MCP skipped."
    fi
  fi

  if mcp_configured context7; then
    already "  Context7 MCP"
    mark_installed "Context7 MCP"
    MCP_CONTEXT7=true
  elif prompt_yes_no "  Context7 MCP? (remote, live framework docs -- no install needed)"; then
    MCP_CONTEXT7=true
    detail "Add 'use context7' to any prompt to pull live framework docs."
    mark_installed "Context7 MCP"
  fi

  printf "\n  ${BOLD}Skills & Agent${RESET}\n"

  if backend_skills_installed; then
    already "  Backend skills"
    mark_installed "Backend Skills"
  elif prompt_yes_no "  Install curated backend architecture skills?"; then
    if [ -d "${SCRIPT_DIR}/configs/skills/backend" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/skills"
      spinner_task "Copying backend skills" \
        cp -r "${SCRIPT_DIR}/configs/skills/backend/"* "${OPENCODE_CONFIG_DIR}/skills/"
      mark_installed "Backend Skills"
    else
      warn "configs/skills/backend not found. Skipped."
    fi
  fi

  if [ -f "${OPENCODE_CONFIG_DIR}/agents/backend.md" ]; then
    already "  @backend agent"
    mark_installed "@backend agent"
  elif prompt_yes_no "  Install @backend agent? (use @backend in opencode)"; then
    if [ -f "${SCRIPT_DIR}/configs/agents/backend.md" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
      if [ "$DRY_RUN" = false ]; then
        cp "${SCRIPT_DIR}/configs/agents/backend.md" \
           "${OPENCODE_CONFIG_DIR}/agents/backend.md"
      fi
      success "  @backend agent installed"
      mark_installed "@backend agent"
    else
      warn "configs/agents/backend.md not found. Skipped."
    fi
  fi
  mark_installed "Backend Pack"
else
  mark_skipped "Backend Pack"
fi

# =============================================================================
# STEP 4a -- General Utilities Pack
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- General Utilities Pack${RESET}\n\n"

MCP_FETCH=false
MCP_MEMORY=false
MCP_SQLITE=false
MCP_TIME=false
MCP_FILESYSTEM=false

_want_general() {
  profile_includes "general" && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && [ "$PROFILE" != "minimal" ] && return 0
  [ "$PROFILE" = "minimal" ] && return 1
  prompt_yes_no "Install General Utilities Pack? (Fetch, Memory, SQLite, Time, Filesystem MCPs)"
}

if _want_general; then
  printf "  ${BOLD}Zero-Setup Utility MCPs${RESET}\n"

  if mcp_configured fetch; then
    already "  Fetch MCP"
    mark_installed "Fetch MCP"
    MCP_FETCH=true
  elif prompt_yes_no "  Fetch MCP? (Read web pages as markdown)"; then
    MCP_FETCH=true
    mark_installed "Fetch MCP"
  fi

  if mcp_configured memory; then
    already "  Memory MCP (Engram)"
    mark_installed "Memory MCP"
    MCP_MEMORY=true
  elif prompt_yes_no "  Memory MCP? (Engram persistent shared memory)"; then
    MCP_MEMORY=true
    if ! command -v engram >/dev/null 2>&1; then
      if command -v brew >/dev/null 2>&1; then
        spinner_task "Installing engram via Homebrew" brew install gentleman-programming/tap/engram
      else
        warn "Please install engram manually: https://github.com/Gentleman-Programming/engram"
      fi
    fi
    mark_installed "Memory MCP"
  fi

  if mcp_configured sqlite; then
    already "  SQLite MCP"
    mark_installed "SQLite MCP"
    MCP_SQLITE=true
  elif prompt_yes_no "  SQLite MCP? (Local database exploration)"; then
    MCP_SQLITE=true
    mark_installed "SQLite MCP"
  fi

  if mcp_configured time; then
    already "  Time MCP"
    mark_installed "Time MCP"
    MCP_TIME=true
  elif prompt_yes_no "  Time MCP? (Current time and timezone)"; then
    MCP_TIME=true
    mark_installed "Time MCP"
  fi

  if mcp_configured filesystem; then
    already "  Filesystem MCP"
    mark_installed "Filesystem MCP"
    MCP_FILESYSTEM=true
  elif prompt_yes_no "  Filesystem MCP? (Read/list local files)"; then
    MCP_FILESYSTEM=true
    mark_installed "Filesystem MCP"
  fi

  mark_installed "General Utilities Pack"
else
  mark_skipped "General Utilities Pack"
fi

# =============================================================================
# STEP 4b -- Frontend pack
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- Frontend Pack${RESET}\n\n"

_want_frontend() {
  profile_includes "frontend" && return 0
  npm_installed playwright    && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "Install Frontend Pack? (design skills + optional Playwright)"
}

if _want_frontend; then
  if npm_installed playwright; then
    already "  Playwright"
    mark_installed "Playwright"
  elif { profile_includes "playwright" || [ "$PROFILE" = "custom" ]; } \
       && prompt_yes_no "  Playwright? (browser automation + Chromium)" "N"; then
    set +e
    spinner_task "Installing Playwright" npm install -g playwright
    if [ "$OS_TYPE" = "linux" ] || [ "$OS_TYPE" = "wsl" ]; then
      spinner_task "Installing Chromium + deps (~3 mins)" npx -y playwright install --with-deps chromium
    else
      spinner_task "Installing Chromium (~3 mins)" npx -y playwright install chromium
    fi
    set -e
    mark_installed "Playwright + Chromium"
  fi

  SKILLS_DST="${OPENCODE_CONFIG_DIR}/skills"
  mkdir -p "$SKILLS_DST"
  if [ -d "${SCRIPT_DIR}/configs/skills/frontend" ] && [ "$DRY_RUN" = false ]; then
    count=0
    for skill_dir in "${SCRIPT_DIR}/configs/skills/frontend"/*/; do
      [ -d "$skill_dir" ] || continue
      name=$(basename "$skill_dir")
      dest="${SKILLS_DST}/${name}"
      if [ -d "$dest" ]; then
        detail "  Skill '${name}' already present -- skipped"
      else
        mkdir -p "$dest"
        cp -r "${skill_dir}"* "$dest/" 2>/dev/null || true
        count=$((count+1))
      fi
    done
    [ "$count" -gt 0 ] \
      && success "  ${count} new frontend skill(s) installed" \
      && mark_installed "Frontend Skills (${count})" \
      || already "  Frontend skills"
  fi

  # ui-ux-pro-max skill (76k★ design intelligence -- installed via its own CLI)
  if [ -d "${OPENCODE_CONFIG_DIR}/skills/ui-ux-pro-max" ]; then
    already "  ui-ux-pro-max skill"
    mark_installed "ui-ux-pro-max"
  elif command -v python3 >/dev/null 2>&1 \
       && prompt_yes_no "  ui-ux-pro-max? (design intelligence: 67 styles, 161 palettes, 57 font pairings)"; then
    if [ "$DRY_RUN" = false ]; then
      set +e
      _uipro_tmp=$(mktemp -d)
      (cd "$_uipro_tmp" && npx -y uipro-cli@latest init --ai opencode >/dev/null 2>&1)
      if [ -d "${_uipro_tmp}/.opencode/skills/ui-ux-pro-max" ]; then
        mkdir -p "${OPENCODE_CONFIG_DIR}/skills"
        cp -r "${_uipro_tmp}/.opencode/skills/ui-ux-pro-max" \
              "${OPENCODE_CONFIG_DIR}/skills/ui-ux-pro-max"
        success "  ui-ux-pro-max skill installed"
      else
        warn "ui-ux-pro-max install failed. Run manually: npx uipro-cli@latest init --ai opencode"
      fi
      rm -rf "$_uipro_tmp"
      set -e
    fi
    mark_installed "ui-ux-pro-max"
  fi

  if [ -f "${OPENCODE_CONFIG_DIR}/agents/frontend.md" ]; then
    already "  @frontend agent"
    mark_installed "@frontend agent"
  elif prompt_yes_no "  Install @frontend agent? (use @frontend in opencode)"; then
    if [ -f "${SCRIPT_DIR}/configs/agents/frontend.md" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
      if [ "$DRY_RUN" = false ]; then
        cp "${SCRIPT_DIR}/configs/agents/frontend.md" \
           "${OPENCODE_CONFIG_DIR}/agents/frontend.md"
      fi
      success "  @frontend agent installed"
      mark_installed "@frontend agent"
    else
      warn "configs/agents/frontend.md not found. Skipped."
    fi
  fi

  mark_installed "Frontend Pack"
else
  mark_skipped "Frontend Pack"
fi

# =============================================================================
# STEP 4c -- Landing Page Pack
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- Landing Page Pack${RESET}\n\n"

MCP_21ST_DEV=false
_21ST_DEV_KEY=""

_want_landing() {
  profile_includes "landing"  && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "Install Landing Page Pack? (GSAP skills + 21st Dev MCP + @studio agent)"
}

if _want_landing; then

  # GSAP skills (official greensock/gsap-skills)
  GSAP_SRC="${SCRIPT_DIR}/configs/skills/gsap"
  GSAP_DST="${OPENCODE_CONFIG_DIR}/skills"
  if [ -d "${GSAP_DST}/gsap-core" ]; then
    already "  GSAP skills (8 modules)"
    mark_installed "GSAP Skills"
  elif [ -d "$GSAP_SRC" ]; then
    mkdir -p "$GSAP_DST"
    _gsap_count=0
    if [ "$DRY_RUN" = false ]; then
      for skill_dir in "${GSAP_SRC}"/gsap-*/; do
        name=$(basename "$skill_dir")
        mkdir -p "${GSAP_DST}/${name}"
        cp -r "${skill_dir}"* "${GSAP_DST}/${name}/"
        _gsap_count=$((_gsap_count + 1))
      done
      # Copy the llms.txt index if present
      [ -f "${GSAP_SRC}/llms.txt" ] && cp "${GSAP_SRC}/llms.txt" "${GSAP_DST}/llms-gsap.txt"
    fi
    success "  GSAP skills installed (${_gsap_count} modules)"
    mark_installed "GSAP Skills"
  else
    warn "configs/skills/gsap not found. Skipped."
  fi

  # 21st Dev MCP
  if mcp_configured "21st-dev"; then
    already "  21st Dev MCP"
    mark_installed "21st Dev MCP"
    MCP_21ST_DEV=true
  elif prompt_yes_no "  21st Dev MCP? (premium React component catalog — requires API key from 21st.dev)"; then
    MCP_21ST_DEV=true
    _21ST_DEV_KEY=$(prompt_secret "  21st Dev API key (or press Enter to skip):")
    _21ST_DEV_KEY=$(printf '%s' "$_21ST_DEV_KEY" | head -1 | tr -d '\r\n ')
    if [ -z "$_21ST_DEV_KEY" ]; then
      detail "No key entered -- MCP registered but disabled until you add your key."
    fi
    mark_installed "21st Dev MCP"
  fi

  # @studio agent
  if [ -f "${OPENCODE_CONFIG_DIR}/agents/studio.md" ]; then
    already "  @studio agent"
    mark_installed "@studio agent"
  elif prompt_yes_no "  Install @studio agent? (use @studio for landing pages in opencode)"; then
    if [ -f "${SCRIPT_DIR}/configs/agents/studio.md" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
      if [ "$DRY_RUN" = false ]; then
        cp "${SCRIPT_DIR}/configs/agents/studio.md" \
           "${OPENCODE_CONFIG_DIR}/agents/studio.md"
      fi
      success "  @studio agent installed"
      mark_installed "@studio agent"
    else
      warn "configs/agents/studio.md not found. Skipped."
    fi
  fi

  mark_installed "Landing Page Pack"
else
  mark_skipped "Landing Page Pack"
fi

# =============================================================================
# STEP 4d -- AI Engineering Pack
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- AI Engineering Pack${RESET}\n\n"

MCP_HUGGINGFACE=false
MCP_LANGSMITH=false
MCP_WANDB=false
MCP_PINECONE=false
_PINECONE_KEY=""
_WANDB_KEY=""

_want_ai() {
  profile_includes "ai-engineering" && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "Install AI Engineering Pack? (Model Evaluation, HuggingFace, RAG tools + @ai-engineer)"
}

if _want_ai; then

  # AI Engineering Skills
  AI_SRC="${SCRIPT_DIR}/configs/skills/ai-engineering"
  AI_DST="${OPENCODE_CONFIG_DIR}/skills/ai-engineering"
  if [ -d "${AI_DST}/ml-pipeline-creation" ]; then
    already "  AI Engineering skills (12 modules)"
    mark_installed "AI Engineering Skills"
  elif [ -d "$AI_SRC" ]; then
    mkdir -p "$AI_DST"
    _ai_count=0
    if [ "$DRY_RUN" = false ]; then
      for skill_dir in "${AI_SRC}"/*/; do
        [ -d "$skill_dir" ] || continue
        name=$(basename "$skill_dir")
        mkdir -p "${AI_DST}/${name}"
        cp -r "${skill_dir}"* "${AI_DST}/${name}/"
        _ai_count=$((_ai_count + 1))
      done
    fi
    success "  AI Engineering skills installed (${_ai_count} modules)"
    mark_installed "AI Engineering Skills"
  else
    warn "configs/skills/ai-engineering not found. Skipped."
  fi

  # HuggingFace MCP
  if mcp_configured "huggingface"; then
    already "  HuggingFace MCP"
    mark_installed "HuggingFace MCP"
    MCP_HUGGINGFACE=true
  elif prompt_yes_no "  HuggingFace MCP? (Direct access to HF Hub APIs and Models)"; then
    MCP_HUGGINGFACE=true
    mark_installed "HuggingFace MCP"
  fi

  # LangSmith MCP
  if mcp_configured "langsmith"; then
    already "  LangSmith MCP"
    mark_installed "LangSmith MCP"
    MCP_LANGSMITH=true
  elif prompt_yes_no "  LangSmith MCP? (Observability and tracing for LLMs)"; then
    MCP_LANGSMITH=true
    mark_installed "LangSmith MCP"
  fi

  # W&B MCP
  if mcp_configured "wandb"; then
    already "  Weights & Biases MCP"
    mark_installed "W&B MCP"
    MCP_WANDB=true
  elif prompt_yes_no "  Weights & Biases MCP? (LLM traces and experiment metrics - requires API key)"; then
    MCP_WANDB=true
    _WANDB_KEY=$(prompt_secret "  W&B API key (or press Enter to skip):")
    _WANDB_KEY=$(printf '%s' "$_WANDB_KEY" | head -1 | tr -d '\r\n ')
    if [ -z "$_WANDB_KEY" ]; then
      detail "No key entered -- MCP registered but won't work without a key."
    fi
    mark_installed "W&B MCP"
  fi

  # Pinecone MCP
  if mcp_configured "pinecone"; then
    already "  Pinecone MCP"
    mark_installed "Pinecone MCP"
    MCP_PINECONE=true
  elif prompt_yes_no "  Pinecone MCP? (Vector database tools - requires API key)"; then
    MCP_PINECONE=true
    _PINECONE_KEY=$(prompt_secret "  Pinecone API key (or press Enter to skip):")
    _PINECONE_KEY=$(printf '%s' "$_PINECONE_KEY" | head -1 | tr -d '\r\n ')
    if [ -z "$_PINECONE_KEY" ]; then
      detail "No key entered -- MCP registered but won't work without a key."
    fi
    mark_installed "Pinecone MCP"
  fi

  # @ai-engineer agent
  if [ -f "${OPENCODE_CONFIG_DIR}/agents/ai-engineer.md" ]; then
    already "  @ai-engineer agent"
    mark_installed "@ai-engineer agent"
  elif prompt_yes_no "  Install @ai-engineer agent? (use @ai-engineer for RAG & ML in opencode)"; then
    if [ -f "${SCRIPT_DIR}/configs/agents/ai-engineer.md" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
      if [ "$DRY_RUN" = false ]; then
        cp "${SCRIPT_DIR}/configs/agents/ai-engineer.md" \
           "${OPENCODE_CONFIG_DIR}/agents/ai-engineer.md"
      fi
      success "  @ai-engineer agent installed"
      mark_installed "@ai-engineer agent"
    else
      warn "configs/agents/ai-engineer.md not found. Skipped."
    fi
  fi

  mark_installed "AI Engineering Pack"
else
  mark_skipped "AI Engineering Pack"
fi

# =============================================================================
# STEP 4e-mobile -- Mobile Development Pack
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- Mobile Development Pack${RESET}\n\n"

MCP_FLUTTER=false
MCP_MOBILE_MCP=false

_want_mobile() {
  profile_includes "mobile"  && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "Install Mobile Development Pack? (5 skills + @mobile agent + optional MCPs)"
}

mobile_skills_installed() {
  local src="${SCRIPT_DIR}/configs/skills/mobile"
  [ -d "$src" ] || return 1
  for d in "$src"/*/; do
    [ -d "${OPENCODE_CONFIG_DIR}/skills/$(basename "$d")" ] && return 0
  done
  return 1
}

if _want_mobile; then

  printf "  ${BOLD}MCPs${RESET}\n"

  # Flutter/Dart MCP (only if dart CLI is available)
  if mcp_configured flutter; then
    already "  Flutter/Dart MCP"
    mark_installed "Flutter/Dart MCP"
    MCP_FLUTTER=true
  elif command -v dart >/dev/null 2>&1; then
    if prompt_yes_no "  Flutter/Dart MCP? (Dart analyzer, widget tree, pub.dev search)"; then
      MCP_FLUTTER=true
      mark_installed "Flutter/Dart MCP"
    fi
  else
    detail "  Flutter/Dart MCP skipped (dart CLI not found)"
  fi

  # Mobile-MCP (cross-platform device automation)
  if mcp_configured mobile-mcp; then
    already "  Mobile-MCP"
    mark_installed "Mobile-MCP"
    MCP_MOBILE_MCP=true
  elif prompt_yes_no "  Mobile-MCP? (device automation, accessibility snapshots, UI testing)"; then
    MCP_MOBILE_MCP=true
    mark_installed "Mobile-MCP"
  fi

  printf "\n  ${BOLD}Skills & Agent${RESET}\n"

  # Mobile skills
  if mobile_skills_installed; then
    already "  Mobile skills"
    mark_installed "Mobile Skills"
  elif prompt_yes_no "  Install curated mobile development skills? (React Native, Flutter, Expo, testing, performance)"; then
    if [ -d "${SCRIPT_DIR}/configs/skills/mobile" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/skills"
      _mobile_count=0
      if [ "$DRY_RUN" = false ]; then
        for skill_dir in "${SCRIPT_DIR}/configs/skills/mobile"/*/; do
          [ -d "$skill_dir" ] || continue
          name=$(basename "$skill_dir")
          dest="${OPENCODE_CONFIG_DIR}/skills/${name}"
          if [ -d "$dest" ]; then
            detail "  Skill '${name}' already present -- skipped"
          else
            mkdir -p "$dest"
            cp -r "${skill_dir}"* "$dest/" 2>/dev/null || true
            _mobile_count=$((_mobile_count+1))
          fi
        done
      fi
      [ "$_mobile_count" -gt 0 ] \
        && success "  ${_mobile_count} mobile skill(s) installed" \
        && mark_installed "Mobile Skills (${_mobile_count})" \
        || already "  Mobile skills"
    else
      warn "configs/skills/mobile not found. Skipped."
    fi
  fi

  # @mobile agent
  if [ -f "${OPENCODE_CONFIG_DIR}/agents/mobile.md" ]; then
    already "  @mobile agent"
    mark_installed "@mobile agent"
  elif prompt_yes_no "  Install @mobile agent? (use @mobile in opencode)"; then
    if [ -f "${SCRIPT_DIR}/configs/agents/mobile.md" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
      if [ "$DRY_RUN" = false ]; then
        cp "${SCRIPT_DIR}/configs/agents/mobile.md" \
           "${OPENCODE_CONFIG_DIR}/agents/mobile.md"
      fi
      success "  @mobile agent installed"
      mark_installed "@mobile agent"
    else
      warn "configs/agents/mobile.md not found. Skipped."
    fi
  fi

  mark_installed "Mobile Pack"
else
  mark_skipped "Mobile Pack"
fi

# =============================================================================
# STEP 4f -- Architect and System Design Pack
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- Architect and System Design Pack${RESET}\n\n"

MCP_GITHUB=false
MCP_BRAVE_SEARCH=false

_want_architect() {
  profile_includes "architect" && return 0
  [ -n "$PROFILE" ] && [ "$PROFILE" != "custom" ] && return 1
  prompt_yes_no "Install Architect and System Design Pack? (System Design skills, MCPs + @architect agent)"
}

if _want_architect; then

  # Architect Skills
  ARCH_SRC="${SCRIPT_DIR}/configs/skills/architect"
  ARCH_DST="${OPENCODE_CONFIG_DIR}/skills/architect"
  if [ -d "${ARCH_DST}/system-design" ]; then
    already "  Architect skills"
    mark_installed "Architect Skills"
  elif [ -d "$ARCH_SRC" ]; then
    mkdir -p "$ARCH_DST"
    _arch_count=0
    if [ "$DRY_RUN" = false ]; then
      cp -R "${ARCH_SRC}"/* "${ARCH_DST}/"
    fi
    _arch_count=$(find "${ARCH_SRC}" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
    success "  Architect skills installed (${_arch_count} modules)"
    mark_installed "Architect Skills"
  else
    warn "configs/skills/architect not found. Skipped."
  fi

  # Architect MCP servers
  if prompt_yes_no "  Install GitHub MCP? (reads repo activity for tool evaluation - requires GITHUB_TOKEN)"; then
    if [ -z "${GITHUB_TOKEN:-}" ]; then
      GITHUB_TOKEN=$(prompt_secret "    GitHub Personal Access Token (classic or fine-grained):")
    fi
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      MCP_GITHUB=true
      mark_installed "GitHub MCP"
    else
      warn "    GitHub MCP skipped (no token provided)"
    fi
  fi

  if prompt_yes_no "  Install Brave Search MCP? (search benchmarks & comparisons - requires BRAVE_API_KEY)"; then
    if [ -z "${BRAVE_API_KEY:-}" ]; then
      BRAVE_API_KEY=$(prompt_secret "    Brave Search API Key:")
    fi
    if [ -n "${BRAVE_API_KEY:-}" ]; then
      MCP_BRAVE_SEARCH=true
      mark_installed "Brave Search MCP"
    else
      warn "    Brave Search MCP skipped (no key provided)"
    fi
  fi
  


  # @architect agent
  if [ -f "${OPENCODE_CONFIG_DIR}/agents/architect.md" ]; then
    already "  @architect agent"
    mark_installed "@architect agent"
  elif prompt_yes_no "  Install @architect agent? (use @architect for system design in opencode)"; then
    if [ -f "${SCRIPT_DIR}/configs/agents/architect.md" ]; then
      mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
      if [ "$DRY_RUN" = false ]; then
        cp "${SCRIPT_DIR}/configs/agents/architect.md" \
           "${OPENCODE_CONFIG_DIR}/agents/architect.md"
      fi
      success "  @architect agent installed"
      mark_installed "@architect agent"
    else
      warn "configs/agents/architect.md not found. Skipped."
    fi
  fi

  mark_installed "Architect Pack"
else
  mark_skipped "Architect Pack"
fi

# =============================================================================
# STEP 4g -- Optional tools
# =============================================================================
printf "\n  ${BLUE}${BOLD}-- Optional Tools${RESET}\n\n"

if npm_installed tokscale; then
  already "tokscale"
  mark_installed "tokscale"
elif want "tokscale" "Install tokscale? (token analytics & cost dashboard)"; then
  spinner_task "Installing tokscale" npm install -g tokscale
  mark_installed "tokscale"
else
  mark_skipped "tokscale"
fi

if npm_installed repomix; then
  already "repomix"
  mark_installed "repomix"
elif want "repomix" "Install repomix? (pack any repo into a single AI-readable file)"; then
  spinner_task "Installing repomix" npm install -g repomix
  mark_installed "repomix"
else
  mark_skipped "repomix"
fi


# =============================================================================
# STEP 4h -- Finalize Configuration Build
# =============================================================================
# This runs unconditionally at the end to ensure schema compliance.
if [ "$DRY_RUN" = false ]; then
  _mcp_tmp=$(mktemp)
  MCP_DOCKER="$MCP_DOCKER"             \
  MCP_GITHUB="${MCP_GITHUB:-false}"      \
  MCP_BRAVE_SEARCH="${MCP_BRAVE_SEARCH:-false}" \
  GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
  BRAVE_API_KEY="${BRAVE_API_KEY:-}" \
  MCP_SENTRY="$MCP_SENTRY"             \
  MCP_STRIPE="$MCP_STRIPE"             \
  MCP_CONTEXT7="$MCP_CONTEXT7"         \
  MCP_21ST_DEV="$MCP_21ST_DEV"         \
  _21ST_DEV_KEY="${_21ST_DEV_KEY:-}"   \
  MCP_HUGGINGFACE="$MCP_HUGGINGFACE"   \
  MCP_LANGSMITH="$MCP_LANGSMITH"       \
  MCP_WANDB="$MCP_WANDB"               \
  MCP_PINECONE="$MCP_PINECONE"         \
  _PINECONE_KEY="${_PINECONE_KEY:-}"   \
  _WANDB_KEY="${_WANDB_KEY:-}"         \
  STRIPE_KEY="${STRIPE_KEY:-}"         \
  MCP_FLUTTER="$MCP_FLUTTER"           \
  MCP_MOBILE_MCP="$MCP_MOBILE_MCP"     \
  MCP_FETCH="${MCP_FETCH:-false}"      \
  MCP_MEMORY="${MCP_MEMORY:-false}"    \
  MCP_SQLITE="${MCP_SQLITE:-false}"    \
  MCP_TIME="${MCP_TIME:-false}"        \
  MCP_FILESYSTEM="${MCP_FILESYSTEM:-false}" \
  OC_SCRIPT_DIR="$SCRIPT_DIR"          \
  OC_CONFIG_DIR="$OPENCODE_CONFIG_DIR" \
  node - > "$_mcp_tmp" <<'NODE'
const fs   = require('fs');
const path = require('path');
const frontendPath = path.join(process.env.OC_SCRIPT_DIR, 'configs', 'opencode-frontend.json');
const backendPath  = path.join(process.env.OC_SCRIPT_DIR, 'configs', 'opencode-backend.json');
const opencodePath = path.join(process.env.OC_CONFIG_DIR, 'opencode.json');
const configDir    = process.env.OC_CONFIG_DIR;

// Using try...catch to prevent corrupted JSON files from breaking the script
let d = {};
if (fs.existsSync(opencodePath)) {
  try {
    d = JSON.parse(fs.readFileSync(opencodePath, 'utf8'));
  } catch (e) {
    console.error('\n  Warning: Existing opencode.json was corrupted. Rebuilding...');
  }
}

// Ensure the necessary root blocks exist
if (!d.mcp || typeof d.mcp !== 'object') d.mcp = {};

// FIX: Plugin must be an array of strings per the opencode schema
if (!Array.isArray(d.plugin)) d.plugin = [];



// 1. Format existing broken tools if they exist (Fixes OMA legacy injections)
Object.keys(d.mcp).forEach(k => {
  if (!d.mcp[k].type && d.mcp[k].command) d.mcp[k].type = "local";
  if (d.mcp[k].enabled === undefined) d.mcp[k].enabled = true;
  // opencode-ai requires command to be an array, not command + args.
  if (typeof d.mcp[k].command === "string" && Array.isArray(d.mcp[k].args)) {
    d.mcp[k].command = [d.mcp[k].command, ...d.mcp[k].args];
    delete d.mcp[k].args;
  }
});

const readJson = p => { try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; } };
const servers = (readJson(backendPath) || {}).mcp || {};
const frontendServers = (readJson(frontendPath) || {}).mcp || {};

const fallbacks = {
  docker: { type: "local", command: ["npx", "-y", "mcp-server-docker"], enabled: true },
  sentry: { type: "local", command: ["npx", "-y", "@modelcontextprotocol/server-sentry"], enabled: true },
  context7: { type: "remote", url: "https://mcp.context7.com/mcp", enabled: true },
  stripe: { type: "local", command: ["npx", "-y", "@stripe/mcp"], enabled: true }
};

const copyServer = (key, transform) => {
  const base = servers[key] || fallbacks[key];
  if (!base) return;
  const srv = JSON.parse(JSON.stringify(base));
  
  // Enforce strict schema on new tools
  if (!srv.type) srv.type = "local";
  if (srv.enabled === undefined) srv.enabled = true;
  
  if (transform) transform(srv);
  d.mcp[key] = srv;
};

const isTrue = val => String(val).toLowerCase() === 'true';

// 2. Append chosen infrastructure tools
if (isTrue(process.env.MCP_DOCKER))   copyServer('docker');
if (isTrue(process.env.MCP_SENTRY))   copyServer('sentry');
if (isTrue(process.env.MCP_CONTEXT7)) copyServer('context7');
if (isTrue(process.env.MCP_STRIPE))   copyServer('stripe', s => {
  s.environment = s.environment || {};
  if (process.env.STRIPE_KEY) s.environment.STRIPE_SECRET_KEY = process.env.STRIPE_KEY;
});

// 3. Append Landing Page Pack MCP
if (isTrue(process.env.MCP_21ST_DEV)) {
  const base = frontendServers['21st-dev'] || { type: 'local', command: ['npx', '-y', '@21st-dev/magic@latest'], enabled: true };
  const srv = JSON.parse(JSON.stringify(base));
  if (!srv.type) srv.type = 'local';
  srv.enabled = true;
  srv.environment = srv.environment || {};
  if (process.env._21ST_DEV_KEY) srv.environment.API_KEY_21ST_DEV = process.env._21ST_DEV_KEY;
  d.mcp['21st-dev'] = srv;
}

// 4. Append AI Engineering MCPs
if (isTrue(process.env.MCP_HUGGINGFACE)) {
  d.mcp['huggingface'] = { type: 'remote', url: 'https://huggingface.co/mcp', enabled: true };
}
if (isTrue(process.env.MCP_LANGSMITH)) {
  d.mcp['langsmith'] = { type: 'remote', url: 'https://api.smith.langchain.com/mcp', enabled: true };
}
if (isTrue(process.env.MCP_WANDB)) {
  const srv = { type: 'remote', url: 'https://mcp.withwandb.com', enabled: true, environment: {} };
  if (process.env._WANDB_KEY) srv.environment.WANDB_API_KEY = process.env._WANDB_KEY;
  d.mcp['wandb'] = srv;
}
if (isTrue(process.env.MCP_PINECONE)) {
  const srv = { type: 'local', command: ['npx', '-y', '@pinecone-database/mcp'], enabled: true, environment: {} };
  if (process.env._PINECONE_KEY) srv.environment.PINECONE_API_KEY = process.env._PINECONE_KEY;
  d.mcp['pinecone'] = srv;
}

// 5. Append Mobile Development Pack MCPs
if (isTrue(process.env.MCP_FLUTTER)) {
  d.mcp['flutter'] = { type: 'local', command: ['dart', 'run', 'dart_mcp_server'], enabled: true };
}
if (isTrue(process.env.MCP_MOBILE_MCP)) {
  d.mcp['mobile-mcp'] = { type: 'local', command: ['npx', '-y', '@mobilenext/mobile-mcp@latest'], enabled: true };
}

// 6. Append Architect Pack MCPs
if (isTrue(process.env.MCP_GITHUB)) {
  const srv = { type: 'local', command: ['npx', '-y', '@modelcontextprotocol/server-github'], enabled: true };
  if (process.env.GITHUB_TOKEN) srv.environment = { GITHUB_PERSONAL_ACCESS_TOKEN: process.env.GITHUB_TOKEN };
  d.mcp['github'] = srv;
}
if (isTrue(process.env.MCP_BRAVE_SEARCH)) {
  const srv = { type: 'local', command: ['npx', '-y', '@modelcontextprotocol/server-brave-search'], enabled: true };
  if (process.env.BRAVE_API_KEY) srv.environment = { BRAVE_API_KEY: process.env.BRAVE_API_KEY };
  d.mcp['brave-search'] = srv;
}

// 7. Append General Utility MCPs
if (isTrue(process.env.MCP_FETCH)) {
  d.mcp['fetch'] = { type: 'local', command: ['uvx', 'mcp-server-fetch'], enabled: true };
}
if (isTrue(process.env.MCP_MEMORY)) {
  d.mcp['memory'] = { type: 'local', command: ['engram', 'mcp'], enabled: true };
}
if (isTrue(process.env.MCP_SQLITE)) {
  d.mcp['sqlite'] = { type: 'local', command: ['uvx', 'mcp-server-sqlite', '--db-path', (process.env.HOME || '') + '/.gemini/config/sqlite.db'], enabled: true };
}
if (isTrue(process.env.MCP_TIME)) {
  d.mcp['time'] = { type: 'local', command: ['uvx', 'mcp-server-time'], enabled: true };
}
if (isTrue(process.env.MCP_FILESYSTEM)) {
  const homeDir = process.env.HOME || '/';
  d.mcp['filesystem'] = { type: 'local', command: ['npx', '-y', '@modelcontextprotocol/server-filesystem', homeDir, '/'], enabled: true };
}

Object.keys(d.mcp).forEach(k => {
  if (d.mcp[k].type !== 'remote' && typeof d.mcp[k].command === 'string') {
    if (Array.isArray(d.mcp[k].args)) {
      d.mcp[k].command = [d.mcp[k].command, ...d.mcp[k].args];
      delete d.mcp[k].args;
    } else {
      d.mcp[k].command = [d.mcp[k].command];
    }
  }
});

fs.mkdirSync(configDir, { recursive: true });
fs.writeFileSync(opencodePath, JSON.stringify(d, null, 2));

const saved = JSON.parse(fs.readFileSync(opencodePath, 'utf8'));
const keys  = Object.keys((saved.mcp && typeof saved.mcp === 'object') ? saved.mcp : {});
process.stdout.write(keys.length + ' server(s): ' + keys.join(', ') + '\n');
NODE

  mcp_result=$(cat "$_mcp_tmp" 2>/dev/null || true)
  rm -f "$_mcp_tmp"
  if [ -n "$mcp_result" ]; then
    success "Config applied -- ${mcp_result}"
  else
    warn "Config write may have failed -- check ${OPENCODE_CONFIG_DIR}/opencode.json"
  fi

  if [ "$MCP_MEMORY" = true ] && [ "$DRY_RUN" = false ]; then
    for _dir in "antigravity" "antigravity-cli" "antigravity-ide" "config"; do
      _agy_dir="$HOME/.gemini/$_dir"
      if [ -d "$_agy_dir" ]; then
        AG_MCP_CONFIG="${_agy_dir}/mcp_config.json"
        mkdir -p "$(dirname "$AG_MCP_CONFIG")"
        echo '{ "mcpServers": { "engram": { "command": "engram", "args": ["mcp"] } } }' > "$AG_MCP_CONFIG"
      fi
    done
    success "Configured Antigravity IDE & CLI to share Engram memory"
  fi
fi

# =============================================================================
# STEP 5 -- Multi-CLI Sync
# =============================================================================
section "Multi-CLI Sync" 5 7
printf "  ${BOLD}Sync stack to other detected AI coding CLIs.${RESET}\n"
printf "  ${DIM}Only CLIs found on your system will be offered.${RESET}\n\n"

_OCJSON="${OPENCODE_CONFIG_DIR}/opencode.json"
_OUS_START="<!-- opencode-ultimate-setup:start -->"
_OUS_END="<!-- opencode-ultimate-setup:end -->"

_SYNC_MANIFEST="${OPENCODE_CONFIG_DIR}/.sync-manifest"
[ "$DRY_RUN" = false ] && rm -f "$_SYNC_MANIFEST"

_record_manifest() {
  local _entry="$1"
  if [ "$DRY_RUN" = true ]; then
    detail "  [dry-run] Would log to manifest: ${_entry}"
  else
    echo "$_entry" >> "$_SYNC_MANIFEST"
  fi
}

_transpile_agent() {
  local _src="$1" _tgt="$2"
  [ "$DRY_RUN" = true ] && return
  SRC="$_src" TGT="$_tgt" node - <<'__TRANSPILE__'
const fs = require('fs');
const src = process.env.SRC;
const tgt = process.env.TGT;
const name = require('path').basename(src, '.md');
let content = fs.readFileSync(src, 'utf8');
if (!content.startsWith('---\n')) {
  content = '---\nname: ' + name + '\ndescription: opencode ' + name + ' agent\n---\n\n' + content;
}
fs.writeFileSync(tgt, content);
__TRANSPILE__
}

# Upsert a sentinel-delimited block into a markdown file.
# Replaces the existing block if found; appends if not.
_write_sentinel_block() {
  local _tgt="$1" _src="$2"
  [ "$DRY_RUN" = true ] && { detail "  [dry-run] Would update sentinel block in $(basename "${_tgt}")"; return; }
  OUS_TARGET="$_tgt" OUS_SRC="$_src" OUS_START="$_OUS_START" OUS_END="$_OUS_END" \
  node - <<'__SENTINEL_NODE__'
const fs   = require('fs');
const tgt  = process.env.OUS_TARGET;
const s    = process.env.OUS_START;
const e    = process.env.OUS_END;
const body = fs.readFileSync(process.env.OUS_SRC, 'utf8').trimEnd();
const blk  = s + '\n' + body + '\n' + e;
const cur  = fs.existsSync(tgt) ? fs.readFileSync(tgt, 'utf8') : '';
const esc  = str => str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const re   = new RegExp(esc(s) + '[\\s\\S]*?' + esc(e));
const out  = re.test(cur) ? cur.replace(re, blk)
                           : cur.trimEnd() + '\n\n' + blk + '\n';
fs.writeFileSync(tgt, out);
__SENTINEL_NODE__
}

# Render the opencode instructions array as markdown bullets to a file.
_build_instructions_file() {
  local _out="$1"
  OC_JSON="$_OCJSON" node - > "$_out" <<'__INSTR_NODE__'
const fs = require('fs');
let d = {};
try { d = JSON.parse(fs.readFileSync(process.env.OC_JSON, 'utf8')); } catch {}
const items = (d.instructions || []).map(i => '- ' + i).join('\n');
process.stdout.write('## opencode Ultimate Stack \u2014 System Instructions\n\n' + (items || '(none)') + '\n');
__INSTR_NODE__
}

# ---------------------------------------------------------------------------
# 5a. Claude Code
# ---------------------------------------------------------------------------
printf "  ${BOLD}Claude Code${RESET}\n"
if command -v claude >/dev/null 2>&1; then
  if prompt_yes_no "  Sync to Claude Code? (MCP + skills + instructions → ~/.claude/)"; then
    _claude_dir="$HOME/.claude"
    _claude_mcp="${_claude_dir}/mcp.json"
    _claude_md="${_claude_dir}/CLAUDE.md"
    _claude_skills="${_claude_dir}/skills"

    # Record manifest entries
    _mcp_keys=$(node -e "try { const d = require('fs').readFileSync('$_OCJSON', 'utf8'); console.log(Object.keys(JSON.parse(d).mcp || {}).join('\n')); } catch {}")
    for k in $_mcp_keys; do
      [ -n "$k" ] && _record_manifest "claude_mcp:$k"
    done
    if [ -d "${OPENCODE_CONFIG_DIR}/skills" ]; then
      for _sd in "${OPENCODE_CONFIG_DIR}/skills"/*/; do
        [ -d "$_sd" ] && _record_manifest "claude_skill:$(basename "$_sd")"
      done
    fi
    if [ -d "${OPENCODE_CONFIG_DIR}/agents" ]; then
      for _ag in "${OPENCODE_CONFIG_DIR}/agents"/*.md; do
        [ -f "$_ag" ] && _record_manifest "claude_agent:$(basename "$_ag")"
      done
    fi
    _record_manifest "claude_sentinel:CLAUDE.md"

    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$_claude_dir"

      # MCP: translate opencode format → Claude Code (command+args split, env key)
      _mcp_tmp=$(mktemp)
      OC_JSON="$_OCJSON" CLAUDE_MCP="$_claude_mcp" MCP_COUNT_FILE="$_mcp_tmp" node - <<'__CLAUDE_MCP__'
const fs = require('fs');
let src = {};
try { src = JSON.parse(fs.readFileSync(process.env.OC_JSON, 'utf8')); } catch {}
let dst = {};
try { if (fs.existsSync(process.env.CLAUDE_MCP)) dst = JSON.parse(fs.readFileSync(process.env.CLAUDE_MCP, 'utf8')); } catch {}
if (!dst.mcpServers || typeof dst.mcpServers !== 'object') dst.mcpServers = {};
const mcp = (src.mcp && typeof src.mcp === 'object') ? src.mcp : {};
Object.entries(mcp).forEach(([k, v]) => {
  if (v.enabled === false) return;
  const out = {};
  if (v.type === 'remote') {
    out.type = 'sse'; out.url = v.url;
  } else {
    const cmd = Array.isArray(v.command) ? v.command : [v.command];
    out.command = cmd[0];
    if (cmd.length > 1) out.args = cmd.slice(1);
  }
  if (v.environment && Object.keys(v.environment).length) out.env = v.environment;
  dst.mcpServers[k] = out;
});
fs.writeFileSync(process.env.CLAUDE_MCP, JSON.stringify(dst, null, 2));
require('fs').writeFileSync(process.env.MCP_COUNT_FILE, String(Object.keys(dst.mcpServers).length));
__CLAUDE_MCP__
      _n=$(cat "$_mcp_tmp" 2>/dev/null || echo 0); rm -f "$_mcp_tmp"
      detail "  ${_n} MCP server(s) → ${_claude_mcp}"

      # Skills: direct copy (Claude Code uses the same directory structure as opencode)
      if [ -d "${OPENCODE_CONFIG_DIR}/skills" ]; then
        mkdir -p "$_claude_skills"
        _cnt=0
        for _sd in "${OPENCODE_CONFIG_DIR}/skills"/*/; do
          [ -d "$_sd" ] || continue
          _sname=$(basename "$_sd")
          if [ -d "${_claude_skills}/${_sname}" ]; then
            rm -rf "${_claude_skills}/${_sname}"
          fi
          cp -r "$_sd" "${_claude_skills}/${_sname}"
          _cnt=$((_cnt+1))
        done
        [ "$_cnt" -gt 0 ] && detail "  ${_cnt} skill(s) → ${_claude_skills}"
      fi

      # Agents: copy opencode agents to Claude Code agents directory
      if [ -d "${OPENCODE_CONFIG_DIR}/agents" ]; then
        _claude_agents="${_claude_dir}/agents"
        mkdir -p "$_claude_agents"
        _cnt=0
        for _ag in "${OPENCODE_CONFIG_DIR}/agents"/*.md; do
          [ -f "$_ag" ] || continue
          _aname=$(basename "$_ag")
          _atarget="${_claude_agents}/${_aname}"
          if [ -f "$_atarget" ]; then
            rm -f "$_atarget"
          fi
          _transpile_agent "$_ag" "$_atarget"
          _cnt=$((_cnt+1))
        done
        [ "$_cnt" -gt 0 ] && detail "  ${_cnt} agent(s) → ${_claude_agents}"
      fi

      # Instructions: idempotent sentinel block in CLAUDE.md
      touch "$_claude_md"
      _tmp_i=$(mktemp)
      _build_instructions_file "$_tmp_i"
      _write_sentinel_block "$_claude_md" "$_tmp_i"
      rm -f "$_tmp_i"
    fi

    success "  Claude Code synced"
    mark_installed "Claude Code sync"
  else
    mark_skipped "Claude Code sync"
  fi
else
  detail "  claude not found -- skipping"
  mark_skipped "Claude Code sync"
fi

printf "\n"

# ---------------------------------------------------------------------------
# 5b. Antigravity IDE & CLI
# ---------------------------------------------------------------------------
printf "  ${BOLD}Antigravity IDE & CLI${RESET}\n"
if command -v agy >/dev/null 2>&1 || [ -d "$HOME/.gemini/antigravity-ide" ] || [ -d "$HOME/.gemini/antigravity" ] || [ -d "$HOME/.gemini/antigravity-cli" ]; then
  if prompt_yes_no "  Sync to Antigravity IDE & CLI? (MCP + skills → ~/.gemini/antigravity*/ + GEMINI.md)"; then
    _agy_md="$HOME/.gemini/GEMINI.md"

    # Record instructions sentinel
    _record_manifest "agy_sentinel:GEMINI.md"

    if [ "$DRY_RUN" = false ]; then
      # Instructions: idempotent sentinel block in GEMINI.md
      touch "$_agy_md"
      _tmp_i=$(mktemp)
      _build_instructions_file "$_tmp_i"
      _write_sentinel_block "$_agy_md" "$_tmp_i"
      rm -f "$_tmp_i"
      detail "  Instructions block → $(basename "$_agy_md")"
    fi

    _agy_synced_count=0
    for _dir in "antigravity" "antigravity-cli" "antigravity-ide" "config"; do
      _agy_base="$HOME/.gemini/$_dir"
      if [ ! -d "$_agy_base" ]; then
        continue
      fi
      
      _agy_synced_count=$((_agy_synced_count+1))
      _agy_mcp="$_agy_base/mcp_config.json"
      _agy_skills="$_agy_base/skills"
      _agy_agents="$_agy_base/agents"

      # Record manifest entries
      _mcp_keys=$(node -e "try { const d = require('fs').readFileSync('$_OCJSON', 'utf8'); console.log(Object.keys(JSON.parse(d).mcp || {}).join('\n')); } catch {}")
      for k in $_mcp_keys; do
        [ -n "$k" ] && _record_manifest "agy_mcp:$k"
      done
      if [ -d "${OPENCODE_CONFIG_DIR}/skills" ]; then
        for _sd in "${OPENCODE_CONFIG_DIR}/skills"/*/; do
          [ -d "$_sd" ] && _record_manifest "agy_skill:$(basename "$_sd")"
        done
      fi


      if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$_agy_mcp")"

        # MCP: translate opencode format → Antigravity mcpServers (serverUrl for remote servers)
        _mcp_tmp=$(mktemp)
        OC_JSON="$_OCJSON" AGY_MCP="$_agy_mcp" MCP_COUNT_FILE="$_mcp_tmp" node - <<'__AGY_MCP__'
const fs = require('fs');
let src = {};
try { src = JSON.parse(fs.readFileSync(process.env.OC_JSON, 'utf8')); } catch {}
let dst = {};
try { if (fs.existsSync(process.env.AGY_MCP)) dst = JSON.parse(fs.readFileSync(process.env.AGY_MCP, 'utf8')); } catch {}
if (!dst.mcpServers || typeof dst.mcpServers !== 'object') dst.mcpServers = {};
const mcp = (src.mcp && typeof src.mcp === 'object') ? src.mcp : {};
Object.entries(mcp).forEach(([k, v]) => {
  if (v.enabled === false) return;
  const out = {};
  if (v.type === 'remote') {
    // Antigravity uses serverUrl (not url or type:http) for remote MCP servers
    out.serverUrl = v.url;
  } else {
    const cmd = Array.isArray(v.command) ? v.command : [v.command];
    out.command = cmd[0];
    if (cmd.length > 1) out.args = cmd.slice(1);
  }
  if (v.environment && Object.keys(v.environment).length) out.env = v.environment;
  dst.mcpServers[k] = out;
});
fs.writeFileSync(process.env.AGY_MCP, JSON.stringify(dst, null, 2));
fs.writeFileSync(process.env.MCP_COUNT_FILE, String(Object.keys(dst.mcpServers).length));
__AGY_MCP__
        _n=$(cat "$_mcp_tmp" 2>/dev/null || echo 0); rm -f "$_mcp_tmp"
        detail "  ${_n} MCP server(s) → ${_agy_mcp}"

        # Skills: copy opencode skills to Antigravity global skills directory
        if [ -d "${OPENCODE_CONFIG_DIR}/skills" ]; then
          mkdir -p "$_agy_skills"
          _cnt=0
          for _sd in "${OPENCODE_CONFIG_DIR}/skills"/*/; do
            [ -d "$_sd" ] || continue
            _sname=$(basename "$_sd")
            if [ -d "${_agy_skills}/${_sname}" ]; then
              rm -rf "${_agy_skills}/${_sname}"
            fi
            cp -r "$_sd" "${_agy_skills}/${_sname}"
            _cnt=$((_cnt+1))
          done
          [ "$_cnt" -gt 0 ] && detail "  ${_cnt} skill(s) → ${_agy_skills}"
        fi


      fi
    done

    if [ "$_agy_synced_count" -gt 0 ]; then
      success "  Antigravity IDE & CLI synced"
      mark_installed "Antigravity sync"
    else
      warn "  No Antigravity data directories found."
      mark_skipped "Antigravity sync"
    fi
  else
    mark_skipped "Antigravity sync"
  fi
else
  detail "  agy / IDE not found -- skipping"
  mark_skipped "Antigravity sync"
fi

printf "\n"

# ---------------------------------------------------------------------------
# 5c. Codex CLI
# ---------------------------------------------------------------------------
printf "  ${BOLD}Codex CLI${RESET}\n"
if command -v codex >/dev/null 2>&1; then
  if prompt_yes_no "  Sync to Codex CLI? (MCP → ~/.codex/config.toml + skills + agents → ~/.codex/AGENTS.md)"; then
    _codex_dir="$HOME/.codex"
    _codex_cfg="${_codex_dir}/config.toml"
    _codex_agents="${_codex_dir}/AGENTS.md"

    # Record manifest entries
    _mcp_keys=$(node -e "try { const d = require('fs').readFileSync('$_OCJSON', 'utf8'); console.log(Object.keys(JSON.parse(d).mcp || {}).join('\n')); } catch {}")
    for k in $_mcp_keys; do
      [ -n "$k" ] && _record_manifest "codex_mcp:$k"
    done
    _record_manifest "codex_sentinel:AGENTS.md"

    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$_codex_dir"

      # MCP: translate opencode format → Codex TOML [mcp_servers.*] tables (idempotent strip+rewrite)
      _mcp_tmp=$(mktemp)
      OC_JSON="$_OCJSON" CODEX_CFG="$_codex_cfg" MCP_COUNT_FILE="$_mcp_tmp" node - <<'__CODEX_MCP__'
const fs = require('fs');
let src = {};
try { src = JSON.parse(fs.readFileSync(process.env.OC_JSON, 'utf8')); } catch {}
const mcp = (src.mcp && typeof src.mcp === 'object') ? src.mcp : {};
let existing = '';
try { if (fs.existsSync(process.env.CODEX_CFG)) existing = fs.readFileSync(process.env.CODEX_CFG, 'utf8'); } catch {}
// Strip any existing [mcp_servers.*] TOML tables so re-runs are idempotent
const lines = existing.split('\n');
let out = [];
let skip = false;
for (const line of lines) {
  const m = line.match(/^\[([^\]]+)\]/);
  if (m) {
    if (m[1].startsWith('mcp_servers.')) skip = true;
    else skip = false;
  }
  if (!skip) out.push(line);
}
existing = out.join('\n').replace(/\n{3,}/g, '\n\n').trimEnd();
let toml = '';
let count = 0;
Object.entries(mcp).forEach(([key, v]) => {
  if (v.enabled === false) return;
  const k = key.replace(/[^a-zA-Z0-9_-]/g, '_');
  toml += '\n[mcp_servers.' + k + ']\n';
  if (v.type === 'remote') {
    toml += 'transport = "http"\n';
    toml += 'url = "' + v.url + '"\n';
  } else {
    const cmd = Array.isArray(v.command) ? v.command : [v.command];
    const esc = s => s.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
    toml += 'command = "' + esc(cmd[0]) + '"\n';
    if (cmd.length > 1) toml += 'args = [' + cmd.slice(1).map(a => '"' + esc(a) + '"').join(', ') + ']\n';
  }
  if (v.environment && Object.keys(v.environment).length) {
    toml += '\n[mcp_servers.' + k + '.env]\n';
    Object.entries(v.environment).forEach(([ek, ev]) => {
      const esc = s => String(s).replace(/\\/g, '\\\\').replace(/"/g, '\\"');
      toml += ek + ' = "' + esc(ev) + '"\n';
    });
  }
  count++;
});
fs.writeFileSync(process.env.CODEX_CFG, (existing ? existing + '\n' : '') + toml);
fs.writeFileSync(process.env.MCP_COUNT_FILE, String(count));
__CODEX_MCP__
      _n=$(cat "$_mcp_tmp" 2>/dev/null || echo 0); rm -f "$_mcp_tmp"
      detail "  ${_n} MCP server(s) → ${_codex_cfg}"

      # AGENTS.md: sentinel block containing instructions + concatenated skill SKILL.md files
      _tmp_a=$(mktemp)
      _build_instructions_file "$_tmp_a"
      if [ -d "${OPENCODE_CONFIG_DIR}/skills" ]; then
        for _sd in "${OPENCODE_CONFIG_DIR}/skills"/*/; do
          [ -d "$_sd" ] || continue
          _skill_md="${_sd}SKILL.md"
          [ -f "$_skill_md" ] || continue
          printf '\n---\n\n## Skill: %s\n\n' "$(basename "$_sd")" >> "$_tmp_a"
          cat "$_skill_md" >> "$_tmp_a"
        done
      fi
      if [ -d "${OPENCODE_CONFIG_DIR}/agents" ]; then
        for _ag in "${OPENCODE_CONFIG_DIR}/agents"/*.md; do
          [ -f "$_ag" ] || continue
          printf '\n---\n\n## Agent: %s\n\n' "$(basename "$_ag" .md)" >> "$_tmp_a"
          cat "$_ag" >> "$_tmp_a"
        done
      fi
      touch "$_codex_agents"
      _write_sentinel_block "$_codex_agents" "$_tmp_a"
      rm -f "$_tmp_a"
    fi

    success "  Codex CLI synced"
    mark_installed "Codex CLI sync"
  else
    mark_skipped "Codex CLI sync"
  fi
else
  detail "  codex not found -- skipping"
  mark_skipped "Codex CLI sync"
fi

# =============================================================================
# STEP 6 -- Provider authentication
# =============================================================================
section "Provider Authentication" 6 7

printf "  ${BOLD}Configure your AI providers.${RESET}\n"
printf "  ${DIM}At least one provider is required to use opencode.${RESET}\n\n"

if github_authed; then
  already "GitHub Copilot"
  ACTIVE_PROVIDERS+=("GitHub Copilot")
elif prompt_yes_no "GitHub Copilot? (Student Pack or Pro -- opens browser OAuth)"; then
  if ! has_browser; then
    warn "No browser detected (headless / SSH session)."
    remind "GitHub Copilot: run 'opencode auth login -p github-copilot' from a desktop session."
    mark_skipped "GitHub Copilot (no browser)"
  else
    conda deactivate 2>/dev/null || true
    info "Opening browser for GitHub OAuth..."
    opencode auth login -p "github-copilot" \
      || warn "Auth skipped -- run 'opencode auth login -p github-copilot' later."
    ACTIVE_PROVIDERS+=("GitHub Copilot")
  fi
else
  mark_skipped "GitHub Copilot"
fi

printf '\n'

_google_configured() {
  env_key_set "${OPENCODE_CONFIG_DIR}/.env" "GOOGLE_API_KEY" \
    || env_key_set ".env" "GOOGLE_API_KEY"
}

if _google_configured; then
  already "Google Gemini 2.5 Pro"
  ACTIVE_PROVIDERS+=("Google Gemini 2.5 Pro")
elif prompt_yes_no "Google Gemini 2.5 Pro? (API key from aistudio.google.com)"; then
  GKEY=$(prompt_secret "Google API key [AIza...]:")
  GKEY=$(printf '%s' "$GKEY" | head -1 | tr -d '\r\n ')
  if [ -n "$GKEY" ]; then
    save_env_key ".env"                        "GOOGLE_API_KEY" "$GKEY"
    save_env_key "${OPENCODE_CONFIG_DIR}/.env" "GOOGLE_API_KEY" "$GKEY"
    success "Google API key saved"
    ACTIVE_PROVIDERS+=("Google Gemini 2.5 Pro")
  else
    warn "No key entered -- skipped."
  fi
else
  mark_skipped "Google Gemini"
  [ "$DRY_RUN" = false ] && node -e "
    const fs=require('fs'); const p=process.env.HOME+'/.config/opencode/opencode.json';
    if(fs.existsSync(p)){
      try {
        const d=JSON.parse(fs.readFileSync(p, 'utf8'));
        if(d.provider && d.provider.google && d.provider.google.models) {
          delete d.provider.google.models['gemini-2.5-pro'];
          delete d.provider.google.models['gemini-2.5-flash'];
          if(Object.keys(d.provider.google.models).length === 0) delete d.provider.google;
          fs.writeFileSync(p, JSON.stringify(d, null, 2));
        }
      } catch(e) {}
    }
  "
fi

printf '\n'

_openrouter_configured() {
  env_key_set "${OPENCODE_CONFIG_DIR}/.env" "OPENROUTER_API_KEY" \
    || env_key_set ".env" "OPENROUTER_API_KEY"
}

if _openrouter_configured; then
  already "OpenRouter"
  ACTIVE_PROVIDERS+=("OpenRouter (200+ models)")
elif prompt_yes_no "OpenRouter? (200+ models -- one key for everything)"; then
  ORKEY=$(prompt_secret "OpenRouter API key [sk-or-...]:")
  ORKEY=$(printf '%s' "$ORKEY" | head -1 | tr -d '\r\n ')
  if [ -n "$ORKEY" ]; then
    save_env_key ".env"                        "OPENROUTER_API_KEY" "$ORKEY"
    save_env_key "${OPENCODE_CONFIG_DIR}/.env" "OPENROUTER_API_KEY" "$ORKEY"
    success "OpenRouter API key saved"
    ACTIVE_PROVIDERS+=("OpenRouter (200+ models)")
  else
    warn "No key entered -- skipped."
  fi
else
  mark_skipped "OpenRouter"
  [ "$DRY_RUN" = false ] && node -e "
    const fs=require('fs'); const p=process.env.HOME+'/.config/opencode/opencode.json';
    if(fs.existsSync(p)){
      try {
        const d=JSON.parse(fs.readFileSync(p, 'utf8'));
        if(d.provider && d.provider.openrouter) {
          delete d.provider.openrouter;
          fs.writeFileSync(p, JSON.stringify(d, null, 2));
        }
      } catch(e) {}
    }
  "
fi

# =============================================================================
# STEP 6 -- Summary
# =============================================================================
section "Summary" 7 7

if [ "${#INSTALLED[@]}" -gt 0 ]; then
  printf "  ${BOLD}Installed / confirmed${RESET}\n"
  for item in "${INSTALLED[@]}"; do printf "  ${GREEN}v${RESET}  %s\n" "$item"; done
  printf '\n'
fi

if [ "$DRY_RUN" = true ]; then
  printf "  ${YELLOW}${BOLD}DRY-RUN complete -- no changes were made.${RESET}\n\n"
  exit 0
fi

if [ "${#ACTIVE_PROVIDERS[@]}" -gt 0 ]; then
  printf "${GREEN}${BOLD}"
  printf "  +-------------------------------------------+\n"
  printf "  |   v  Setup complete!  You're ready.       |\n"
  printf "  +-------------------------------------------+\n"
  printf "${RESET}\n"
  printf "  Run ${CYAN}${BOLD}opencode${RESET} to start.\n"
else
  printf "  ${YELLOW}${BOLD}!  No AI providers configured.${RESET}\n"
  printf "  ${DIM}Run 'opencode auth login' to add one at any time.${RESET}\n"
fi