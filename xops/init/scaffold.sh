#!/usr/bin/env bash
# xops/init/scaffold.sh
#
# The bootstrapper. Drops the ai-vscode-basics framework into a target
# repo. Idempotent: safe to re-run after upstream changes.
#
# Usage:
#   xops/init/scaffold.sh --target /path/to/repo [options]
#   xops/init/scaffold.sh              # interactive TUI (no args)
#
# Options:
#   --target PATH         Required (or set interactively). Directory to install into.
#   --dry-run             Show what would happen, change nothing.
#   --force               Overwrite files that already exist at the target.
#   --preset NAME         minimal | full   (default: full)
#   --agents LIST         Comma-separated list of agents to wire (default: all).
#                         Choices: copilot,claude,gemini,codex,cursor,opencode,aider,local
#   --lang LANG           Language preset: python | node | go | rust
#                         Adds .gitignore lines, Makefile.lang.mk, and starter test command.
#   --no-mcp              Skip MCP config files.
#   --no-vscode           Skip .vscode/ folder.
#   --no-skills           Skip .agents/skills/ (just leave a README).
#   -h | --help           This message.
#
# What gets installed (full preset):
#   - Root: README, LICENSE, AGENTS.md, CLAUDE.md, GEMINI.md, CONVENTIONS.md,
#           Makefile, .gitignore, .gitattributes
#   - .github/        copilot-instructions.md + chatmodes/ + prompts/
#   - .vscode/        settings, tasks, mcp
#   - Vendor configs  matching --agents
#   - ai/          tracking.csv + schema + state/
#   - xops/           bash + python ops tree (this script itself + siblings)
#   - docs/           code/ project/ design/ planning/ROADMAP.md tracking/ guides/
#   - .agents/skills/ skill library (one SKILL.md per subfolder)
#
# After install, in the target repo:
#   make help          # see available targets
#   make doctor        # verify the install
#   xops/agent/session-bootstrap.sh   # first context-load

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "$HERE/../.." && pwd)"
# shellcheck source=../lib/log.sh
source "$SRC_ROOT/xops/lib/log.sh"

# ── defaults ────────────────────────────────────────────────────────────
TARGET=""
DRY_RUN=0
FORCE=0
PRESET="full"
AGENTS="copilot,claude,gemini,codex,cursor,opencode,aider,local"
WITH_MCP=1
WITH_VSCODE=1
WITH_SKILLS=1
LANG=""

# ── arg parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)     TARGET="$2"; shift 2 ;;
    --target=*)   TARGET="${1#*=}"; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    --force)      FORCE=1; shift ;;
    --preset)     PRESET="$2"; shift 2 ;;
    --preset=*)   PRESET="${1#*=}"; shift ;;
    --agents)     AGENTS="$2"; shift 2 ;;
    --agents=*)   AGENTS="${1#*=}"; shift ;;
    --lang)       LANG="$2"; shift 2 ;;
    --lang=*)     LANG="${1#*=}"; shift ;;
    --no-mcp)     WITH_MCP=0; shift ;;
    --no-vscode)  WITH_VSCODE=0; shift ;;
    --no-skills)  WITH_SKILLS=0; shift ;;
    -h|--help)    sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            die "unknown arg: $1 (try --help)" 64 ;;
  esac
done

# ── interactive TUI when no --target given ───────────────────────────────
_ask() {
  # _ask PROMPT DEFAULT
  local prompt="$1" default="${2:-}"
  local answer
  if [[ -n "$default" ]]; then
    printf "%s [%s]: " "$prompt" "$default" >&2
  else
    printf "%s: " "$prompt" >&2
  fi
  read -r answer </dev/tty
  echo "${answer:-$default}"
}

_ask_yn() {
  local prompt="$1" default="${2:-y}"
  local answer
  printf "%s [%s]: " "$prompt" "$default" >&2
  read -r answer </dev/tty
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy] ]] && echo "1" || echo "0"
}

_tui_select() {
  # _tui_select PROMPT item1 item2 ...  → prints chosen item
  local prompt="$1"; shift
  local items=("$@")
  local i choice
  printf "\n%s\n" "$prompt" >&2
  for i in "${!items[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${items[$i]}" >&2
  done
  printf "choice [1]: " >&2
  read -r choice </dev/tty
  choice="${choice:-1}"
  echo "${items[$((choice-1))]}"
}

