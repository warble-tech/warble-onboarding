#Requires -RunAsAdministrator
# warble-onboarding/windows/setup.ps1
# Interactive installer for Warble dev toolchain on Windows 11 / 10
# Run as: Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup.ps1
# Idempotent — safe to re-run

$ErrorActionPreference = "Stop"

# ── COLOUR HELPERS ───────────────────────────────────────────────────────────
function Step  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok    { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Skip  { param($msg) Write-Host "  [--] $msg (already installed)" -ForegroundColor Yellow }
function Warn  { param($msg) Write-Host "  [!]  $msg" -ForegroundColor Yellow }

# ── WINGET CHECK ─────────────────────────────────────────────────────────────
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    exit 1
}

# ── TOOL SELECTION (console checklist) ───────────────────────────────────────
$allTools = [ordered]@{
    core       = @{ label = "Core CLI tools (git, curl, jq, fzf, 7zip...)";  default = $true  }
    ohmyposh   = @{ label = "Oh My Posh (PowerShell prompt)";                 default = $true  }
    go         = @{ label = "Go 1.24";                                         default = $true  }
    node       = @{ label = "Node.js 22 LTS";                                  default = $true  }
    uv         = @{ label = "Python uv (fast package manager)";                default = $true  }
    docker     = @{ label = "Docker Desktop";                                  default = $true  }
    kind       = @{ label = "kind (Kubernetes in Docker)";                     default = $true  }
    kubectl    = @{ label = "kubectl";                                         default = $true  }
    helm       = @{ label = "Helm 3";                                          default = $true  }
    k9s        = @{ label = "k9s (Kubernetes TUI)";                            default = $true  }
    tofu       = @{ label = "OpenTofu (Terraform OSS fork)";                   default = $true  }
    terraform  = @{ label = "Terraform (legacy compat)";                       default = $false }
    gcloud     = @{ label = "Google Cloud CLI + GKE auth plugin";              default = $true  }
    awscli     = @{ label = "AWS CLI v2";                                      default = $true  }
    azurecli   = @{ label = "Azure CLI";                                       default = $true  }
    gh         = @{ label = "GitHub CLI";                                      default = $true  }
    lazygit    = @{ label = "lazygit";                                         default = $true  }
    vscode     = @{ label = "VS Code";                                         default = $true  }
    wt         = @{ label = "Windows Terminal";                                default = $true  }
    ollama     = @{ label = "Ollama (local LLM runtime)";                      default = $false }
    gitcfg     = @{ label = "Git global config (editor, rebase, branch)";      default = $true  }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Warble Dev Toolchain — Windows Setup" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select tools (Y/n, Enter = keep default):" -ForegroundColor White
Write-Host ""

$selected = @{}
foreach ($key in $allTools.Keys) {
    $tool    = $allTools[$key]
    $default = if ($tool.default) { "Y" } else { "n" }
    $prompt  = "  [$default] $($tool.label)"
    $input   = Read-Host $prompt
    if ($input -eq "") { $input = $default }
    $selected[$key] = ($input -match '^[Yy]')
}

function Has { param($key) return $selected[$key] -eq $true }

function WingetInstall {
    param($id, $name, $extra = "")
    Step "Installing $name..."
    $installed = winget list --id $id --exact -q 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match $id) {
        Skip $name
    } else {
        $cmd = "winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements"
        if ($extra) { $cmd += " $extra" }
        Invoke-Expression $cmd
        Ok $name
    }
}

Step "Updating winget sources..."
winget source update | Out-Null

# ── CORE CLI TOOLS ───────────────────────────────────────────────────────────
if (Has "core") {
    WingetInstall "Git.Git"          "Git"
    WingetInstall "jqlang.jq"        "jq"
    WingetInstall "junegunn.fzf"     "fzf"
    WingetInstall "7zip.7zip"        "7-Zip"
    WingetInstall "sharkdp.bat"      "bat"
    WingetInstall "BurntSushi.ripgrep.MSVC" "ripgrep"
    WingetInstall "sharkdp.fd"       "fd"
    WingetInstall "tldr-pages.tlrc"  "tldr"
    WingetInstall "Neovim.Neovim"    "Neovim" "--scope machine"
}

# ── OH MY POSH ───────────────────────────────────────────────────────────────
if (Has "ohmyposh") {
    Step "Installing Oh My Posh..."
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        winget install --id JanDeDobbeleer.OhMyPosh --exact --silent `
            --accept-package-agreements --accept-source-agreements
        # Add to PowerShell profile
        $profileLine = 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\tokyo.omp.json" | Invoke-Expression'
        if (-not (Test-Path $PROFILE)) { New-Item -Path $PROFILE -Force | Out-Null }
        if (-not (Select-String -Path $PROFILE -Pattern "oh-my-posh" -Quiet)) {
            Add-Content -Path $PROFILE -Value "`n$profileLine"
        }
        Ok "oh-my-posh (profile updated)"
    } else {
        Skip "oh-my-posh"
    }
}

