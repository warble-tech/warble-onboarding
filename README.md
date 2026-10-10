# warble-onboarding

Dev toolchain setup for Warble engineers. Pick your platform and run one script.

## AI stack (Grok + Anthropic + Goose + BrowserOS)

| Tool | Role |
|------|------|
| **Goose** | Primary local coding agent |
| **Claude Code** | Anthropic CLI — burn **org Anthropic credits first** |
| **BrowserOS** | Agentic browser (BYO keys) |
| **xAI console** | PAYG for Grok when not on Anthropic |
| **Antigravity** | Optional — Google agentic IDE + `agy` CLI ([ai/07](./ai/07-antigravity-setup.md)) |

→ **[ai/README.md](./ai/README.md)** — console, PAYG costs, **2h/day budget**, Goose, Anthropic credits.

**Cost target:** ~2 hours of agent work per day; prefer Anthropic CLI credits, then xAI. See [ai/05-cost-optimization-2h.md](./ai/05-cost-optimization-2h.md).

**Containers:** Docker is **not** installed by default. Use GKE for clusters; opt in to Docker/Rancher only if you need local containers.

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
kubectl, helm, k9s, kind (optional runtime),
OpenTofu, Terraform, gcloud CLI, Ollama, GitHub CLI, lazygit, VS Code,
**Goose CLI**, **Claude Code**, **BrowserOS**

Optional Docker CE:

```bash
WARBLE_INSTALL_DOCKER=1 bash install-devtools.sh
```

**System tuning scripts** (run separately as root):

| Script | What it does |
|--------|-------------|
| `minimal-gui.sh` | Removes bloat, disables noisy services, tunes GNOME |
| `apply.sh` | TLP power profile, CPU governor (powersave), turbo off |
| `openbox-setup.sh` | Installs lightweight Openbox WM as alternative to GNOME |
| `kernel-cleanup-rancher.sh` | Kernel cleanup; optional Rancher path if you want nerdctl |

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

Or Brewfile only:

```bash
brew bundle --file=mac/Brewfile
```

**What it installs:**
git, curl, jq, yq, ripgrep, fd, bat, fzf, tldr, tmux, zsh plugins,
Go, Node 22 (via nvm), Python 3.12 + uv,
kubectl, helm, k9s, kubectx, kind (needs runtime if used),
OpenTofu, Terraform, gcloud SDK, Ollama, GitHub CLI, lazygit,
VS Code, iTerm2, Rectangle, JetBrains Mono Nerd Font,
**Goose** (cask + CLI), **Claude Code**, BrowserOS (manual DMG if needed)

Docker Desktop is **not** in the Brewfile. Optional:

```bash
brew install --cask rancher   # preferred local runtime
# or: brew install --cask docker
```

---

## Windows 11

Run PowerShell **as Administrator**:

```powershell
git clone https://github.com/warble-tech/warble-onboarding.git
cd warble-onboarding\windows
PowerShell -ExecutionPolicy Bypass -File setup.ps1
```

Interactive checklist: **Docker off by default**; **Goose / Claude Code / BrowserOS on by default**.

For a full Linux environment on Windows:

```powershell
wsl --install -d Ubuntu-24.04
# Then follow the Linux instructions inside WSL
```

---

## Post-install (all platforms)

```bash
# Authenticate cloud tools
gcloud auth login
gcloud config set project warble-tech   # or your project
gh auth login

# AI agents
goose configure          # Anthropic first if credits; also xAI
claude                   # Anthropic CLI login / credits
# BrowserOS: open app → connect xAI / Anthropic / Ollama keys

# Optional local LLM
ollama serve &
ollama pull llama3.2

# Kubernetes (remote GKE preferred)
k9s
```

---

## Tool reference

| Tool | Purpose |
|------|---------|
| `goose` | Primary coding agent (xAI / Anthropic) |
| `claude` | Anthropic Claude Code CLI |
| BrowserOS | Agentic browser |
| `agy` | Google Antigravity CLI (optional) |
| `tofu` | OpenTofu — Terraform OSS fork |
| `terraform` | Terraform — legacy compat |
| `gcloud` | Google Cloud CLI |
| `kubectl` / `k9s` | Kubernetes CLI / TUI |
| `helm` | Kubernetes package manager |
| `ollama` | Local LLM runtime |
| `uv` | Fast Python package manager |
| `gh` | GitHub CLI |
| `lazygit` | Terminal git UI |
| Docker / Rancher | **Optional** local containers only |

---

## Related repos

| Repo | Notes |
|------|--------|
| `warble-tech/warble-bootstrap` | **Private** — bootstrap / platform manifests |
| `warble-tech/warble-onboarding` | This repo (public or team) |