if [[ -z "$TARGET" ]]; then
  # Try dialog/whiptail first for a nicer experience.
  if command -v whiptail >/dev/null 2>&1 || command -v dialog >/dev/null 2>&1; then
    _TOOL="whiptail"; command -v whiptail >/dev/null 2>&1 || _TOOL="dialog"
    TARGET=$($_TOOL --inputbox "Target directory (will be created if missing):" 8 60 "./my-project" 3>&1 1>&2 2>&3) || TARGET=""
    PRESET=$($_TOOL --menu "Preset:" 12 50 2 \
      "full"    "All framework files (default)" \
      "minimal" "Rulebooks + tracking only" 3>&1 1>&2 2>&3) || PRESET="full"
    LANG=$($_TOOL --menu "Language preset:" 14 50 5 \
      ""       "(none)" \
      "python" "Python"  \
      "node"   "Node.js" \
      "go"     "Go"      \
      "rust"   "Rust"    3>&1 1>&2 2>&3) || LANG=""
    [[ "$LANG" == "(none)" ]] && LANG=""
    WITH_MCP=$($_TOOL --yesno "Include MCP config files?" 7 40 3>&1 1>&2 2>&3 && echo 1 || echo 0)
  else
    # Plain read -p fallback.
    printf "\n${BOLD}🏗  ai-vscode-basics interactive setup${RESET}\n\n" >&2
    TARGET=$(_ask "Target directory" "./my-project")
    PRESET=$(_tui_select "Choose preset:" "full" "minimal")
    LANG=$(_tui_select "Language preset (choose 1 for none):" "(none)" "python" "node" "go" "rust")
    [[ "$LANG" == "(none)" ]] && LANG=""
    WITH_MCP=$(_ask_yn "Include MCP config?" "y")
    WITH_VSCODE=$(_ask_yn "Include .vscode/ folder?" "y")
    WITH_SKILLS=$(_ask_yn "Include .agents/skills/ library?" "y")
  fi
fi

[[ -n "$TARGET" ]] || die "--target is required (or run interactively)" 64
case "$PRESET" in minimal|full) ;; *) die "--preset must be minimal|full" 64 ;; esac
if [[ -n "$LANG" ]]; then
  case "$LANG" in python|node|go|rust) ;; *) die "--lang must be python|node|go|rust" 64 ;; esac
fi

# Convert relative target to absolute.
mkdir -p "$TARGET" 2>/dev/null || true
TARGET="$(cd "$TARGET" && pwd)"

if [[ "$SRC_ROOT" == "$TARGET" ]]; then
  warn "source == target — this is a re-scaffold of the framework repo itself"
fi

log_step "🏗  ai-vscode-basics scaffolder"
log_info "  source : $SRC_ROOT"
log_info "  target : $TARGET"
log_info "  preset : $PRESET"
log_info "  agents : $AGENTS"
log_info "  lang   : ${LANG:-(none)}"
log_info "  options: mcp=$WITH_MCP vscode=$WITH_VSCODE skills=$WITH_SKILLS"
log_info "  mode   : $( ((DRY_RUN)) && echo DRY-RUN || echo LIVE )$( ((FORCE)) && echo " +force" )"
echo >&2

# ── copy helpers ────────────────────────────────────────────────────────
copy_file() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$TARGET/$rel"

  if [[ ! -e "$src" ]]; then
    log_warn "  ⚠️  source missing: $rel (skipping)"
    return 0
  fi

  if [[ -e "$dst" && $FORCE -eq 0 ]]; then
    if cmp -s "$src" "$dst"; then
      log_dim "  ✓ identical: $rel"
    else
      log_dim "  ↩ kept user version: $rel (use --force to overwrite)"
    fi
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    log_info "  + would copy: $rel"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  log_ok "  + copied: $rel"
}

copy_glob() {
  local pattern="$1"
  shopt -s globstar nullglob
  local f
  for f in $SRC_ROOT/$pattern; do
    [[ -f "$f" ]] || continue
    copy_file "${f#$SRC_ROOT/}"
  done
  shopt -u globstar nullglob
}

