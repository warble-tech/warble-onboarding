#!/usr/bin/env bash
# warble-onboarding/linux/install-devtools.sh
# Full dev toolchain for Warble engineers on Ubuntu 22.04 / 24.04
# Run as: bash install-devtools.sh
# Idempotent — safe to re-run
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${GREEN}==>${NC} ${CYAN}$1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
skip() { echo -e "  ${YELLOW}–${NC} $1 (already installed)"; }

ARCH=$(dpkg --print-architecture)
CODENAME=$(. /etc/os-release; echo "$VERSION_CODENAME")

step "Updating apt..."
sudo apt-get update -qq

# ── CORE TOOLS ───────────────────────────────────────────────────────────────
step "Installing core tools..."
sudo apt-get install -y \
    git curl wget jq yq unzip zip \
    build-essential pkg-config \
    ca-certificates gnupg lsb-release \
    htop ncdu iotop nethogs \
    ripgrep fd-find bat tldr \
    tmux zsh fzf direnv \
    python3 python3-pip python3-venv \
    2>/dev/null
ok "core tools"

# ── ZSH + OH-MY-ZSH ──────────────────────────────────────────────────────────
step "Setting up Zsh + Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "oh-my-zsh"
else
    skip "oh-my-zsh"
fi
sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || true

# ── GO ────────────────────────────────────────────────────────────────────────
step "Installing Go 1.24..."
GO_VERSION="1.24.2"
if ! go version 2>/dev/null | grep -q "$GO_VERSION"; then
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    grep -q '/usr/local/go/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.zshrc"
    grep -q '/usr/local/go/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc"
    ok "go $GO_VERSION"
else
    skip "go $GO_VERSION"
fi

# ── NODE (via nvm) ────────────────────────────────────────────────────────────
step "Installing Node.js 22 via nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install 22 && nvm alias default 22
    ok "node 22 via nvm"
else
    skip "nvm"
fi

# ── PYTHON UV ─────────────────────────────────────────────────────────────────
step "Installing uv (fast Python package manager)..."
if ! which uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ok "uv"
else
    skip "uv"
fi

# ── CONTAINER RUNTIME (optional — Docker CE off by default) ───────────────────
# Warble default: no Docker Desktop / Docker CE. Use remote GKE or install
# Rancher Desktop (nerdctl) when you need local clusters.
# Opt-in: WARBLE_INSTALL_DOCKER=1 bash install-devtools.sh
if [ "${WARBLE_INSTALL_DOCKER:-0}" = "1" ]; then
    step "Installing Docker CE (WARBLE_INSTALL_DOCKER=1)..."
    if ! command -v docker &>/dev/null; then
        sudo rm -f /etc/apt/sources.list.d/docker.list
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF
        sudo apt-get update -qq
        sudo apt-get install -y \
            docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker "$USER"
        ok "docker ce (re-login or 'newgrp docker')"
    else
        skip "docker"
    fi
else
    step "Skipping Docker CE (default). Set WARBLE_INSTALL_DOCKER=1 to install."
    ok "no local Docker — use GKE / optional Rancher Desktop"
fi

# ── KUBECTL ───────────────────────────────────────────────────────────────────
step "Installing kubectl..."
if ! which kubectl &>/dev/null; then
    K8S_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${K8S_VER}/bin/linux/amd64/kubectl" -o /tmp/kubectl
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm /tmp/kubectl
    ok "kubectl $K8S_VER"
else
    skip "kubectl $(kubectl version --client --short 2>/dev/null | head -1)"
fi

# ── KIND ──────────────────────────────────────────────────────────────────────
step "Installing kind..."
if ! command -v kind &>/dev/null; then
    KIND_VER=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-amd64" -o /tmp/kind
    sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
    rm /tmp/kind
    ok "kind $KIND_VER"
else
    skip "kind $(kind version 2>/dev/null | head -1)"
fi

# ── HELM ──────────────────────────────────────────────────────────────────────
step "Installing Helm..."
if ! which helm &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ok "helm $(helm version --short 2>/dev/null)"
else
    skip "helm"
fi

# ── TERRAFORM / OPENTOFU ──────────────────────────────────────────────────────
step "Installing OpenTofu (Terraform OSS fork)..."
if ! which tofu &>/dev/null; then
    curl -fsSL https://get.opentofu.org/install-opentofu.sh | sudo bash -s -- --install-method deb
    ok "opentofu $(tofu version 2>/dev/null | head -1)"
else
    skip "opentofu"
fi

step "Installing Terraform (for legacy compat)..."
if ! which terraform &>/dev/null; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -qq && sudo apt-get install -y terraform
    ok "terraform $(terraform version 2>/dev/null | head -1)"
else
    skip "terraform"
fi

# ── GCLOUD CLI ────────────────────────────────────────────────────────────────
step "Installing Google Cloud CLI..."
if ! which gcloud &>/dev/null; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update -qq && sudo apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin
    ok "gcloud"
else
    skip "gcloud"
fi

# ── K9S ───────────────────────────────────────────────────────────────────────
step "Installing k9s (Kubernetes TUI)..."
if ! which k9s &>/dev/null; then
    K9S_VER=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
    curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_amd64.tar.gz" -o /tmp/k9s.tar.gz
    sudo tar -C /usr/local/bin -xzf /tmp/k9s.tar.gz k9s
    rm /tmp/k9s.tar.gz
    ok "k9s $K9S_VER"
else
    skip "k9s"
fi

