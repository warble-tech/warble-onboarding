#!/usr/bin/env bash
# warble-onboarding/linux/setup.sh
# Interactive installer for Warble dev toolchain on Ubuntu 22.04 / 24.04
# Run as: bash setup.sh
# Idempotent — safe to re-run
set -euo pipefail

# ── DEPS CHECK ────────────────────────────────────────────────────────────────
if ! command -v whiptail &>/dev/null; then
    sudo apt-get install -y whiptail 2>/dev/null
fi

# ── COLOURS ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
step()  { echo -e "\n${GREEN}==>${NC} ${CYAN}$1${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
skip()  { echo -e "  ${YELLOW}–${NC} $1 (already installed)"; }
warn()  { echo -e "  ${YELLOW}!${NC} $1"; }
err()   { echo -e "  ${RED}✗${NC} $1"; }

ARCH=$(dpkg --print-architecture)
CODENAME=$(. /etc/os-release; echo "$VERSION_CODENAME")
# Map dpkg arch to the names used by upstream release assets
case "$ARCH" in
    amd64) BIN_ARCH=amd64; LG_ARCH=x86_64; AWS_ARCH=x86_64 ;;
    arm64) BIN_ARCH=arm64; LG_ARCH=arm64;  AWS_ARCH=aarch64 ;;
    *) echo "Unsupported architecture: $ARCH (expected amd64 or arm64)"; exit 1 ;;
esac

# ── WHIPTAIL TOOL SELECTION ───────────────────────────────────────────────────
CHOICES=$(whiptail --title "Warble Dev Toolchain" \
    --checklist "Select tools to install (SPACE to toggle, ENTER to confirm):" \
    30 70 22 \
    "core"       "Core CLI tools (git, curl, jq, fzf, tmux…)" ON \
    "zsh"        "Zsh + Oh-My-Zsh"                             ON \
    "go"         "Go 1.27"                                     ON \
    "node"       "Node.js 22 (via nvm)"                        ON \
    "uv"         "Python uv (fast package manager)"            ON \
    "docker"     "Docker CE (optional; off by default)"        OFF \
    "kind"       "kind (needs a container runtime)"            OFF \
    "kubectl"    "kubectl"                                     ON \
    "helm"       "Helm 3"                                      ON \
    "k9s"        "k9s (Kubernetes TUI)"                        ON \
    "tofu"       "OpenTofu (Terraform OSS fork)"               ON \
    "terraform"  "Terraform (legacy compat)"                   OFF \
    "gcloud"     "Google Cloud CLI + GKE auth plugin"          ON \
    "gh"         "GitHub CLI"                                  ON \
    "lazygit"    "lazygit"                                     ON \
    "vscode"     "VS Code"                                     ON \
    "awscli"     "AWS CLI v2"                                   ON \
    "azurecli"   "Azure CLI"                                   ON \
    "ollama"     "Ollama (local LLM runtime)"                  OFF \
    "goose"      "Goose CLI (primary coding agent)"            ON \
    "claude"     "Claude Code CLI (Anthropic credits)"         ON \
    "browseros"  "BrowserOS (agentic browser)"                 ON \
    "gitcfg"     "Git global config (editor, rebase, branch)"  ON \
    3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 0; }

# strip quotes from whiptail output
selected=$(echo "$CHOICES" | tr -d '"')

has() { echo "$selected" | grep -qw "$1"; }

step "Starting installation…"
sudo apt-get update -qq

# ── CORE TOOLS ────────────────────────────────────────────────────────────────
if has core; then
    step "Installing core tools…"
    sudo apt-get install -y \
        git curl wget jq yq unzip zip \
        build-essential pkg-config \
        ca-certificates gnupg lsb-release \
        htop ncdu iotop nethogs \
        ripgrep fd-find bat tldr \
        tmux zsh fzf direnv \
        python3 python3-pip python3-venv \
        whiptail

    # Ubuntu ships fd/bat as fdfind/batcat — expose the upstream names
    mkdir -p "$HOME/.local/bin"
    command -v fdfind &>/dev/null && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    command -v batcat &>/dev/null && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    ok "core tools"
fi

# ── ZSH + OH-MY-ZSH ──────────────────────────────────────────────────────────
if has zsh; then
    step "Setting up Zsh + Oh-My-Zsh…"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        ok "oh-my-zsh"
    else
        skip "oh-my-zsh"
    fi
    sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || true
fi

