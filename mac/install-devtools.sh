#!/usr/bin/env bash
# warble-onboarding/mac/install-devtools.sh
# Full dev toolchain for Warble engineers on macOS (Apple Silicon + Intel)
# Run as: bash install-devtools.sh
# Idempotent — safe to re-run
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${GREEN}==>${NC} ${CYAN}$1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
skip() { echo -e "  ${YELLOW}–${NC} $1 (already installed)"; }

ARCH=$(uname -m)   # arm64 or x86_64
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── XCODE CLI TOOLS ──────────────────────────────────────────────────────────
step "Checking Xcode CLI tools..."
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "  Xcode CLI tools installation launched. Wait for it to complete, then re-run this script."
    exit 0
else
    skip "xcode-select"
fi

# ── HOMEBREW ─────────────────────────────────────────────────────────────────
step "Installing Homebrew..."
if ! which brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon: add brew to PATH immediately
    if [ "$ARCH" = "arm64" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    ok "homebrew"
else
    skip "homebrew $(brew --version | head -1)"
fi

# Ensure brew is on PATH for the rest of this script
if [ "$ARCH" = "arm64" ] && [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── BREW BUNDLE ──────────────────────────────────────────────────────────────
step "Installing all tools via Brewfile..."
brew update --quiet
brew bundle --file="$SCRIPT_DIR/Brewfile" --no-upgrade 2>&1 | grep -v "^Using\|^Skipping" || true
ok "brew bundle"

# ── ZSH SETUP ─────────────────────────────────────────────────────────────────
step "Configuring Zsh..."
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# zsh-autosuggestions
if ! grep -q 'zsh-autosuggestions' "$ZSHRC"; then
    if [ "$ARCH" = "arm64" ]; then
        echo 'source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> "$ZSHRC"
    else
        echo 'source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> "$ZSHRC"
    fi
fi

# zsh-syntax-highlighting
if ! grep -q 'zsh-syntax-highlighting' "$ZSHRC"; then
    if [ "$ARCH" = "arm64" ]; then
        echo 'source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> "$ZSHRC"
    else
        echo 'source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> "$ZSHRC"
    fi
fi

# fzf key bindings
[ -f ~/.fzf.zsh ] || $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash
grep -q 'fzf.zsh' "$ZSHRC" || echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >> "$ZSHRC"

ok "zsh config"

# ── NVM + NODE 22 ─────────────────────────────────────────────────────────────
step "Setting up nvm + Node 22..."
NVM_DIR="$HOME/.nvm"
if ! grep -q 'NVM_DIR' "$ZSHRC"; then
    {
        echo ''
        echo 'export NVM_DIR="$HOME/.nvm"'
        echo '[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"'
        echo '[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && . "$(brew --prefix nvm)/etc/bash_completion.d/nvm"'
    } >> "$ZSHRC"
fi
export NVM_DIR="$HOME/.nvm"
NVM_SCRIPT="$(brew --prefix nvm)/nvm.sh"
[ -s "$NVM_SCRIPT" ] && . "$NVM_SCRIPT"
if ! node --version 2>/dev/null | grep -q 'v22'; then
    nvm install 22 && nvm alias default 22
    ok "node 22 via nvm"
else
    skip "node 22"
fi

# ── GO PATH ──────────────────────────────────────────────────────────────────
step "Configuring Go PATH..."
if ! grep -q 'go/bin' "$ZSHRC"; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> "$ZSHRC"
fi
ok "go $(go version 2>/dev/null | awk '{print $3}')"

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
step "Installing AWS CLI v2..."
if ! command -v aws &>/dev/null; then
    brew install awscli
    ok "aws $(aws --version 2>&1 | head -1)"
else
    skip "aws cli"
fi

# ── AZURE CLI ─────────────────────────────────────────────────────────────────
step "Installing Azure CLI..."
if ! command -v az &>/dev/null; then
    brew install azure-cli
    ok "az $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
else
    skip "azure cli"
fi

# ── GCLOUD COMPONENTS ─────────────────────────────────────────────────────────
step "Installing gcloud GKE auth plugin..."
if which gcloud &>/dev/null; then
    gcloud components install gke-gcloud-auth-plugin --quiet 2>/dev/null || true
    ok "gke-gcloud-auth-plugin"
fi

# ── GOOSE CLI ─────────────────────────────────────────────────────────────────
step "Installing Goose CLI..."
if ! command -v goose &>/dev/null; then
    curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
        | CONFIGURE=false bash
    grep -q '\.local/bin' "$ZSHRC" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    export PATH="$HOME/.local/bin:$PATH"
    ok "goose CLI"
    echo "    Configure: goose configure  # xAI Grok and/or Anthropic"
else
    skip "goose"
fi

# ── GOOGLE ANTIGRAVITY (desktop + agy CLI) — optional ─────────────────────────
# Opt-in: WARBLE_INSTALL_ANTIGRAVITY=1 bash install-devtools.sh  ·  guide: ai/07-antigravity-setup.md
if [ "${WARBLE_INSTALL_ANTIGRAVITY:-0}" = "1" ]; then
    step "Installing Google Antigravity..."
    if [ ! -d "/Applications/Antigravity.app" ]; then
        brew install --cask antigravity || echo "  cask failed — download: https://antigravity.google/download"
    else
        skip "Antigravity.app"
    fi
    if ! command -v agy &>/dev/null; then
        curl -fsSL https://antigravity.google/cli/install.sh | bash
        export PATH="$HOME/.local/bin:$PATH"
        ok "agy CLI (sign in on first run: agy)"
    else
        skip "agy"
    fi
fi

# ── CLAUDE CODE (Anthropic CLI credits) ───────────────────────────────────────
step "Installing Claude Code CLI..."
if ! command -v claude &>/dev/null; then
    export NVM_DIR="$HOME/.nvm"
    NVM_SCRIPT="$(brew --prefix nvm)/nvm.sh"
    [ -s "$NVM_SCRIPT" ] && . "$NVM_SCRIPT"
    if command -v npm &>/dev/null; then
        npm install -g @anthropic-ai/claude-code@latest
        ok "claude (Anthropic Claude Code)"
    else
        echo "  ${YELLOW}npm missing — nvm install 22 then: npm i -g @anthropic-ai/claude-code${NC}"
    fi
else
    skip "claude"
fi

# ── BROWSEROS ─────────────────────────────────────────────────────────────────
step "BrowserOS (agentic browser)..."
if [ ! -d "/Applications/BrowserOS.app" ]; then
    # Normally installed by the Brewfile (cask "browseros"); retry here if that failed
    if brew install --cask browseros; then
        ok "BrowserOS (cask)"
    else
        echo "  Download DMG: https://files.browseros.com/download/BrowserOS.dmg"
        echo "  Docs:         https://docs.browseros.com/browseros/onboarding"
    fi
else
    skip "BrowserOS.app"
fi

# ── GIT CONFIG ────────────────────────────────────────────────────────────────
step "Git global config..."
git config --global core.editor "code --wait"
git config --global pull.rebase true
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true
git config --global core.autocrlf input
ok "git config"

# ── FINAL ─────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo " Warble dev toolchain installed."
echo "════════════════════════════════════════════════"
echo ""
echo " Reload shell:  source ~/.zshrc"
echo " Auth GCP:      gcloud auth login"
echo " Auth AWS:      aws configure"
echo " Auth Azure:    az login"
echo " Auth GitHub:   gh auth login"
echo " Goose:         goose configure   # xAI + Anthropic"
echo " Claude Code:   claude            # Anthropic credits"
echo " BrowserOS:     open BrowserOS.app; wire API keys (docs.browseros.com)"
echo " Containers:    Docker Desktop NOT installed by default"
echo "                Optional: brew install --cask rancher  # or docker"
echo " Start Ollama:  ollama serve"
echo " Pull model:    ollama pull llama3.2"
echo " Launch k9s:    k9s"
echo " AI guide:      warble-onboarding/ai/README.md"
echo ""
