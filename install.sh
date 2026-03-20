#!/usr/bin/env bash
set -e

dir=$(cd -- "$(dirname -- "$0")" && pwd)
GRUB_FILE="$dir/grub"
GRUB_BACKUP_FILE="$dir/grub.bak"
SKIP_FIRMWARE=0
STEP_CURRENT=0
STEP_TOTAL=4

detect_package_manager() {
  if command -v pacman >/dev/null 2>&1; then
    echo pacman
  elif command -v apt >/dev/null 2>&1; then
    echo apt
  elif command -v dnf >/dev/null 2>&1; then
    echo dnf
  else
    echo "Unsupported T2 Linux distribution" >&2
    exit 1
  fi
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "This script must be run as root."
    echo "Use: sudo ./install.sh"
    exit 1
  fi
}

print_warning() {
  echo "WARNING: NOT INSTALLING THE DRM DRIVERS WILL PREVENT THE SYSTEM FROM WORKING. Please be mindful of what you are doing,use if already installed or its causing issues"
}

confirm() {
  local prompt=$1
  local reply

  read -rp "$prompt" reply
  [[ ${reply:-Y} =~ ^[Yy]$ ]]
}

step() {
  STEP_CURRENT=$((STEP_CURRENT + 1))
  echo
  echo "[$STEP_CURRENT/$STEP_TOTAL] $1"
}

run_with_spinner() {
  local label=$1
  local logfile
  shift

  if [[ -t 1 ]]; then
    local pid
    local spin='|/-\'
    local i=0

    logfile=$(mktemp)
    "$@" >"$logfile" 2>&1 &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
      printf '\r%s %s' "${spin:i++%${#spin}:1}" "$label"
      sleep 0.1
    done

    local status
    if wait "$pid"; then
      status=0
    else
      status=$?
    fi
    if ((status == 0)); then
      printf '\r%s\r' "$(printf '%*s' $(( ${#label} + 2 )) '')"
    else
      echo
      cat "$logfile"
      rm -f "$logfile"
      return "$status"
    fi
    rm -f "$logfile"
  else
    "$@"
  fi
}

show_help() {
  cat <<EOF
Usage: $0 [OPTION]

Options:
  --revert    Insert 'nomodeset' into GRUB_CMDLINE_LINUX if not present
  --skip-firmware    Skip installing DRM firmware and drivers
  --help      Display this help message

The installer regenerates GRUB configuration automatically.
The firmware step is skipped automatically if the AMD stack is already installed.

$(print_warning)
EOF
}

drivers_installed() {
  local pm=$1
  local pkg

  case "$pm" in
  pacman)
    for pkg in linux-firmware-amdgpu mesa libdrm mesa-vulkan-radeon xf86-video-amdgpu; do
      pacman -Q "$pkg" >/dev/null 2>&1 || return 1
    done
    ;;
  apt)
    for pkg in linux-firmware libdrm-amdgpu1 libgl1-mesa-dri libegl1-mesa mesa-vulkan-drivers xserver-xorg-video-amdgpu; do
      dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" || return 1
    done
    ;;
  dnf)
    for pkg in linux-firmware libdrm mesa-dri-drivers mesa-libGL mesa-libEGL mesa-vulkan-drivers xorg-x11-drv-amdgpu; do
      rpm -q "$pkg" >/dev/null 2>&1 || return 1
    done
    ;;
  esac
}

