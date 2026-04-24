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

# ── RANCHER DESKTOP (nerdctl) aliases ─────────────────────────────────────────
step "Adding nerdctl aliases..."
if ! grep -q 'nerdctl aliased' "$ZSHRC"; then
    cat >> "$ZSHRC" << 'ALIAS'

# Rancher Desktop — nerdctl aliased as docker
export PATH="$HOME/.rd/bin:$PATH"
alias docker="nerdctl"
alias docker-compose="nerdctl compose"
alias d="nerdctl"
alias dc="nerdctl compose"
alias dps="nerdctl ps"
alias dimg="nerdctl images"
alias dlogs="nerdctl logs -f"
alias dexec="nerdctl exec -it"
alias dprune="nerdctl system prune -f"
ALIAS
    ok "nerdctl aliases"
fi

# ── GCLOUD COMPONENTS ─────────────────────────────────────────────────────────
step "Installing gcloud GKE auth plugin..."
if which gcloud &>/dev/null; then
    gcloud components install gke-gcloud-auth-plugin --quiet 2>/dev/null || true
    ok "gke-gcloud-auth-plugin"
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
echo " Auth GitHub:   gh auth login"
echo " Start Ollama:  ollama serve"
echo " Pull model:    ollama pull llama3.2"
echo " Launch k9s:    k9s"
echo ""
echo " Rancher Desktop: launch from Applications, choose containerd."
echo ""
