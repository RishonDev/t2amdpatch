#!/bin/sh
set -e

# -------------------------
# Package manager detection
# -------------------------
if command -v pacman >/dev/null 2>&1; then
  PM=pacman
elif command -v apt >/dev/null 2>&1; then
  PM=apt
elif command -v dnf >/dev/null 2>&1; then
  PM=dnf
else
  echo "Unsupported T2 Linux distribution"
  exit 1
fi

# -------------------------
# Install AMD graphics stack
# -------------------------
case "$PM" in
pacman)
  pacman -Sy --needed --noconfirm \
    linux-firmware \
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
  apt update
  apt install -y \
    linux-firmware \
    libdrm-amdgpu1 \
    libgl1-mesa-dri \
    libegl1-mesa \
    mesa-vulkan-drivers \
    xserver-xorg-video-amdgpu
  ;;
dnf)
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
pexec modprobe amdgpu || echo "Loading amdgpu driver failed"
echo "For best results, reboot."
