#!/usr/bin/env bash
# warble-onboarding/mac/setup.sh
# Interactive installer for Warble dev toolchain on macOS (Apple Silicon + Intel)
# Run as: bash setup.sh
# Idempotent — safe to re-run
set -euo pipefail

# ── DEPS CHECK ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # add brew to PATH for Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        grep -q 'homebrew' "$HOME/.zprofile" 2>/dev/null || \
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
fi

if ! command -v whiptail &>/dev/null; then
    brew install newt 2>/dev/null || true
fi

# ── COLOURS ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step()  { echo -e "\n${GREEN}==>${NC} ${CYAN}$1${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
skip()  { echo -e "  ${YELLOW}–${NC} $1 (already installed)"; }

# ── WHIPTAIL TOOL SELECTION ───────────────────────────────────────────────────
CHOICES=$(whiptail --title "Warble Dev Toolchain (macOS)" \
    --checklist "Select tools to install (SPACE to toggle, ENTER to confirm):" \
    30 70 22 \
    "core"       "Core CLI tools (git, curl, jq, fzf, tmux…)"  ON \
    "zsh"        "Zsh + Oh-My-Zsh"                              ON \
    "go"         "Go (latest via Homebrew)"                     ON \
    "node"       "Node.js 22 (via nvm)"                         ON \
    "uv"         "Python uv (fast package manager)"             ON \
    "docker"     "Docker Desktop (optional; off by default)"    OFF \
    "kind"       "kind (needs a container runtime)"             OFF \
    "kubectl"    "kubectl"                                      ON \
    "helm"       "Helm 3"                                       ON \
    "k9s"        "k9s (Kubernetes TUI)"                         ON \
    "tofu"       "OpenTofu (Terraform OSS fork)"                ON \
    "terraform"  "Terraform (legacy compat)"                    OFF \
    "gcloud"     "Google Cloud CLI + GKE auth plugin"           ON \
    "awscli"     "AWS CLI v2"                                   ON \
    "azurecli"   "Azure CLI"                                    ON \
    "gh"         "GitHub CLI"                                   ON \
    "lazygit"    "lazygit"                                      ON \
    "vscode"     "VS Code"                                      ON \
    "ollama"     "Ollama (local LLM runtime)"                   OFF \
    "goose"      "Goose CLI (primary coding agent)"             ON \
    "claude"     "Claude Code CLI (Anthropic credits)"          ON \
    "browseros"  "BrowserOS (agentic browser)"                  ON \
    "gitcfg"     "Git global config (editor, rebase, branch)"   ON \
    3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 0; }

selected=$(echo "$CHOICES" | tr -d '"')
has() { echo "$selected" | grep -qw "$1"; }

step "Starting installation..."
brew update --quiet

# ── CORE TOOLS ────────────────────────────────────────────────────────────────
if has core; then
    step "Installing core tools..."
    brew install \
        git curl wget jq yq unzip \
        pkg-config \
        htop ncdu iotop \
        ripgrep fd bat tldr \
        tmux fzf direnv \
        python3 \
        2>/dev/null || true
    ok "core tools"
fi

# ── ZSH + OH-MY-ZSH ──────────────────────────────────────────────────────────
if has zsh; then
    step "Setting up Oh-My-Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        ok "oh-my-zsh"
    else
        skip "oh-my-zsh"
    fi
    # zsh is default on macOS 10.15+ — no chsh needed
fi

# ── GO ────────────────────────────────────────────────────────────────────────
if has go; then
    step "Installing Go..."
    if ! command -v go &>/dev/null; then
        brew install go
        ok "go $(go version 2>/dev/null | awk '{print $3}')"
    else
        skip "go $(go version 2>/dev/null | awk '{print $3}')"
    fi
fi

# ── NODE (via nvm) ────────────────────────────────────────────────────────────
if has node; then
    step "Installing Node.js 22 via nvm..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        nvm install 22 && nvm alias default 22
        ok "node 22 via nvm"
    else
        skip "nvm (already installed)"
    fi
fi

# ── PYTHON UV ─────────────────────────────────────────────────────────────────
if has uv; then
    step "Installing uv..."
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        ok "uv"
    else
        skip "uv"
    fi
fi

# ── DOCKER DESKTOP ────────────────────────────────────────────────────────────
if has docker; then
    step "Installing Docker Desktop..."
    if ! command -v docker &>/dev/null; then
        brew install --cask docker
        ok "docker desktop (launch from Applications to start the daemon)"
    else
        skip "docker"
    fi
fi

# ── KIND ──────────────────────────────────────────────────────────────────────
if has kind; then
    step "Installing kind..."
    if ! command -v kind &>/dev/null; then
        brew install kind
        ok "kind $(kind version 2>/dev/null | head -1)"
    else
        skip "kind"
    fi
fi

# ── KUBECTL ───────────────────────────────────────────────────────────────────
if has kubectl; then
    step "Installing kubectl..."
    if ! command -v kubectl &>/dev/null; then
        brew install kubectl
        ok "kubectl $(kubectl version --client 2>/dev/null | head -1)"
    else
        skip "kubectl"
    fi
fi

# ── HELM ──────────────────────────────────────────────────────────────────────
if has helm; then
    step "Installing Helm..."
    if ! command -v helm &>/dev/null; then
        brew install helm
        ok "helm $(helm version --short 2>/dev/null)"
    else
        skip "helm"
    fi
