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
elif command -v zypper >/dev/null 2>&1; then
  PM=zypper
else
  echo "Unsupported distro"
  exit 1
fi

# -------------------------
# Install AMD graphics stack
# -------------------------
case "$PM" in
pacman)
  pacman -Sy --needed --noconfirm \
    linux-firmware \
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
zypper)
  zypper install -y \
    kernel-firmware-amdgpu \
    Mesa \
    Mesa-dri \
    Mesa-libGL1 \
    Mesa-libEGL1 \
    Mesa-vulkan-drivers \
    xf86-video-amdgpu
  ;;
esac
