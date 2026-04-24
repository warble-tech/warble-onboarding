#!/usr/bin/env bash
# Run as: sudo bash apply.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Copying TLP AC profile..."
cp "$SCRIPT_DIR/50-warble-ac.conf" /etc/tlp.d/50-warble-ac.conf

echo "==> Copying VM sysctl config..."
cp "$SCRIPT_DIR/99-warble-vm.conf" /etc/sysctl.d/99-warble-vm.conf

echo "==> Applying sysctl settings now..."
sysctl -p /etc/sysctl.d/99-warble-vm.conf

echo "==> Reloading TLP with new profile..."
tlp start

echo "==> Disabling turbo boost immediately (intel_pstate)..."
TURBO=/sys/devices/system/cpu/intel_pstate/no_turbo
if [ -f "$TURBO" ]; then
    echo 1 > "$TURBO"
else
    echo "    (turbo sysfs node not found — skipping)"
fi

echo "==> Setting powersave governor on all cores..."
for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
    echo powersave > "$cpu"
done

echo "==> Capping CPU performance to 85% via intel_pstate..."
MAXPERF=/sys/devices/system/cpu/intel_pstate/max_perf_pct
if [ -f "$MAXPERF" ]; then
    echo 85 > "$MAXPERF"
    echo "    max_perf_pct set to 85%"
else
    echo "    (intel_pstate max_perf_pct not found — skipping)"
fi

echo ""
echo "Done. Current temps:"
sensors | grep -E "Package|Core 0"
echo ""
echo "Current governor:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo ""
echo "Turbo disabled:"
cat /sys/devices/system/cpu/intel_pstate/no_turbo
