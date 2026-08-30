#!/usr/bin/env bash
# =============================================================================
# dotfiles installer for opencode + agent skills
# Works on macOS and Linux (incl. WSL — the recommended way to run opencode
# on Windows, see install-windows.ps1 for the WSL bootstrap).
#
# Usage:
#   ./install.sh              full install (installs missing deps via brew/apt)
#   ./install.sh --skip-deps  skip dependency auto-install, warn only
# =============================================================================
set -euo pipefail

SKIP_DEPS=false
[[ "${1:-}" == "--skip-deps" ]] && SKIP_DEPS=true

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OC_DIR="$HOME/.config/opencode"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"

ARCHIFY_REPO="https://github.com/tt-a1i/archify.git"
OFFICE_SKILLS_REPO="https://github.com/tfriedel/claude-office-skills.git"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m  ✗\033[0m %s\n' "$*"; exit 1; }

OS="$(uname -s)"                 # Darwin / Linux
IS_LINUX=false; [[ "$OS" == "Linux" ]] && IS_LINUX=true

# -----------------------------------------------------------------------------
# 0. Prerequisites
# -----------------------------------------------------------------------------
need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    if [[ "$SKIP_DEPS" == true ]]; then
      warn "missing: $1 (use it or fix PATH, then re-run)"
      return 1
    fi
    info "installing missing dependency: $1"
    if [[ "$OS" == "Darwin" ]]; then
      command -v brew >/dev/null 2>&1 || fail "Homebrew required. Install: https://brew.sh"
      brew install "$2"
    else
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y "$2"
      else
        fail "Please install '$1' manually, then re-run."
      fi
    fi
  fi
}

need_cmd git git || true
need_cmd node node || true
need_cmd npm node || true

# uv (provides uvx) — not in apt/brew core everywhere; use official installer
if ! command -v uvx >/dev/null 2>&1; then
  if [[ "$SKIP_DEPS" == true ]]; then
    warn "missing: uvx (https://docs.astral.sh/uv/)"
  else
    info "installing uv (uvx) via official installer"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi

command -v git  >/dev/null 2>&1 || fail "git is required"
command -v node >/dev/null 2>&1 || fail "node >= 18 is required"
command -v uvx  >/dev/null 2>&1 || warn "uvx not found — uvx-based MCP servers (drawio-edit, macos-mcp, openproject) will not start"

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[[ "$NODE_MAJOR" -ge 18 ]] || fail "node >= 18 required, found $(node --version)"

# -----------------------------------------------------------------------------
# 1. opencode global config + plugin deps
# -----------------------------------------------------------------------------
info "opencode global config -> $OC_DIR"
mkdir -p "$OC_DIR"

if [[ -f "$OC_DIR/opencode.json" || -f "$OC_DIR/opencode.jsonc" ]]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  BACKUP="$OC_DIR/.backup-$TS"
  mkdir -p "$BACKUP"
  [[ -f "$OC_DIR/opencode.json"  ]] && cp "$OC_DIR/opencode.json"  "$BACKUP/"
  [[ -f "$OC_DIR/opencode.jsonc" ]] && cp "$OC_DIR/opencode.jsonc" "$BACKUP/"
  [[ -f "$OC_DIR/package.json"   ]] && cp "$OC_DIR/package.json"   "$BACKUP/"
  rm -f "$OC_DIR/opencode.json" "$OC_DIR/opencode.jsonc"
  ok "backed up previous config to $BACKUP"
fi

cp "$REPO_DIR/opencode/opencode.json" "$OC_DIR/opencode.json"
cp "$REPO_DIR/opencode/package.json"  "$OC_DIR/package.json"

# WSL/Linux: macos-mcp only works on macOS — disable it there
if [[ "$IS_LINUX" == true ]]; then
  node -e '
    const fs = require("fs");
    const p = process.env.HOME + "/.config/opencode/opencode.json";
    const c = JSON.parse(fs.readFileSync(p, "utf8"));
    if (c.mcp && c.mcp["macos-mcp"]) c.mcp["macos-mcp"].enabled = false;
    fs.writeFileSync(p, JSON.stringify(c, null, 2) + "\n");
  '
  ok "Linux detected: macos-mcp disabled (macOS-only)"
fi

# -----------------------------------------------------------------------------
# 2. Secrets (.env — never committed)
# -----------------------------------------------------------------------------
if [[ ! -f "$OC_DIR/.env" ]]; then
  cp "$REPO_DIR/.env.example" "$OC_DIR/.env"
  warn "created $OC_DIR/.env — FILL IN OP_BASE_URL and OP_API_KEY (openproject MCP needs them)"
else
  ok ".env already exists (left untouched)"
fi

info "npm install (plugin deps) in $OC_DIR"
(cd "$OC_DIR" && npm install --silent --no-fund --no-audit)
ok "node_modules ready"

# -----------------------------------------------------------------------------
# 3. Skills: hand-written (copied) + third-party (cloned from origin)
# -----------------------------------------------------------------------------
info "copying local skills"
mkdir -p "$OC_DIR/skills" "$CLAUDE_SKILLS_DIR"
cp -R "$REPO_DIR/opencode-skills/"* "$OC_DIR/skills/"
cp -R "$REPO_DIR/claude-skills/"*   "$CLAUDE_SKILLS_DIR/"
ok "macos-return-ghostty, agile-init, drawio, op-logtime"

info "cloning third-party skills from origin (kept out of this repo)"
if [[ ! -d "$OC_DIR/skills/archify" ]]; then
  git clone --depth 1 "$ARCHIFY_REPO" "$OC_DIR/skills/archify"
else
  ok "archify already present"
fi

if [[ ! -d "$CLAUDE_SKILLS_DIR/claude-office-skills" ]]; then
  git clone --depth 1 "$OFFICE_SKILLS_REPO" "$CLAUDE_SKILLS_DIR/claude-office-skills"
else
  ok "claude-office-skills already present"
fi

info "npm install for claude-office-skills (this takes a while)"
(cd "$CLAUDE_SKILLS_DIR/claude-office-skills" && npm install --silent --no-fund --no-audit)

# office-* symlinks (docx/pdf/pptx/pdf entry points used by claude code)
for ext in docx pdf pptx xlsx; do
  ln -sfn "claude-office-skills/public/$ext" "$CLAUDE_SKILLS_DIR/office-$ext"
done
ok "office-* symlinks created"

# -----------------------------------------------------------------------------
# 4. Azure / Microsoft agent skills
# -----------------------------------------------------------------------------
info "copying azure/foundry/entra skills -> $AGENTS_SKILLS_DIR"
mkdir -p "$AGENTS_SKILLS_DIR"
cp -R "$REPO_DIR/agents-skills/"* "$AGENTS_SKILLS_DIR/"
ok "$(ls "$REPO_DIR/agents-skills" | wc -l | tr -d ' ') skills installed"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
cat <<'EOF'

──────────────────────────────────────────────────────────────
 ✓ Install complete

 Next steps:
   1. Fill secrets if needed:   nano ~/.config/opencode/.env
        OP_BASE_URL, OP_API_KEY   (OpenProject MCP)
   2. Restart opencode so config + skills load.
   3. First ms365 use:          run /ms365 login inside opencode
      (OAuth browser flow; config already uses org-mode + read-only).
   4. On Windows? Everything above ran INSIDE WSL — that is correct.
──────────────────────────────────────────────────────────────
EOF
