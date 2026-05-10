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
section "Prerequisites" 1 6

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
section "Setup Profile" 2 6

if [ -z "$PROFILE" ] && [ "$NON_INTERACTIVE" = false ]; then
  printf "  ${BOLD}Choose a preset, or pick components manually:${RESET}\n\n"
  printf "  ${CYAN}1${RESET}  ${BOLD}Minimal${RESET}      Core engine only\n"
  printf "  ${CYAN}2${RESET}  ${BOLD}Backend Dev${RESET}  Core + Backend MCPs + Skills + Agent\n"
  printf "  ${CYAN}3${RESET}  ${BOLD}Full Stack${RESET}   Backend + Frontend + tokscale + repomix\n"
  printf "  ${CYAN}4${RESET}  ${BOLD}Everything${RESET}   All of the above + Playwright + oh-my-openagent\n"
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
section "Core Engine" 3 6

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

if [ -f "${SCRIPT_DIR}/configs/oh-my-openagent.json" ] \
   && npm_installed oh-my-opencode \
   && [ "$DRY_RUN" = false ]; then
  cp "${SCRIPT_DIR}/configs/oh-my-openagent.json" \
     "${OPENCODE_CONFIG_DIR}/oh-my-openagent.json"
fi

# =============================================================================
# STEP 4 -- Backend Pack
# =============================================================================
section "Backend Pack" 4 6

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
      spinner_task "Installing Chromium + system deps" npx playwright install --with-deps chromium
    else
      spinner_task "Installing Chromium" npx playwright install chromium
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
# STEP 4c -- Optional tools
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

OMA_INSTALLED=false
if npm_installed oh-my-opencode; then
  already "oh-my-openagent"
  mark_installed "oh-my-openagent"
  OMA_INSTALLED=true
  # Trigger headless init just in case it hasn't run yet
  oh-my-opencode --help >/dev/null 2>&1 || true
elif want "oma" "Install oh-my-openagent? (advanced terminal harness + themes)"; then
  spinner_task "Installing oh-my-openagent" npm install -g oh-my-opencode
  mark_installed "oh-my-openagent"
  OMA_INSTALLED=true
  spinner_task "Bootstrapping OMA default tools" oh-my-opencode --help || true
else
  mark_skipped "oh-my-openagent"
fi

# =============================================================================
# STEP 4d -- Finalize Configuration Build
# =============================================================================
# This runs unconditionally at the end to ensure schema compliance.
if [ "$DRY_RUN" = false ]; then
  _mcp_tmp=$(mktemp)
  MCP_DOCKER="$MCP_DOCKER"             \
  MCP_SENTRY="$MCP_SENTRY"             \
  MCP_STRIPE="$MCP_STRIPE"             \
  MCP_CONTEXT7="$MCP_CONTEXT7"         \
  STRIPE_KEY="${STRIPE_KEY:-}"         \
  OMA_INSTALLED="${OMA_INSTALLED}"     \
  OC_SCRIPT_DIR="$SCRIPT_DIR"          \
  OC_CONFIG_DIR="$OPENCODE_CONFIG_DIR" \
  node - > "$_mcp_tmp" <<'NODE'
const fs   = require('fs');
const path = require('path');
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

// 1. If OMA is installed, explicitly register it as a PLUGIN
const isTrue = v => String(v).toLowerCase() === 'true';

if (isTrue(process.env.OMA_INSTALLED)) {
  // Push OMA into the array if it isn't already there
  if (!d.plugin.includes('oh-my-opencode')) {
    d.plugin.push('oh-my-opencode');
  }
  
  // Inject its default MCPs with strict schema formatting
  if (!d.mcp.search) d.mcp.search = { type: "local", command: "npx", args: ["-y", "@modelcontextprotocol/server-brave-search"], enabled: true };
  if (!d.mcp.fetch)  d.mcp.fetch  = { type: "local", command: "npx", args: ["-y", "@modelcontextprotocol/server-fetch"], enabled: true };
}

// 2. Format existing broken tools if they exist (Fixes OMA legacy injections)
Object.keys(d.mcp).forEach(k => {
  if (!d.mcp[k].type && d.mcp[k].command) d.mcp[k].type = "local";
  if (d.mcp[k].enabled === undefined) d.mcp[k].enabled = true;
});

const readJson = p => { try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; } };
const servers = (readJson(backendPath) || {}).mcp || {};

const fallbacks = {
  docker: { type: "local", command: "npx", args: ["-y", "mcp-server-docker"], enabled: true },
  sentry: { type: "local", command: "npx", args: ["-y", "@modelcontextprotocol/server-sentry"], enabled: true },
  context7: { type: "remote", url: "https://mcp.context7.com/mcp", enabled: true },
  stripe: { type: "local", command: "npx", args: ["-y", "@stripe/mcp"], enabled: true }
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

// 3. Append chosen infrastructure tools
if (isTrue(process.env.MCP_DOCKER))   copyServer('docker');
if (isTrue(process.env.MCP_SENTRY))   copyServer('sentry');
if (isTrue(process.env.MCP_CONTEXT7)) copyServer('context7');
if (isTrue(process.env.MCP_STRIPE))   copyServer('stripe', s => {
  s.environment = s.environment || {};
  if (process.env.STRIPE_KEY) s.environment.STRIPE_SECRET_KEY = process.env.STRIPE_KEY;
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
fi

# =============================================================================
# STEP 5 -- Provider authentication
# =============================================================================
section "Provider Authentication" 5 6

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
section "Summary" 6 6

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