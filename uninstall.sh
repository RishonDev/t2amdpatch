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

if [[ ! -f "$SCRIPT_DIR/grub.bak" ]]; then
  fail "Backup grub config not found at $SCRIPT_DIR/grub.bak"
fi

if ! command -v grub-mkconfig >/dev/null 2>&1; then
  fail "grub-mkconfig command not found"
fi

if [[ -f /etc/default/grub ]]; then
  if cp /etc/default/grub "$SCRIPT_DIR/grub.uninstall.bak"; then
    info "Backed up current /etc/default/grub to $SCRIPT_DIR/grub.uninstall.bak"
  else
    fail "Failed to back up current /etc/default/grub"
  fi
fi

if cp "$SCRIPT_DIR/grub.bak" /etc/default/grub; then
  info "Restored $SCRIPT_DIR/grub.bak to /etc/default/grub"
else
  fail "Failed to restore grub config"
fi

if systemctl disable amdgpu-bind.service >/dev/null 2>&1; then
  info "Disabled amdgpu-bind.service"
else
  info "amdgpu-bind.service was not enabled"
fi

if systemctl disable amdgpu-bind-resume.service >/dev/null 2>&1; then
  info "Disabled amdgpu-bind-resume.service"
else
  info "amdgpu-bind-resume.service was not enabled"
fi

if rm -f /etc/systemd/system/amdgpu-bind.service; then
  info "Removed /etc/systemd/system/amdgpu-bind.service"
else
  fail "Failed to remove amdgpu-bind.service"
fi

if rm -f /etc/systemd/system/amdgpu-bind-resume.service; then
  info "Removed /etc/systemd/system/amdgpu-bind-resume.service"
else
  fail "Failed to remove amdgpu-bind-resume.service"
fi

if rm -f /usr/local/bin/amdgpu-bind.sh; then
  info "Removed /usr/local/bin/amdgpu-bind.sh"
else
  fail "Failed to remove amdgpu-bind.sh"
fi

if systemctl daemon-reload >/dev/null 2>&1; then
  info "Reloaded systemd daemon"
else
  fail "Failed to reload systemd daemon"
fi

if grub-mkconfig -o /boot/grub/grub.cfg >/dev/null; then
  info "Regenerated /boot/grub/grub.cfg"
else
  fail "Failed to regenerate /boot/grub/grub.cfg"
fi

info "Done."
