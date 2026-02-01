# t2amdpatch

GRUB Bootloader patches for AMD GPU driver on T2 Linux. Tested on iMac 2020 with Radeon Pro 5300

**WARNING: READ BEFORE INSTALL!**
# Steps to install:

1. Download the repository to your Downloads folder
2. In Terminal, type (or copy and paste):

```bash
cd Downloads
unzip t2amdpatch-main.zip
cd t2amdpatch-main
chmod +x install.sh
./install.sh
```

And you're good to go. If you're not willing to deal with the quirks of the driver, don't apply the patch

# Boot sequence
When it boots, hold the option key (⌥). Wait for a few seconds for the firmware to load (Around 2 seconds). Then select the Linux EFI partition