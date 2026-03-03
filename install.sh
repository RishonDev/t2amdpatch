#!/usr/bin/env bash
dir=$(pwd)
GRUB_FILE="$dir/grub"

show_help() {
  cat <<EOF
Usage: $0 [OPTION]

Options:
  --revert    Insert 'nomodeset' into GRUB_CMDLINE_LINUX if not present
  --help      Display this help message

After modification, regenerate grub config with:
  sudo grub-mkconfig -o /boot/grub/grub.cfg
EOF
}
install_drm() {
  chmod +x "$dir/install_drm.sh"
  pkexec "$dir/install_drm.sh"

}
insert_nomodeset() {

  # Create variable if missing
  if ! grep -q '^GRUB_CMDLINE_LINUX=' "$GRUB_FILE"; then
    echo 'GRUB_CMDLINE_LINUX=""' | sudo tee -a "$GRUB_FILE" >/dev/null
  fi

  # Check if already present
  if grep -q '^GRUB_CMDLINE_LINUX=.*nomodeset' "$GRUB_FILE"; then
    echo "Direct display driver loading is already off"

  else
    # Insert nomodeset inside quotes
    sudo sed -i \
      's/^GRUB_CMDLINE_LINUX="\([^"]*\)"/GRUB_CMDLINE_LINUX="\1 nomodeset"/' \
      "$GRUB_FILE"

    echo "nomodeset added."
  fi
}

case "$1" in
--revert)
  if read -rp "Disable direct amdgpu loading? (Removes most issues on most Macs) [Y/n] " ans && [[ ${ans:-Y} =~ ^[Yy] ]]; then
    insert_nomodeset
  fi
  if ! [ -f grub.bak ]; then
    if read -rp "Backup file not found. You like to install the default? [Y/m]" ans && [[ ${ans:-Y} =~ ^[Yy]] ]]; then
      sudo cp "$GRUB_FILE.default" /etc/default/grub
    else
      echo "Kept current grub config."
    fi
  fi
  ;;
--help | "")
  show_help
  ;;
*)
  echo "Unknown option: $1"
  echo "Try --help"
  exit 1
  ;;
esac
#Prevents Brcmfmac from preventing compatibility mode with amdgpu
echo "blacklist brcmfmac" | sudo tee /etc/modprobe.d/brcmfmac.conf
#Backs up existing grub directory
sudo cp /etc/default/grub "$dir/grub.bak"
sudo chown "$(whoami)" "$dir/grub.bak"
#Setting up grub config
sudo cp -f "$dir/grub" /etc/default/grub
sudo install -m 0755 load-wifi.sh /usr/local/sbin/loading_wifi
sudo chown root:root /usr/local/sbin/load_wifi
sudo cp "$dir/49-enable-brcmfmac.rules" /etc/polkit-1/rules.d/49-enable-brcmfmac.rules
sudo chown root:root /etc/polkit-1/rules.d/49-enable-brcmfmac.rules
sudo chmod 0644 /etc/polkit-1/rules.d/49-enable-brcmfmac.rules
#Updates grub config
sudo grub-mkconfig -o /boot/grub/grub.cfg
echo "Setup done!"
