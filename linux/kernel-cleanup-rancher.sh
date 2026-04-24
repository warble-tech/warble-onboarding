#!/usr/bin/env bash
# kernel-cleanup-rancher.sh
# 1. Remove old kernel (6.17.0-20) — frees ~200 MB from /boot
# 2. Install Rancher Desktop (lightweight Docker alternative)
# Run as: sudo bash kernel-cleanup-rancher.sh
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}  (skipped)${NC} $1"; }

RUNNING=$(uname -r)
OLD_KERNEL="6.17.0-20-generic"

# ── 1. KERNEL CLEANUP ────────────────────────────────────────────────────────
step "Running kernel: $RUNNING"
step "Removing old kernel: $OLD_KERNEL"

if [ "$RUNNING" = "$OLD_KERNEL" ]; then
    echo "ERROR: You are currently running the old kernel. Reboot first, then re-run."
    exit 1
fi

OLD_PKGS=(
    linux-image-${OLD_KERNEL}
    linux-headers-${OLD_KERNEL}
    linux-modules-${OLD_KERNEL}
    linux-modules-extra-${OLD_KERNEL}
)

for pkg in "${OLD_PKGS[@]}"; do
    if dpkg -l "$pkg" &>/dev/null; then
        apt-get remove -y --purge "$pkg"
        echo "  removed: $pkg"
    else
        warn "$pkg not installed"
    fi
done

apt-get autoremove -y --purge
update-grub 2>&1 | tail -5

echo ""
echo "/boot usage after cleanup:"
du -sh /boot
ls -lh /boot/vmlinuz* /boot/initrd*

# ── 2. RANCHER DESKTOP ───────────────────────────────────────────────────────
step "Installing Rancher Desktop v1.22.0..."

# Why Rancher Desktop over Docker Desktop:
# - Free for all use (no BSL license issues)
# - containerd + nerdctl (lighter than dockerd)
# - Built-in k3s for local Kubernetes
# - Uses less RAM than Docker Desktop (~400 MB vs ~800 MB)

RANCHER_DEB="/tmp/rancher-desktop-1.22.0-amd64.deb"
RANCHER_URL="https://github.com/rancher-sandbox/rancher-desktop/releases/download/v1.22.0/rancher-desktop-1.22.0-amd64.deb"

if ! which rdctl &>/dev/null; then
    echo "  Downloading Rancher Desktop deb..."
    curl -L --progress-bar "$RANCHER_URL" -o "$RANCHER_DEB"
    apt-get install -y "$RANCHER_DEB"
    rm -f "$RANCHER_DEB"
    echo "  Rancher Desktop installed."
else
    warn "Rancher Desktop already installed ($(rdctl version 2>/dev/null || echo unknown))"
fi

# ── 3. POST-INSTALL: nerdctl alias ───────────────────────────────────────────
step "Setting up nerdctl → docker alias for $SUDO_USER..."
PROFILE=/home/${SUDO_USER}/.bashrc
ZSH_PROFILE=/home/${SUDO_USER}/.zshrc

ALIAS_BLOCK='
# Rancher Desktop — nerdctl aliased as docker
export PATH="$HOME/.rd/bin:$PATH"
alias docker="nerdctl"
alias docker-compose="nerdctl compose"
'

for f in "$PROFILE" "$ZSH_PROFILE"; do
    if [ -f "$f" ] && ! grep -q "nerdctl aliased" "$f"; then
        echo "$ALIAS_BLOCK" >> "$f"
        echo "  added alias to $f"
    fi
done

# ── 4. FINAL SUMMARY ─────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo " Done."
echo "════════════════════════════════════════"
echo ""
echo "Kernel cleanup:"
echo "  Running:  $RUNNING"
echo "  Removed:  $OLD_KERNEL"
df -h /boot
echo ""
echo "Rancher Desktop:"
echo "  Launch from app menu or: rancher-desktop &"
echo "  First launch: choose containerd (not dockerd) for lower RAM"
echo "  nerdctl is your docker CLI — alias 'docker' now points to it"
echo ""
echo "Setup after first launch:"
echo "  rdctl set --container-engine.name=containerd"
echo "  rdctl set --kubernetes.enabled=false   # disable k3s if you don't need k8s"
echo "  nerdctl run hello-world                # verify"
echo ""
echo "Memory comparison:"
echo "  Docker Desktop:   ~800 MB RSS"
echo "  Rancher Desktop:  ~400 MB RSS (containerd, no k8s)"
echo "  Rancher Desktop:  ~700 MB RSS (containerd + k3s)"
echo ""