install_drm() {
  local pm
  pm=$(detect_package_manager)

  case "$pm" in
  pacman)
    run_with_spinner "Installing AMD graphics stack" \
      pacman -Sy --needed --noconfirm \
      linux-firmware \
      linux-firmware-amdgpu \
      linux-firmware-atheros \
      linux-firmware-broadcom \
      linux-firmware-cirrus \
      linux-firmware-intel \
      linux-firmware-mediatek \
      linux-firmware-nvidia \
      linux-firmware-other \
      linux-firmware-radeon \
      linux-firmware-realtek \
      linux-firmware-whence \
      mesa \
      libdrm \
      vulkan-loader \
      mesa-vulkan-radeon \
      xf86-video-amdgpu
    ;;
  apt)
    run_with_spinner "Updating apt package lists" apt update
    run_with_spinner "Installing AMD graphics stack" \
      apt install -y \
      linux-firmware \
      libdrm-amdgpu1 \
      libgl1-mesa-dri \
      libegl1-mesa \
      mesa-vulkan-drivers \
      xserver-xorg-video-amdgpu
    ;;
  dnf)
    run_with_spinner "Installing AMD graphics stack" \
      dnf install -y \
      linux-firmware \
      libdrm \
      mesa-dri-drivers \
      mesa-libGL \
      mesa-libEGL \
      mesa-vulkan-drivers \
      xorg-x11-drv-amdgpu
    ;;
  esac

  echo "Loading amdgpu kernel module"
  modprobe amdgpu || echo "Loading amdgpu driver failed"
  echo "For best results, reboot."
}
insert_nomodeset() {
  # Create variable if missing
  if ! grep -q '^GRUB_CMDLINE_LINUX=' "$GRUB_FILE"; then
    echo 'GRUB_CMDLINE_LINUX=""' >>"$GRUB_FILE"
  fi

  # Check if already present
  if grep -q '^GRUB_CMDLINE_LINUX=.*nomodeset' "$GRUB_FILE"; then
    echo "Direct display driver loading is already off"

  else
    # Insert nomodeset inside quotes
    sed -i \
      's/^GRUB_CMDLINE_LINUX="\([^"]*\)"/GRUB_CMDLINE_LINUX="\1 nomodeset"/' \
      "$GRUB_FILE"

    echo "nomodeset added."
  fi
}

perform_revert() {
  if confirm "Disable direct amdgpu loading? (Removes most issues on most Macs) [Y/n] "; then
    insert_nomodeset
  fi

  if [[ ! -f "$GRUB_BACKUP_FILE" ]]; then
    if confirm "Backup file not found. You like to install the default? [Y/n] "; then
      cp "$dir/grub.default" /etc/default/grub
    else
      echo "Kept current grub config."
    fi
  fi
}

install_loader_policy() {
  install -m 0755 "$dir/load_wifi" /usr/local/sbin/load_wifi
  chown root:root /usr/local/sbin/load_wifi
  install -d /etc/xdg/autostart
  install -m 0644 "$dir/brcmfmac.desktop" /etc/xdg/autostart/brcmfmac.desktop
  chown root:root /etc/xdg/autostart/brcmfmac.desktop
  cp "$dir/49-enable-brcmfmac.rules" /etc/polkit-1/rules.d/49-enable-brcmfmac.rules
  chown root:root /etc/polkit-1/rules.d/49-enable-brcmfmac.rules
  chmod 0644 /etc/polkit-1/rules.d/49-enable-brcmfmac.rules
}

revert_requested=0

while (($# > 0)); do
  case "$1" in
  --revert)
    revert_requested=1
    ;;
  --skip-firmware)
    SKIP_FIRMWARE=1
    print_warning
    ;;
  --help)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    echo "Try --help"
    exit 1
    ;;
  esac
  shift
done

require_root

if ((SKIP_FIRMWARE)); then
  STEP_TOTAL=3
else
  PACKAGE_MANAGER=$(detect_package_manager)
  if drivers_installed "$PACKAGE_MANAGER"; then
    SKIP_FIRMWARE=1
    STEP_TOTAL=3
    echo "AMD graphics stack already installed. Skipping firmware and DRM userspace installation."
  fi
fi

if ((SKIP_FIRMWARE)); then
  STEP_TOTAL=3
fi

if ((revert_requested)); then
  perform_revert
  exit 0
fi

if (( ! SKIP_FIRMWARE )); then
  step "Installing firmware and DRM userspace"
  install_drm
fi

step "Configuring kernel module handling"
#Prevents Brcmfmac from preventing compatibility mode with amdgpu
echo "blacklist brcmfmac" >/etc/modprobe.d/brcmfmac.conf
#Backs up existing grub directory
cp /etc/default/grub "$GRUB_BACKUP_FILE"
#Setting up grub config
cp -f "$dir/grub" /etc/default/grub

step "Installing Wi-Fi loader and policy"
install_loader_policy

step "Regenerating GRUB configuration"
#Updates grub config
run_with_spinner "Generating grub.cfg" grub-mkconfig -o /boot/grub/grub.cfg
echo
echo "Setup done!"