# ── GO ───────────────────────────────────────────────────────────────────────
if (Has "go") {
    WingetInstall "GoLang.Go" "Go 1.24"
}

# ── NODE.JS ───────────────────────────────────────────────────────────────────
if (Has "node") {
    WingetInstall "OpenJS.NodeJS.LTS" "Node.js 22 LTS"
}

# ── PYTHON UV ────────────────────────────────────────────────────────────────
if (Has "uv") {
    Step "Installing uv..."
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
        Ok "uv"
    } else {
        Skip "uv"
    }
}

# ── DOCKER DESKTOP ───────────────────────────────────────────────────────────
if (Has "docker") {
    WingetInstall "Docker.DockerDesktop" "Docker Desktop"
}

# ── KIND ─────────────────────────────────────────────────────────────────────
if (Has "kind") {
    Step "Installing kind..."
    if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
        $kindVer = (Invoke-RestMethod https://api.github.com/repos/kubernetes-sigs/kind/releases/latest).tag_name
        $kindUrl = "https://kind.sigs.k8s.io/dl/$kindVer/kind-windows-amd64.exe"
        $dest    = "$env:LOCALAPPDATA\Microsoft\WindowsApps\kind.exe"
        Invoke-WebRequest $kindUrl -OutFile $dest
        Ok "kind $kindVer"
    } else {
        Skip "kind"
    }
}

# ── KUBECTL ──────────────────────────────────────────────────────────────────
if (Has "kubectl") {
    WingetInstall "Kubernetes.kubectl" "kubectl"
}

# ── HELM ─────────────────────────────────────────────────────────────────────
if (Has "helm") {
    WingetInstall "Helm.Helm" "Helm 3"
}

# ── K9S ──────────────────────────────────────────────────────────────────────
if (Has "k9s") {
    WingetInstall "Derailed.k9s" "k9s"
}

# ── OPENTOFU ─────────────────────────────────────────────────────────────────
if (Has "tofu") {
    WingetInstall "OpenTofu.Tofu" "OpenTofu"
}

# ── TERRAFORM ────────────────────────────────────────────────────────────────
if (Has "terraform") {
    WingetInstall "Hashicorp.Terraform" "Terraform"
}

# ── GCLOUD CLI ───────────────────────────────────────────────────────────────
if (Has "gcloud") {
    WingetInstall "Google.CloudSDK" "Google Cloud CLI"
}

# ── AWS CLI v2 ───────────────────────────────────────────────────────────────
if (Has "awscli") {
    WingetInstall "Amazon.AWSCLI" "AWS CLI v2"
}

# ── AZURE CLI ────────────────────────────────────────────────────────────────
if (Has "azurecli") {
    WingetInstall "Microsoft.AzureCLI" "Azure CLI"
}

# ── GITHUB CLI ───────────────────────────────────────────────────────────────
if (Has "gh") {
    WingetInstall "GitHub.cli" "GitHub CLI"
}

# ── LAZYGIT ──────────────────────────────────────────────────────────────────
if (Has "lazygit") {
    WingetInstall "JesseDuffield.lazygit" "lazygit"
}

# ── VSCODE ───────────────────────────────────────────────────────────────────
if (Has "vscode") {
    WingetInstall "Microsoft.VisualStudioCode" "VS Code"
}

# ── WINDOWS TERMINAL ─────────────────────────────────────────────────────────
if (Has "wt") {
    WingetInstall "Microsoft.WindowsTerminal" "Windows Terminal"
}

# ── OLLAMA ───────────────────────────────────────────────────────────────────
if (Has "ollama") {
    WingetInstall "Ollama.Ollama" "Ollama"
    Write-Host ""
    Write-Host "  Pull a model:  ollama pull llama3.2" -ForegroundColor Yellow
}

# ── GIT CONFIG ───────────────────────────────────────────────────────────────
if (Has "gitcfg") {
    Step "Git global config..."
    git config --global core.editor "code --wait"
    git config --global pull.rebase true
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true
    git config --global core.autocrlf true
    Ok "git config"
}

# ── FINAL ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Warble dev toolchain installed (Windows)." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Restart your terminal to pick up PATH changes." -ForegroundColor White
Write-Host ""
Write-Host "  Auth GCP:      gcloud auth login"
Write-Host "  Auth AWS:      aws configure"
Write-Host "  Auth Azure:    az login"
Write-Host "  Auth GitHub:   gh auth login"
Write-Host "  Docker:        launch Docker Desktop from Start Menu"
Write-Host "  kind cluster:  kind create cluster"
Write-Host "  Launch k9s:    k9s"
Write-Host ""
