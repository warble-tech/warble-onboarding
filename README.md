# warble-onboarding

Dev toolchain setup for Warble engineers. Pick your platform and run one script.

---

## Linux (Ubuntu 22.04 / 24.04)

```bash
git clone https://github.com/warble-tech/warble-onboarding.git
cd warble-onboarding/linux
bash install-devtools.sh
```

**What it installs:**
git, curl, jq, ripgrep, fd, bat, fzf, tmux, zsh + oh-my-zsh, direnv,
Go 1.24, Node 22 (via nvm), Python 3 + uv,
Rancher Desktop (nerdctl as docker), kubectl, helm, k9s,
OpenTofu, Terraform, gcloud CLI, Ollama, GitHub CLI, lazygit, VS Code

**System tuning scripts** (run separately as root):

| Script | What it does |
|--------|-------------|
| `minimal-gui.sh` | Removes bloat, disables noisy services, tunes GNOME |
| `apply.sh` | TLP power profile, CPU governor (powersave), turbo off |
| `openbox-setup.sh` | Installs lightweight Openbox WM as alternative to GNOME |
| `kernel-cleanup-rancher.sh` | Removes old kernel, installs Rancher Desktop |

```bash
sudo bash linux/minimal-gui.sh
sudo bash linux/apply.sh
```

---

## macOS (Apple Silicon + Intel)

```bash
git clone https://github.com/warble-tech/warble-onboarding.git
cd warble-onboarding/mac
bash install-devtools.sh
```

Or if you prefer to manage everything manually via Homebrew:

```bash
brew bundle --file=mac/Brewfile
```

**What it installs (via Homebrew):**
git, curl, jq, yq, ripgrep, fd, bat, fzf, tldr, tmux, zsh plugins,
Go, Node 22 (via nvm), Python 3.12 + uv,
Rancher Desktop (nerdctl), kubectl, helm, k9s, kubectx,
OpenTofu, Terraform, gcloud SDK, Ollama, GitHub CLI, lazygit,
VS Code, iTerm2, Rectangle, JetBrains Mono Nerd Font

After first launch of **Rancher Desktop**, select `containerd` (not dockerd) in Preferences.

---

## Windows 11

Run PowerShell **as Administrator**:

```powershell
git clone https://github.com/warble-tech/warble-onboarding.git
cd warble-onboarding\windows
PowerShell -ExecutionPolicy Bypass -File install-devtools.ps1
```

**What it installs (via winget + scoop):**
Git, jq, ripgrep, fd, bat, fzf, yq,
Go, Node 22 (via nvm-windows), Python 3.12 + uv,
Rancher Desktop (nerdctl), kubectl, helm, k9s,
OpenTofu, Terraform, gcloud CLI, Ollama, GitHub CLI, lazygit,
VS Code, Windows Terminal

For a full Linux environment on Windows, also run:

```powershell
wsl --install -d Ubuntu-24.04
# Then follow the Linux instructions inside WSL
```

---

## Post-install (all platforms)

```bash
# Authenticate cloud tools
gcloud auth login
gcloud config set project warble-cloud
gh auth login

# Start local LLM runtime
ollama serve &
ollama pull llama3.2          # 2 GB, general purpose
ollama pull nomic-embed-text  # embedding model for RAG

# Verify container runtime
nerdctl run --rm hello-world

# Kubernetes
k9s    # TUI — point at your kubeconfig cluster
```

---

## Tool reference

| Tool | Purpose |
|------|---------|
| `nerdctl` / `docker` alias | Container CLI (Rancher Desktop) |
| `rdctl` | Rancher Desktop daemon control |
| `tofu` | OpenTofu — Terraform OSS fork |
| `terraform` | Terraform — legacy compat |
| `gcloud` | Google Cloud CLI |
| `kubectl` / `k9s` | Kubernetes CLI / TUI |
| `helm` | Kubernetes package manager |
| `ollama` | Local LLM runtime |
| `uv` | Fast Python package manager |
| `gh` | GitHub CLI |
| `lazygit` | Terminal git UI |
| `k9s` | Kubernetes cluster TUI |
