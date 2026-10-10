# warble-onboarding/windows/install-devtools.ps1
# Non-interactive dev toolchain for Warble engineers on Windows 11.
# Prefer the interactive windows/setup.ps1 (documented in README.md); this
# script is kept for unattended installs.
# Run as: PowerShell -ExecutionPolicy Bypass -File install-devtools.ps1 [-WithDocker]
# Docker Desktop is OFF by default (Warble policy) — pass -WithDocker to opt in.
# Idempotent — safe to re-run
#Requires -RunAsAdministrator
param([switch]$WithDocker)

$ErrorActionPreference = "Stop"

function Step  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok    { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Skip  { param($msg) Write-Host "  [--] $msg (already installed)" -ForegroundColor Yellow }
function Winget { param([Parameter(Mandatory)][string]$Id) winget install --id $Id --exact --silent --accept-source-agreements --accept-package-agreements }

# ── WINGET BOOTSTRAP ─────────────────────────────────────────────────────────
Step "Checking winget..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  winget not found. Installing App Installer from Microsoft Store..." -ForegroundColor Yellow
    Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    Read-Host "  Install 'App Installer' from the Store, then press Enter to continue"
}
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements 2>$null
Ok "winget"

# ── SCOOP (for tools not in winget) ──────────────────────────────────────────
Step "Installing Scoop..."
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    scoop bucket add extras
    scoop bucket add versions
    Ok "scoop"
} else {
    Skip "scoop"
}

# ── GIT ───────────────────────────────────────────────────────────────────────
Step "Installing Git..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Winget "Git.Git"
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Ok "git"
} else {
    Skip "git $(git --version 2>$null)"
}

# ── CORE CLI TOOLS ────────────────────────────────────────────────────────────
Step "Installing core CLI tools..."
$cliTools = @(
    @{ Id = "jqlang.jq";         Name = "jq"      },
    @{ Id = "sharkdp.ripgrep";   Name = "ripgrep" },
    @{ Id = "sharkdp.fd";        Name = "fd"      },
    @{ Id = "sharkdp.bat";       Name = "bat"     },
    @{ Id = "junegunn.fzf";      Name = "fzf"     },
    @{ Id = "stedolan.jq";       Name = "jq"      }
)
foreach ($tool in $cliTools) {
    if (-not (Get-Command $tool.Name -ErrorAction SilentlyContinue)) {
        winget install --id $tool.Id --silent --accept-source-agreements --accept-package-agreements 2>$null
        Ok $tool.Name
    } else {
        Skip $tool.Name
    }
}

if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
    winget install --id MikeFarah.yq --silent --accept-source-agreements --accept-package-agreements
    Ok "yq"
} else {
    Skip "yq"
}

# ── GO ────────────────────────────────────────────────────────────────────────
Step "Installing Go (latest stable via winget)..."
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    winget install --id GoLang.Go --exact --silent --accept-source-agreements --accept-package-agreements
    $env:PATH = $env:PATH + ";C:\Program Files\Go\bin;$env:USERPROFILE\go\bin"
    [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")
    Ok "go"
} else {
    Skip "go $(go version 2>$null)"
}

# ── NODE.JS (via nvm-windows) ─────────────────────────────────────────────────
Step "Installing Node.js 22 via nvm-windows..."
if (-not (Get-Command nvm -ErrorAction SilentlyContinue)) {
    winget install --id CoreyButler.NVMforWindows --silent --accept-source-agreements --accept-package-agreements
    # Reload PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    & nvm install 22
    & nvm use 22
    Ok "node 22 via nvm-windows"
} else {
    Skip "nvm-windows"
}

# ── PYTHON (via uv) ───────────────────────────────────────────────────────────
Step "Installing Python + uv..."
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    powershell -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex"
    Ok "uv"
} else {
    Skip "uv"
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    winget install --id Python.Python.3.12 --silent --accept-source-agreements --accept-package-agreements
    Ok "python 3.12"
} else {
    Skip "python"
}

# ── DOCKER DESKTOP (optional — off by default) ───────────────────────────────
if ($WithDocker) {
    Step "Installing Docker Desktop (-WithDocker)..."
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        winget install --id Docker.DockerDesktop --silent --accept-source-agreements --accept-package-agreements
        Ok "docker desktop (launch from Start Menu to start the daemon)"
    } else {
        Skip "docker desktop"
    }
} else {
    Step "Skipping Docker Desktop (default). Re-run with -WithDocker to install."
}

# ── KUBECTL ───────────────────────────────────────────────────────────────────
Step "Installing kubectl..."
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    winget install --id Kubernetes.kubectl --silent --accept-source-agreements --accept-package-agreements
    Ok "kubectl"
} else {
    Skip "kubectl $(kubectl version --client --short 2>$null)"
}

# ── HELM ──────────────────────────────────────────────────────────────────────
Step "Installing Helm..."
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    winget install --id Helm.Helm --silent --accept-source-agreements --accept-package-agreements
    Ok "helm"
} else {
    Skip "helm"
}