# ── OLLAMA ────────────────────────────────────────────────────────────────────
step "Installing Ollama (local LLM runtime)..."
if ! which ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    ok "ollama"
    echo ""
    echo "  Pull a model to get started:"
    echo "    ollama pull llama3.2        # 2GB, good general purpose"
    echo "    ollama pull mistral         # 4GB, strong coding"
    echo "    ollama pull nomic-embed-text # embedding model for pgvector RAG"
else
    skip "ollama"
fi

# ── GOOSE (primary coding agent — xAI / Anthropic / multi-provider) ───────────
step "Installing Goose CLI..."
if ! command -v goose &>/dev/null; then
    curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
        | CONFIGURE=false bash
    # ensure ~/.local/bin on PATH
    grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    ok "goose $(goose --version 2>/dev/null | head -1 || echo installed)"
    echo "    Configure:  goose configure   # pick xAI (Grok) and/or Anthropic"
else
    skip "goose $(goose --version 2>/dev/null | head -1)"
fi

# ── CLAUDE CODE (Anthropic CLI — use existing Anthropic credits) ─────────────
step "Installing Claude Code CLI (Anthropic)..."
if ! command -v claude &>/dev/null; then
    # needs node/npm from nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    if command -v npm &>/dev/null; then
        npm install -g @anthropic-ai/claude-code@latest
        ok "claude (Anthropic Claude Code)"
        echo "    Auth:       claude   # or set ANTHROPIC_API_KEY"
    else
        echo "  ${YELLOW}npm not available yet — re-run after nvm/node, or: npm i -g @anthropic-ai/claude-code${NC}"
    fi
else
    skip "claude"
fi

# ── BROWSEROS (agentic browser) ───────────────────────────────────────────────
step "Installing BrowserOS (agentic Chromium)..."
if [ ! -d /opt/browseros ] && [ ! -f /usr/bin/browseros ] && ! command -v browseros &>/dev/null \
    && [ ! -f "$HOME/.local/share/BrowserOS/BrowserOS" ] \
    && [ ! -f /usr/share/applications/browseros.desktop ]; then
    DEB_URL="https://cdn.browseros.com/download/BrowserOS.deb"
    TMP_DEB="/tmp/BrowserOS.deb"
    if curl -fsSL "$DEB_URL" -o "$TMP_DEB"; then
        sudo apt-get install -y "$TMP_DEB" || sudo dpkg -i "$TMP_DEB" || true
        sudo apt-get install -f -y 2>/dev/null || true
        rm -f "$TMP_DEB"
        ok "BrowserOS (deb)"
        echo "    Launch from app menu; connect xAI / Anthropic / Ollama keys in settings"
    else
        echo "  ${YELLOW}deb download failed — install AppImage manually:${NC}"
        echo "    curl -fL -o ~/BrowserOS.AppImage https://files.browseros.com/download/BrowserOS.AppImage"
        echo "    chmod +x ~/BrowserOS.AppImage && ~/BrowserOS.AppImage"
    fi
else
    skip "BrowserOS"
fi

# ── GOOGLE ANTIGRAVITY CLI (agy) — optional ──────────────────────────────────
# Opt-in: WARBLE_INSTALL_ANTIGRAVITY=1 bash install-devtools.sh
# Docs: https://antigravity.google/docs/cli/install  ·  guide: ai/07-antigravity-setup.md
if [ "${WARBLE_INSTALL_ANTIGRAVITY:-0}" = "1" ]; then
    step "Installing Antigravity CLI (agy)..."
    if ! command -v agy &>/dev/null; then
        curl -fsSL https://antigravity.google/cli/install.sh | bash
        export PATH="$HOME/.local/bin:$PATH"
        ok "agy $(agy --version 2>/dev/null | head -1 || echo installed)"
        echo "    Sign in on first run: agy   ·  Desktop app: https://antigravity.google/download?os=linux"
    else
        skip "agy"
    fi
fi

# ── GITHUB CLI ────────────────────────────────────────────────────────────────
step "Installing GitHub CLI..."
if ! which gh &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
    sudo apt-get update -qq && sudo apt-get install -y gh
    ok "gh $(gh version 2>/dev/null | head -1)"
else
    skip "gh"
fi

# ── LAZYGIT ───────────────────────────────────────────────────────────────────
step "Installing lazygit..."
if ! which lazygit &>/dev/null; then
    LG_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name | sed 's/v//')
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" -o /tmp/lazygit.tar.gz
    sudo tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit
    rm /tmp/lazygit.tar.gz
    ok "lazygit $LG_VER"
else
    skip "lazygit"
fi

# ── VSCODE ────────────────────────────────────────────────────────────────────
step "Installing VS Code..."
if ! which code &>/dev/null; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update -qq && sudo apt-get install -y code
    ok "vscode"
else
    skip "vscode"
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
echo " Goose setup:   goose configure   # xAI + Anthropic providers"
echo " Claude Code:   claude            # Anthropic CLI credits"
echo " BrowserOS:     open from apps; wire API keys"
echo " Antigravity:   optional — WARBLE_INSTALL_ANTIGRAVITY=1 (see ai/07)"
echo " Docker:        skipped by default (WARBLE_INSTALL_DOCKER=1 to install)"
echo " List clusters: kind get clusters  # needs a container runtime if local"
echo " Start Ollama:  ollama serve"
echo " Pull model:    ollama pull llama3.2"
echo " Launch k9s:    k9s"
echo " AI guide:      warble-onboarding/ai/README.md"
echo ""
