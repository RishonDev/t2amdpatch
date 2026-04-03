#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

info() {
  printf '\033[0;32m%s\033[0m\n' "$1"
}

fail() {
  printf '\033[0;31m%s\033[0m\n' "$1" >&2
  exit 1
}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  fail "This script must be run as root."
fi

if [[ ! -f "$SCRIPT_DIR/grub" ]]; then
  fail "Source grub config not found at $SCRIPT_DIR/grub"
fi

if [[ ! -f "$SCRIPT_DIR/amdgpu-bind.sh" ]]; then
  fail "Source script not found at $SCRIPT_DIR/amdgpu-bind.sh"
fi

if [[ ! -f "$SCRIPT_DIR/amdgpu-bind.service" ]]; then
  fail "Source service not found at $SCRIPT_DIR/amdgpu-bind.service"
fi

if [[ ! -f /etc/default/grub ]]; then
  fail "System grub config not found at /etc/default/grub"
fi

if ! command -v grub-mkconfig >/dev/null 2>&1; then
  fail "grub-mkconfig command not found"
fi

if cp /etc/default/grub "$SCRIPT_DIR/grub.bak"; then
  info "Backed up /etc/default/grub to $SCRIPT_DIR/grub.bak"
else
  fail "Failed to back up /etc/default/grub"
fi

if cp "$SCRIPT_DIR/grub" /etc/default/grub; then
  info "Installed $SCRIPT_DIR/grub to /etc/default/grub"
else
  fail "Failed to install grub config"
fi

if install -m 755 "$SCRIPT_DIR/amdgpu-bind.sh" /usr/local/bin/amdgpu-bind.sh; then
  info "Installed $SCRIPT_DIR/amdgpu-bind.sh to /usr/local/bin/amdgpu-bind.sh"
else
  fail "Failed to install amdgpu-bind.sh"
fi

if install -m 644 "$SCRIPT_DIR/amdgpu-bind.service" /etc/systemd/system/amdgpu-bind.service; then
  info "Installed $SCRIPT_DIR/amdgpu-bind.service to /etc/systemd/system/amdgpu-bind.service"
else
  fail "Failed to install amdgpu-bind.service"
fi

if systemctl daemon-reload >/dev/null 2>&1; then
  info "Reloaded systemd daemon"
else
  fail "Failed to reload systemd daemon"
fi

if systemctl enable amdgpu-bind.service >/dev/null 2>&1; then
  info "Enabled amdgpu-bind.service"
else
  fail "Failed to enable amdgpu-bind.service"
fi

if grub-mkconfig -o /boot/grub/grub.cfg >/dev/null; then
  info "Regenerated /boot/grub/grub.cfg"
else
  fail "Failed to regenerate /boot/grub/grub.cfg"
fi

info "Done."