# ── GO ────────────────────────────────────────────────────────────────────────
if has go; then
    GO_VERSION="1.27.2"
    step "Installing Go $GO_VERSION…"
    if ! go version 2>/dev/null | grep -q "$GO_VERSION"; then
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${BIN_ARCH}.tar.gz" -o /tmp/go.tar.gz
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
            grep -q '/usr/local/go/bin' "$rc" 2>/dev/null || \
                echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$rc"
        done
        ok "go $GO_VERSION"
    else
        skip "go $GO_VERSION"
    fi
fi

# ── NODE (via nvm) ────────────────────────────────────────────────────────────
if has node; then
    step "Installing Node.js 22 via nvm…"
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
    step "Installing uv…"
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        ok "uv"
    else
        skip "uv"
    fi
fi

# ── DOCKER CE ─────────────────────────────────────────────────────────────────
if has docker; then
    step "Installing Docker CE…"
    if ! command -v docker &>/dev/null; then
        # remove conflicting old sources
        sudo rm -f /etc/apt/sources.list.d/docker.list

        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # write as .sources (DEB822 format) — no duplicate with .list
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
        ok "docker ce (re-login or 'newgrp docker' to use without sudo)"
    else
        skip "docker"
    fi
fi

# ── KIND ──────────────────────────────────────────────────────────────────────
if has kind; then
    step "Installing kind…"
    if ! command -v kind &>/dev/null; then
        KIND_VER=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-${BIN_ARCH}" -o /tmp/kind
        sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
        rm /tmp/kind
        ok "kind $KIND_VER"
    else
        skip "kind $(kind version 2>/dev/null | head -1)"
    fi
fi

# ── KUBECTL ───────────────────────────────────────────────────────────────────
if has kubectl; then
    step "Installing kubectl…"
    if ! command -v kubectl &>/dev/null; then
        K8S_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
        curl -fsSL "https://dl.k8s.io/release/${K8S_VER}/bin/linux/${BIN_ARCH}/kubectl" -o /tmp/kubectl
        sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
        rm /tmp/kubectl
        ok "kubectl $K8S_VER"
    else
        skip "kubectl $(kubectl version --client 2>/dev/null | head -1)"
    fi
fi

# ── HELM ──────────────────────────────────────────────────────────────────────
if has helm; then
    step "Installing Helm…"
    if ! command -v helm &>/dev/null; then
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        ok "helm $(helm version --short 2>/dev/null)"
    else
        skip "helm"
    fi
fi

# ── K9S ───────────────────────────────────────────────────────────────────────
if has k9s; then
    step "Installing k9s…"
    if ! command -v k9s &>/dev/null; then
        K9S_VER=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_${BIN_ARCH}.tar.gz" \
            -o /tmp/k9s.tar.gz
        sudo tar -C /usr/local/bin -xzf /tmp/k9s.tar.gz k9s
        rm /tmp/k9s.tar.gz
        ok "k9s $K9S_VER"
    else
        skip "k9s"
    fi
fi

# ── OPENTOFU ──────────────────────────────────────────────────────────────────
if has tofu; then
    step "Installing OpenTofu…"
    if ! command -v tofu &>/dev/null; then
        curl -fsSL https://get.opentofu.org/install-opentofu.sh | sudo bash -s -- --install-method deb
        ok "opentofu $(tofu version 2>/dev/null | head -1)"
    else
        skip "opentofu"
    fi
fi

# ── TERRAFORM ─────────────────────────────────────────────────────────────────
if has terraform; then
    step "Installing Terraform…"
    if ! command -v terraform &>/dev/null; then
        if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
            curl -fsSL https://apt.releases.hashicorp.com/gpg \
                | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        fi
        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com ${CODENAME} main" \
            | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y terraform
        ok "terraform $(terraform version 2>/dev/null | head -1)"
    else
        skip "terraform"
    fi
fi

# ── GCLOUD CLI ────────────────────────────────────────────────────────────────
if has gcloud; then
    step "Installing Google Cloud CLI…"
    if ! command -v gcloud &>/dev/null; then
        if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
            curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
                | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        fi
        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/cloud.google.gpg] \
https://packages.cloud.google.com/apt cloud-sdk main" \
            | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin
        ok "gcloud"
    else
        skip "gcloud"
    fi
fi

