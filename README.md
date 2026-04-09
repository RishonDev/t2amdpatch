# t2amdpatch

GRUB and driver setup for T2 Linux systems using AMD GPUs.

Tested on an iMac 2020 with a Radeon Pro 5300M. Current version: 0.4.

Credits: @curtis7551 (Discord)

## Install

Run the installer as root:

```bash
chmod +x install.sh
sudo ./install.sh
```

The installer:

- installs the binder service
- updates `/etc/default/grub`
- regenerates `grub.cfg` automatically

For redistribution, the patched `apple-bce` should come from the shipped kernel or package set, not from a local source checkout. This installer only installs the suspend/resume workaround and GRUB settings.

## Options

```bash
sudo ./install.sh --help
```

Available options:

- `--nomodeset on|off` enables or disables `nomodeset` in GRUB
- `--revert` remains available as a compatibility alias for `--nomodeset on`
- `--skip-firmware` skips the firmware and DRM driver installation step

WARNING: NOT INSTALLING THE DRM DRIVERS WILL PREVENT THE SYSTEM FROM WORKING. Please be mindful of what you are doing,use if already installed or its causing issues

## Notes

- `nomodeset` is off by default.
- Normal boot behavior is expected on the newest versions; the old manual boot timing workaround is obsolete.
- Suspend reliability still depends on a kernel or module package that contains the required `apple-bce` fixes.
- Incorrect setup can still cause AMD GPU crashes. If that happens, power the machine off and try again. Do not force shutdown, rather press the power button once.
- RAM faster than 2666 MHz may prevent the drivers from loading reliably on affected hardware.

## Contributing

Open an issue for problems not covered here, or send a pull request with tested changes.
