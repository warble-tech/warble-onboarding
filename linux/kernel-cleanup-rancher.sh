#!/usr/bin/env bash
# kernel-cleanup-rancher.sh
# 1. Remove old kernel (6.17.0-20) — frees ~200 MB from /boot
# 2. Install Docker CE
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

# ── 2. DOCKER CE ─────────────────────────────────────────────────────────────
step "Installing Docker CE (docker CLI mode)..."

ARCH=$(dpkg --print-architecture)
CODENAME=$(. /etc/os-release; echo "$VERSION_CODENAME")

if ! command -v docker &>/dev/null; then
    # remove any conflicting old source file
    rm -f /etc/apt/sources.list.d/docker.list

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    tee /etc/apt/sources.list.d/docker.sources > /dev/null << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    apt-get update -qq
    apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    usermod -aG docker "$SUDO_USER"
    echo "  Docker CE installed."
else
    warn "Docker already installed ($(docker version --format '{{.Server.Version}}' 2>/dev/null || echo unknown))"
fi

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
echo "Docker CE:"
echo "  Verify:           docker run hello-world"
echo "  Re-login or:      newgrp docker   (to run without sudo)"
echo "  Compose:          docker compose up"
echo ""