# ── GITHUB CLI ────────────────────────────────────────────────────────────────
if has gh; then
    step "Installing GitHub CLI…"
    if ! command -v gh &>/dev/null; then
        if [ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
        fi
        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y gh
        ok "gh $(gh version 2>/dev/null | head -1)"
    else
        skip "gh"
    fi
fi

# ── LAZYGIT ───────────────────────────────────────────────────────────────────
if has lazygit; then
    step "Installing lazygit…"
    if ! command -v lazygit &>/dev/null; then
        LG_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_linux_${LG_ARCH}.tar.gz" \
            -o /tmp/lazygit.tar.gz
        sudo tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit
        rm /tmp/lazygit.tar.gz
        ok "lazygit $LG_VER"
    else
        skip "lazygit"
    fi
fi

# ── VSCODE ────────────────────────────────────────────────────────────────────
if has vscode; then
    step "Installing VS Code…"
    if ! command -v code &>/dev/null; then
        if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
                | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
        fi
        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
            | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y code
        ok "vscode"
    else
        skip "vscode"
    fi
fi

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
if has awscli; then
    step "Installing AWS CLI v2…"
    if ! command -v aws &>/dev/null; then
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o /tmp/awscliv2.zip
        unzip -q /tmp/awscliv2.zip -d /tmp/awscli
        sudo /tmp/awscli/aws/install
        rm -rf /tmp/awscliv2.zip /tmp/awscli
        ok "aws $(aws --version 2>&1 | head -1)"
    else
        skip "aws cli $(aws --version 2>&1 | head -1)"
    fi
fi

# ── AZURE CLI ─────────────────────────────────────────────────────────────────
if has azurecli; then
    step "Installing Azure CLI…"
    if ! command -v az &>/dev/null; then
        if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
                | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
        fi
        echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/microsoft-prod.gpg] \
https://packages.microsoft.com/repos/azure-cli/ ${CODENAME} main" \
            | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y azure-cli
        ok "az $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
    else
        skip "azure cli $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
    fi
fi

# ── OLLAMA ────────────────────────────────────────────────────────────────────
if has ollama; then
    step "Installing Ollama…"
    if ! command -v ollama &>/dev/null; then
        curl -fsSL https://ollama.com/install.sh | sh
        ok "ollama"
        echo ""
        echo "  Pull a model to get started:"
        echo "    ollama pull llama3.2         # 2 GB, good general purpose"
        echo "    ollama pull mistral          # 4 GB, strong coding"
        echo "    ollama pull nomic-embed-text # embedding model for pgvector RAG"
    else
        skip "ollama"
    fi
fi

# ── GOOSE (primary coding agent) ──────────────────────────────────────────────
if has goose; then
    step "Installing Goose CLI…"
    if ! command -v goose &>/dev/null; then
        curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
            | CONFIGURE=false bash
        for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
            grep -q '\.local/bin' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        done
        export PATH="$HOME/.local/bin:$PATH"
        ok "goose (configure: goose configure)"
    else
        skip "goose"
    fi
fi

# ── CLAUDE CODE (Anthropic CLI credits) ───────────────────────────────────────
if has claude; then
    step "Installing Claude Code CLI…"
    if ! command -v claude &>/dev/null; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        if command -v npm &>/dev/null; then
            npm install -g @anthropic-ai/claude-code@latest
            ok "claude (auth: claude)"
        else
            warn "npm not available — select Node, re-run, or: npm i -g @anthropic-ai/claude-code"
        fi
    else
        skip "claude"
    fi
fi

# ── BROWSEROS (agentic browser) ───────────────────────────────────────────────
if has browseros; then
    step "Installing BrowserOS…"
    if ! command -v browseros &>/dev/null && [ ! -d /opt/browseros ] \
        && [ ! -f /usr/share/applications/browseros.desktop ]; then
        if curl -fsSL https://cdn.browseros.com/download/BrowserOS.deb -o /tmp/BrowserOS.deb; then
            sudo apt-get install -y /tmp/BrowserOS.deb || warn "BrowserOS .deb install failed"
            rm -f /tmp/BrowserOS.deb
            ok "BrowserOS (connect xAI / Anthropic / Ollama keys in settings)"
        else
            warn "download failed — AppImage: https://files.browseros.com/download/BrowserOS.AppImage"
        fi
    else
        skip "BrowserOS"
    fi
fi

# ── GIT CONFIG ────────────────────────────────────────────────────────────────
if has gitcfg; then
    step "Git global config…"
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
echo " Warble dev toolchain installed."
echo "════════════════════════════════════════════════"
echo ""
echo " Reload shell:  source ~/.zshrc"
echo " Auth GCP:      gcloud auth login"
echo " Auth AWS:      aws configure"
echo " Auth Azure:    az login"
echo " Auth GitHub:   gh auth login"
echo " Goose:         goose configure   # Anthropic first while credits last, then xAI"
echo " Claude Code:   claude            # Anthropic CLI credits"
echo " Docker:        off by default; if selected: newgrp docker (or re-login)"
echo " List clusters: kind get clusters  # needs a container runtime if local"
echo " Start Ollama:  ollama serve"
echo " Launch k9s:    k9s"
echo ""