# ── OPENTOFU ─────────────────────────────────────────────────────────────────
Step "Installing OpenTofu (Terraform OSS fork)..."
if (-not (Get-Command tofu -ErrorAction SilentlyContinue)) {
    winget install --id OpenTofu.OpenTofu --silent --accept-source-agreements --accept-package-agreements
    Ok "opentofu"
} else {
    Skip "opentofu"
}

# ── TERRAFORM ─────────────────────────────────────────────────────────────────
Step "Installing Terraform (legacy compat)..."
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    winget install --id Hashicorp.Terraform --silent --accept-source-agreements --accept-package-agreements
    Ok "terraform"
} else {
    Skip "terraform"
}

# ── GCLOUD CLI ────────────────────────────────────────────────────────────────
Step "Installing Google Cloud CLI..."
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    winget install --id Google.CloudSDK --silent --accept-source-agreements --accept-package-agreements
    Ok "gcloud"
} else {
    Skip "gcloud"
}

# ── K9S ───────────────────────────────────────────────────────────────────────
Step "Installing k9s (Kubernetes TUI)..."
if (-not (Get-Command k9s -ErrorAction SilentlyContinue)) {
    winget install --id Derailed.k9s --silent --accept-source-agreements --accept-package-agreements
    Ok "k9s"
} else {
    Skip "k9s"
}

# ── OLLAMA ────────────────────────────────────────────────────────────────────
Step "Installing Ollama (local LLM runtime)..."
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    winget install --id Ollama.Ollama --silent --accept-source-agreements --accept-package-agreements
    Ok "ollama"
    Write-Host ""
    Write-Host "  Pull a model to get started:" -ForegroundColor Yellow
    Write-Host "    ollama pull llama3.2        # 2GB, good general purpose"
    Write-Host "    ollama pull mistral         # 4GB, strong coding"
    Write-Host "    ollama pull nomic-embed-text # embedding model for pgvector RAG"
} else {
    Skip "ollama"
}

# ── GITHUB CLI ────────────────────────────────────────────────────────────────
Step "Installing GitHub CLI..."
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
    Ok "gh"
} else {
    Skip "gh"
}

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
Step "Installing AWS CLI v2..."
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    winget install --id Amazon.AWSCLI --silent --accept-source-agreements --accept-package-agreements
    Ok "aws cli"
} else {
    Skip "aws cli"
}

# ── AZURE CLI ─────────────────────────────────────────────────────────────────
Step "Installing Azure CLI..."
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.AzureCLI --silent --accept-source-agreements --accept-package-agreements
    Ok "azure cli"
} else {
    Skip "azure cli"
}

# ── LAZYGIT ───────────────────────────────────────────────────────────────────
Step "Installing lazygit..."
if (-not (Get-Command lazygit -ErrorAction SilentlyContinue)) {
    winget install --id JesseDuffield.lazygit --silent --accept-source-agreements --accept-package-agreements
    Ok "lazygit"
} else {
    Skip "lazygit"
}

# ── VSCODE ────────────────────────────────────────────────────────────────────
Step "Installing VS Code..."
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.VisualStudioCode --silent --accept-source-agreements --accept-package-agreements
    Ok "vscode"
} else {
    Skip "vscode"
}

# ── WINDOWS TERMINAL ─────────────────────────────────────────────────────────
Step "Installing Windows Terminal..."
if (-not (Get-Command wt -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.WindowsTerminal --silent --accept-source-agreements --accept-package-agreements
    Ok "windows terminal"
} else {
    Skip "windows terminal"
}

# ── WSL2 (optional prompt) ────────────────────────────────────────────────────
Step "Checking WSL2..."
$wslStatus = wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  WSL2 not configured. To install Ubuntu on WSL2 run:" -ForegroundColor Yellow
    Write-Host "    wsl --install -d Ubuntu-24.04" -ForegroundColor Yellow
} else {
    Skip "wsl2"
}

# ── GIT CONFIG ────────────────────────────────────────────────────────────────
Step "Git global config..."
git config --global core.editor "code --wait"
git config --global pull.rebase true
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true
git config --global core.autocrlf true
Ok "git config"

# ── FINAL ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host " Warble dev toolchain installed." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Reload shell:  . `$PROFILE" -ForegroundColor Cyan
Write-Host " Auth GCP:      gcloud auth login" -ForegroundColor Cyan
Write-Host " Auth AWS:      aws configure" -ForegroundColor Cyan
Write-Host " Auth Azure:    az login" -ForegroundColor Cyan
Write-Host " Auth GitHub:   gh auth login" -ForegroundColor Cyan
Write-Host " Docker:        off by default (re-run with -WithDocker)" -ForegroundColor Cyan
Write-Host " Start Ollama:  ollama serve" -ForegroundColor Cyan
Write-Host " Pull model:    ollama pull llama3.2" -ForegroundColor Cyan
Write-Host " Launch k9s:    k9s" -ForegroundColor Cyan
Write-Host ""
Write-Host " NOTE: Restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
Write-Host ""
