# t2amdpatch

GRUB Bootloader patches for AMD GPU driver on T2 Linux. Tested on iMac 2020 with Radeon Pro 5300

**WARNING: READ BEFORE INSTALL!**
## Steps to install:

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

## Boot sequence
1. When it boots, hold the option key (⌥). Wait for a few seconds for the firmware to load (Around 2 seconds). Then select the Linux EFI  partition

2.  **DO NOT PRESS ENTER, AS THE DRIVER WILL FAIL TO LOAD.**. Let GRUB boot on its own. Wait for the 5 second timer 
3. And you should be in. 

## Contribution

Please test and document befoe posting any tweaks.  Put it as a pull request.

## Known quirks
a. Cold boot. First boots are most likely to fail.

**Known workaround: using rEFInd(nomodeset is safer, but without nomodeset can be used), or using an alternate OS supported by T2**

b. AMD GPU may crash if setup is done improperly. 

**Known workaround: Press the power button once and do the setup again**  