fi

# ── K9S ───────────────────────────────────────────────────────────────────────
if has k9s; then
    step "Installing k9s..."
    if ! command -v k9s &>/dev/null; then
        brew install derailed/k9s/k9s
        ok "k9s"
    else
        skip "k9s"
    fi
fi

# ── OPENTOFU ──────────────────────────────────────────────────────────────────
if has tofu; then
    step "Installing OpenTofu..."
    if ! command -v tofu &>/dev/null; then
        brew install opentofu
        ok "opentofu $(tofu version 2>/dev/null | head -1)"
    else
        skip "opentofu"
    fi
fi

# ── TERRAFORM ─────────────────────────────────────────────────────────────────
if has terraform; then
    step "Installing Terraform..."
    if ! command -v terraform &>/dev/null; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
        ok "terraform $(terraform version 2>/dev/null | head -1)"
    else
        skip "terraform"
    fi
fi

# ── GCLOUD CLI ────────────────────────────────────────────────────────────────
if has gcloud; then
    step "Installing Google Cloud CLI..."
    if ! command -v gcloud &>/dev/null; then
        brew install --cask google-cloud-sdk
        ok "gcloud"
    else
        skip "gcloud"
    fi
fi

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
if has awscli; then
    step "Installing AWS CLI v2..."
    if ! command -v aws &>/dev/null; then
        brew install awscli
        ok "aws $(aws --version 2>&1 | head -1)"
    else
        skip "aws cli"
    fi
fi

# ── AZURE CLI ─────────────────────────────────────────────────────────────────
if has azurecli; then
    step "Installing Azure CLI..."
    if ! command -v az &>/dev/null; then
        brew install azure-cli
        ok "az $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
    else
        skip "azure cli"
    fi
fi

# ── GITHUB CLI ────────────────────────────────────────────────────────────────
if has gh; then
    step "Installing GitHub CLI..."
    if ! command -v gh &>/dev/null; then
        brew install gh
        ok "gh $(gh version 2>/dev/null | head -1)"
    else
        skip "gh"
    fi
fi

# ── LAZYGIT ───────────────────────────────────────────────────────────────────
if has lazygit; then
    step "Installing lazygit..."
    if ! command -v lazygit &>/dev/null; then
        brew install lazygit
        ok "lazygit"
    else
        skip "lazygit"
    fi
fi

# ── VSCODE ────────────────────────────────────────────────────────────────────
if has vscode; then
    step "Installing VS Code..."
    if ! command -v code &>/dev/null; then
        brew install --cask visual-studio-code
        ok "vscode"
    else
        skip "vscode"
    fi
fi

# ── OLLAMA ────────────────────────────────────────────────────────────────────
if has ollama; then
    step "Installing Ollama..."
    if ! command -v ollama &>/dev/null; then
        brew install ollama
        ok "ollama"
        echo ""
        echo "  Pull a model:  ollama pull llama3.2"
    else
        skip "ollama"
    fi
fi

# ── GOOSE (primary coding agent) ──────────────────────────────────────────────
if has goose; then
    step "Installing Goose CLI..."
    if ! command -v goose &>/dev/null; then
        curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
            | CONFIGURE=false bash
        grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        export PATH="$HOME/.local/bin:$PATH"
        ok "goose (configure: goose configure)"
    else
        skip "goose"
    fi
fi

# ── CLAUDE CODE (Anthropic CLI credits) ───────────────────────────────────────
if has claude; then
    step "Installing Claude Code CLI..."
    if ! command -v claude &>/dev/null; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        if command -v npm &>/dev/null; then
            npm install -g @anthropic-ai/claude-code@latest
            ok "claude (auth: claude)"
        else
            echo "  npm not available — select Node, re-run, or: npm i -g @anthropic-ai/claude-code"
        fi
    else
        skip "claude"
    fi
fi

# ── BROWSEROS (agentic browser) ───────────────────────────────────────────────
if has browseros; then
    step "Installing BrowserOS..."
    if [ ! -d "/Applications/BrowserOS.app" ]; then
        brew install --cask browseros
        ok "BrowserOS (connect xAI / Anthropic / Ollama keys in settings)"
    else
        skip "BrowserOS.app"
    fi
fi

# ── GIT CONFIG ────────────────────────────────────────────────────────────────
if has gitcfg; then
    step "Git global config..."
    git config --global core.editor "code --wait"
    git config --global pull.rebase true
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true
    git config --global core.autocrlf input
    ok "git config"
fi

# ── FINAL ─────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo " Warble dev toolchain installed (macOS)."
echo "════════════════════════════════════════════════"
echo ""
echo " Reload shell:  source ~/.zshrc"
echo " Auth GCP:      gcloud auth login"
echo " Auth AWS:      aws configure"
echo " Auth Azure:    az login"
echo " Auth GitHub:   gh auth login"
echo " Goose:         goose configure   # Anthropic first while credits last, then xAI"
echo " Claude Code:   claude            # Anthropic CLI credits"
echo " Docker:        off by default; if selected, open Docker.app"
echo " kind cluster:  kind create cluster  # needs a container runtime"
echo " Launch k9s:    k9s"
echo ""