want_agent() {
  case ",$AGENTS," in *",$1,"*) return 0 ;; esac
  return 1
}

# ── 1. root files ───────────────────────────────────────────────────────
log_step "📦 root files"
ROOT_FILES=(
  "README.md" "LICENSE" "AGENTS.md" "Makefile"
  ".gitignore" ".gitattributes"
)
for f in "${ROOT_FILES[@]}"; do copy_file "$f"; done

# Vendor entrypoint files — only for selected agents.
want_agent claude  && copy_file "CLAUDE.md"
want_agent gemini  && copy_file "GEMINI.md"
want_agent aider   && copy_file "CONVENTIONS.md" && copy_file ".aider.conf.yml"

# ── 2. .github/ ─────────────────────────────────────────────────────────
if want_agent copilot; then
  log_step "🐙 .github/ (Copilot)"
  copy_file ".github/copilot-instructions.md"
  copy_glob ".github/chatmodes/*.chatmode.md"
  copy_glob ".github/prompts/*.prompt.md"
fi

# ── 3. .vscode/ ─────────────────────────────────────────────────────────
if [[ $WITH_VSCODE -eq 1 ]]; then
  log_step "🖥  .vscode/"
  copy_file ".vscode/settings.json"
  copy_file ".vscode/tasks.json"
  [[ $WITH_MCP -eq 1 ]] && copy_file ".vscode/mcp.json"
fi

# ── 4. vendor MCP + plugin configs ──────────────────────────────────────
if [[ $WITH_MCP -eq 1 ]]; then
  log_step "🔌 MCP"
  copy_file ".mcp.json"
fi

want_agent cursor   && { log_step "✨ .cursor/"; copy_file ".cursor/rules/agents.mdc"; [[ $WITH_MCP -eq 1 ]] && copy_file ".cursor/mcp.json"; }
want_agent claude   && { log_step "🤖 .claude-plugin/"; copy_file ".claude-plugin/plugin.json"; }
want_agent codex    && { log_step "🧪 .codex-plugin/"; copy_file ".codex-plugin/config.toml"; }
want_agent opencode && { log_step "🪩 .opencode/"; copy_file ".opencode/config.json"; }
want_agent gemini   && { log_step "💎 gemini-extension"; copy_file "gemini-extension.json"; }

# ── 5. ai/ ───────────────────────────────────────────────────────────
log_step "📊 ai/"
# Always write a BLANK tracking.csv (just the header) — never copy the source
# repo's history into a freshly scaffolded project.
if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$TARGET/ai/state"
  BLANK_CSV="$TARGET/ai/tracking.csv"
  if [[ -e "$BLANK_CSV" && $FORCE -eq 0 ]]; then
    log_dim "  ↩ kept user version: ai/tracking.csv (use --force to reset)"
  else
    printf 'ts_utc,run_id,agent,scope,action,status,summary,refs,commit_sha\n' > "$BLANK_CSV"
    log_ok "  + created: ai/tracking.csv (blank)"
  fi
else
  log_info "  + would create: ai/tracking.csv (blank header only)"
fi
copy_file "ai/tracking.schema.md"
copy_file "ai/README.md"
copy_file "ai/state/.gitkeep"
copy_file "ai/context.md"

# ── 6. xops/ ────────────────────────────────────────────────────────────
log_step "🛠  xops/"
copy_file "xops/README.md"
copy_file "xops/lib/log.sh"
copy_file "xops/init/scaffold.sh"
copy_glob "xops/agent/*.sh"
copy_glob "xops/makefile/*.py"

# Ensure executable bits stick after copy.
if [[ $DRY_RUN -eq 0 ]]; then
  chmod +x \
    "$TARGET/xops/init/scaffold.sh" \
    "$TARGET/xops/agent/"*.sh 2>/dev/null || true
fi

# ── 7. docs/ ────────────────────────────────────────────────────────────
log_step "📚 docs/"
copy_file "docs/README.md"
copy_glob "docs/code/*.md"
copy_glob "docs/project/*.md"
copy_glob "docs/design/*.md"
copy_file "docs/planning/README.md"
copy_file "docs/planning/ROADMAP.md"
copy_file "docs/tracking/README.md"
copy_glob "docs/guides/*.md"
copy_file "docs/reports/README.md"

