#!/usr/bin/env bash
# minimal-gui.sh — lightweight GNOME + package cleanup for warble workstation
# Run as: sudo bash minimal-gui.sh
# Safe to re-run. All destructive steps are guarded.
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}  (skipped)${NC} $1"; }

# ── 1. REMOVE BLOAT PACKAGES ─────────────────────────────────────────────────
step "Removing unused desktop apps..."
REMOVE=(
    # office suite — use Google Docs / web
    libreoffice-base-core libreoffice-calc libreoffice-common libreoffice-core
    libreoffice-draw libreoffice-gnome libreoffice-gtk3 libreoffice-impress
    libreoffice-kf5 libreoffice-math libreoffice-plasma libreoffice-qt5
    libreoffice-writer libreoffice-style-breeze libreoffice-style-colibre
    libreoffice-style-elementary libreoffice-style-yaru
    # media apps not needed
    rhythmbox rhythmbox-data rhythmbox-plugin-alternative-toolbar rhythmbox-plugins
    totem totem-common totem-plugins
    # photo manager
    shotwell shotwell-common
    # scanner
    simple-scan
    # backup (use Drive/gcloud)
    deja-dup
    # video player (use VLC if needed)
    # keeping evince (PDF viewer — useful)
    # keeping eog (image viewer — lightweight)
    # calendar (web)
    gnome-calendar
    # transmission
    transmission-gtk transmission-common
    # gamemode (not a gaming rig)
    gamemode gamemode-daemon libgamemode0 libgamemodeauto0
)
# optional — may not be installed on all systems
REMOVE_OPTIONAL=(
    gnome-mahjongg gnome-mines gnome-sudoku aisleriot gnome-2048
    thunderbird
)
apt-get remove -y --purge "${REMOVE[@]}" 2>/dev/null || true
apt-get remove -y --purge "${REMOVE_OPTIONAL[@]}" 2>/dev/null || true
apt-get autoremove -y --purge
apt-get autoclean -y

# ── 2. REMOVE UNNECESSARY SNAPS ──────────────────────────────────────────────
step "Removing unused snaps..."
SNAPS_REMOVE=(
    firmware-updater       # GUI firmware updater — fwupd CLI is fine
    freeshow               # presentation tool
    thunderbird            # use browser-based mail
)
for s in "${SNAPS_REMOVE[@]}"; do
    if snap list "$s" &>/dev/null; then
        snap remove --purge "$s"
    else
        warn "snap $s not installed"
    fi
done

# clean snap cache (old revisions)
snap set system refresh.retain=2
du -sh /var/lib/snapd/snaps/

# ── 3. DISABLE UNNECESSARY SERVICES ──────────────────────────────────────────
step "Disabling unnecessary system services..."
SERVICES_DISABLE=(
    avahi-daemon          # mDNS — not needed on a dev machine without printers
    cups-browsed          # network printer discovery
    kerneloops            # kernel crash reporter
    ModemManager          # mobile broadband — not used
    whoopsie              # Ubuntu crash reporter
    apport                # crash handler (disable service, keep CLI)
    geoclue               # location service
    bluetooth             # disable if not using BT devices — comment out if needed
)
for svc in "${SERVICES_DISABLE[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        systemctl stop "$svc"
        systemctl disable "$svc"
        echo "  disabled: $svc"
    else
        warn "$svc already inactive"
    fi
done

# keep but don't auto-start: cups (manual start if you print)
systemctl disable cups.service 2>/dev/null || true
systemctl stop cups.service 2>/dev/null || true

# ── 4. DISABLE TRACKER (file indexer — not needed for dev) ───────────────────
step "Disabling GNOME Tracker file indexer..."
systemctl --user mask tracker-miner-fs-3.service 2>/dev/null || true
systemctl --user stop tracker-miner-fs-3.service 2>/dev/null || true
tracker3 reset --filesystem 2>/dev/null || true

# ── 5. DISABLE NOISY AUTOSTART ITEMS ─────────────────────────────────────────
step "Disabling unnecessary autostart entries..."
AUTOSTART_DISABLE=(
    org.gnome.DejaDup.Monitor.desktop
    org.kde.discover.notifier.desktop
    org.kde.kdeconnect.daemon.desktop
    pam_kwallet_init.desktop
    polkit-kde-authentication-agent-1.desktop
    powerdevil.desktop
    print-applet.desktop
    baloo_file.desktop
    geoclue-demo-agent.desktop
    spice-vdagent.desktop
    ubuntu-report-on-upgrade.desktop
    ubuntu-advantage-notification.desktop
    snap-userd-autostart.desktop
    xdg-user-dirs-kde.desktop
)
mkdir -p /etc/xdg/autostart-disabled
for f in "${AUTOSTART_DISABLE[@]}"; do
    src="/etc/xdg/autostart/$f"
    if [ -f "$src" ]; then
        mv "$src" /etc/xdg/autostart-disabled/
        echo "  moved: $f"
    else
        warn "$f not found"
    fi
done

# ── 6. GNOME MINIMAL MODE TWEAKS (run as user, not root) ─────────────────────
step "Applying GNOME minimal settings (as $SUDO_USER)..."
run_user() {
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$SUDO_USER")/bus" gsettings "$@"
}

# animations off — biggest perceived speed win
run_user set org.gnome.desktop.interface enable-animations false

# minimal font rendering
run_user set org.gnome.desktop.interface font-antialiasing 'rgba'
run_user set org.gnome.desktop.interface font-hinting 'slight'

# disable search providers that hit disk
run_user set org.gnome.desktop.search-providers disabled \
    "['org.gnome.Contacts.desktop','org.gnome.Calendar.desktop','org.gnome.clocks.desktop','org.gnome.Weather.desktop','org.gnome.Maps.desktop','org.gnome.Photos.desktop']"

# disable hot corners
run_user set org.gnome.desktop.interface enable-hot-corners false

# blank screen faster, no suspend on AC
run_user set org.gnome.desktop.session idle-delay 300
run_user set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
run_user set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

# nautilus — list view by default
run_user set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

# disable GNOME software auto-update check
run_user set org.gnome.software allow-updates false
run_user set org.gnome.software download-updates false 2>/dev/null || true

# ── 7. DISABLE GNOME SHELL EXTENSIONS (KDE leftovers) ────────────────────────
step "Removing KDE/unnecessary GNOME extensions..."
run_user set org.gnome.shell disabled-extensions \
    "['ding@rastersoft.com']" 2>/dev/null || true
# keep: ubuntu-appindicators, ubuntu-dock, tiling-assistant

# ── 8. INSTALL LIGHTWEIGHT REPLACEMENTS ──────────────────────────────────────
step "Installing lightweight tools..."
apt-get install -y \
    htop \
    ncdu \
    tldr \
    ripgrep \
    fd-find \
    bat \
    iotop \
    nethogs \
    2>/dev/null || true

# ── 9. FINAL REPORT ──────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo " Done. Summary:"
echo "════════════════════════════════════════"
echo ""
echo "RAM before/after (reboot to see full effect):"
free -h
echo ""
echo "Disk freed:"
df -h /
echo ""
echo "Active services (reduced list):"
systemctl list-units --type=service --state=running --no-legend | awk '{print "  "$1}' | grep -v "\.mount\|\.scope" | wc -l
echo " services running"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (or reboot) to apply GNOME settings"
echo "  2. Bluetooth: if you use BT devices, re-enable:"
echo "     sudo systemctl enable --now bluetooth"
echo "  3. Printing: if you need to print:"
echo "     sudo systemctl start cups"
echo ""