if [[ $WITH_SKILLS -eq 1 ]]; then
  log_step "🧠 .agents/skills/"
  copy_file ".agents/skills/README.md"
  # Each skill lives in its own subfolder as SKILL.md
  copy_glob ".agents/skills/*/SKILL.md"
else
  copy_file ".agents/skills/README.md"
fi

# ── done ────────────────────────────────────────────────────────────────

# ── 8. version stamp ────────────────────────────────────────────────────
if [[ $DRY_RUN -eq 0 ]]; then
  VERSION_FILE="$SRC_ROOT/.ai-vscode-basics-version"
  TARGET_VER="$TARGET/.ai-vscode-basics-version"
  if [[ -f "$VERSION_FILE" ]]; then
    cp -a "$VERSION_FILE" "$TARGET_VER"
    log_ok "  + version: $(cat "$VERSION_FILE")"
  fi
fi

# ── 9. language preset ──────────────────────────────────────────────────
if [[ -n "$LANG" ]]; then
  log_step "🗣  language preset: $LANG"
  _lang_mk="$TARGET/Makefile.lang.mk"
  _gitignore="$TARGET/.gitignore"

  if [[ $DRY_RUN -eq 0 ]]; then
    # .gitignore additions (appended only if not already present)
    _append_gitignore() {
      local line="$1"
      grep -qxF "$line" "$_gitignore" 2>/dev/null || echo "$line" >> "$_gitignore"
    }

    case "$LANG" in
      python)
        _append_gitignore "__pycache__/"
        _append_gitignore "*.py[cod]"
        _append_gitignore ".venv/"
        _append_gitignore "dist/"
        _append_gitignore "*.egg-info/"
        _append_gitignore ".pytest_cache/"
        _append_gitignore ".mypy_cache/"
        cat > "$_lang_mk" <<'EOF'
# Makefile.lang.mk — python preset (included by Makefile)
PYTHON ?= python3
VENV   ?= .venv

## test          Run the test suite
test:
	@$(PYTHON) -m pytest -q

## lint          Run ruff + mypy
lint:
	@$(PYTHON) -m ruff check .
	@$(PYTHON) -m mypy .

## venv          Create .venv and install deps
venv:
	@$(PYTHON) -m venv $(VENV)
	@$(VENV)/bin/pip install -q -e ".[dev]"
EOF
        ;;
      node)
        _append_gitignore "node_modules/"
        _append_gitignore "dist/"
        _append_gitignore ".next/"
        _append_gitignore "coverage/"
        cat > "$_lang_mk" <<'EOF'
# Makefile.lang.mk — node preset (included by Makefile)

## test          Run the test suite
test:
	@npm test

## lint          Run eslint
lint:
	@npm run lint

## build         Build the project
build:
	@npm run build
EOF
        ;;
      go)
        _append_gitignore "bin/"
        _append_gitignore "*.test"
        _append_gitignore "*.out"
        cat > "$_lang_mk" <<'EOF'
# Makefile.lang.mk — go preset (included by Makefile)

## test          Run go test ./...
test:
	@go test ./... -count=1

## lint          Run golangci-lint
lint:
	@golangci-lint run ./...

## build         Build the binary
build:
	@go build -o bin/$(notdir $(CURDIR)) ./...
EOF
        ;;
      rust)
        _append_gitignore "target/"
        _append_gitignore "Cargo.lock"
        cat > "$_lang_mk" <<'EOF'
# Makefile.lang.mk — rust preset (included by Makefile)

## test          Run cargo test
test:
	@cargo test

## lint          Run clippy
lint:
	@cargo clippy -- -D warnings

## build         Build in release mode
build:
	@cargo build --release
EOF
        ;;
    esac
    log_ok "  + Makefile.lang.mk ($LANG)"
    log_ok "  + .gitignore updated"
  else
    log_info "  + would write: Makefile.lang.mk ($LANG)"
    log_info "  + would update: .gitignore"
  fi
fi

echo >&2
log_ok "🎉 scaffold complete → $TARGET"
echo >&2
log_info "Next steps:"
log_dim  "  cd $TARGET"
log_dim  "  make help"
log_dim  "  make doctor"
log_dim  "  xops/agent/session-bootstrap.sh"
